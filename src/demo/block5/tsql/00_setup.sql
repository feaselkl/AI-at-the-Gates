/* =============================================================================
   00_setup.sql  -- Block 5.3 RAG demo, ENTIRELY-IN-T-SQL variant: setup.

   Creates the DbaDocs database and registers the Microsoft Foundry (Azure OpenAI)
   embedding model. Foundry endpoints use publicly-trusted certs, so SQL Server
   trusts them with NO cert setup (unlike the local-Ollama path in Block 4).

   Fill in the placeholders before running:
     <resource>          your Azure OpenAI / Foundry resource name
     <embed-deployment>  your text-embedding-3-small deployment name
     <chat-deployment>   your chat model deployment (used in 02_rag.sql)
     <api-key>           the resource API key
     <master-key-pwd>    any strong password for the database master key
   ============================================================================= */

IF DB_ID(N'DbaDocs') IS NULL CREATE DATABASE DbaDocs;
GO
ALTER DATABASE DbaDocs SET COMPATIBILITY_LEVEL = 170;   -- required for AI_GENERATE_CHUNKS
GO
USE DbaDocs;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;   -- AI_GENERATE_* are preview
GO
EXEC sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO

-- Master key + ONE credential for the Foundry resource (covers embeddings + chat).
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'<master-key-pwd>';
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_scoped_credentials
               WHERE name = N'https://<resource>.openai.azure.com/')
    CREATE DATABASE SCOPED CREDENTIAL [https://<resource>.openai.azure.com/]
        WITH IDENTITY = 'HTTPEndpointHeaders', SECRET = '{"api-key":"<api-key>"}';
GO

-- Foundry embedding model (text-embedding-3-small = 1536 dims).
IF EXISTS (SELECT 1 FROM sys.external_models WHERE name = N'FoundryEmbeddings')
    DROP EXTERNAL MODEL FoundryEmbeddings;
GO
CREATE EXTERNAL MODEL FoundryEmbeddings
WITH (
    LOCATION   = 'https://<resource>.openai.azure.com/openai/deployments/<embed-deployment>/embeddings?api-version=2024-02-01',
    API_FORMAT = 'Azure OpenAI',
    MODEL_TYPE = EMBEDDINGS,
    MODEL      = 'text-embedding-3-small',
    CREDENTIAL = [https://<resource>.openai.azure.com/]
);
GO

-- Doc + chunk tables. Embedding is a GA VECTOR column (no index here -- the corpus
-- is tiny, so exact kNN with VECTOR_DISTANCE is the right tool; see Block 4).
DROP TABLE IF EXISTS dbo.KbChunk;
DROP TABLE IF EXISTS dbo.KbDoc;
GO
CREATE TABLE dbo.KbDoc (
    DocId   INT IDENTITY PRIMARY KEY,
    DocName NVARCHAR(200)  NOT NULL,
    Content NVARCHAR(MAX)  NOT NULL
);
CREATE TABLE dbo.KbChunk (
    ChunkId    INT IDENTITY PRIMARY KEY,
    DocName    NVARCHAR(200) NOT NULL,
    ChunkOrder BIGINT        NOT NULL,
    ChunkText  NVARCHAR(MAX) NOT NULL,
    Embedding  VECTOR(1536)  NULL          -- match your embedding model's dimension
);
GO

-- Smoke test: should return a 1536-element array.
SELECT AI_GENERATE_EMBEDDINGS(N'test chunk' USE MODEL FoundryEmbeddings) AS test_embedding;
GO
