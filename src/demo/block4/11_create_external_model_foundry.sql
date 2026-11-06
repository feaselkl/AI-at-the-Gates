/* =============================================================================
   11_create_external_model_foundry.sql   (LIVE DEMO -- not run at build)

   ALTERNATIVE to 10_create_external_model.sql: registers a Microsoft Foundry
   (Azure OpenAI) embedding model instead of local Ollama/Harrier. Use it when
   there's no local GPU, or as the stage fallback if Ollama misbehaves.

   Foundry endpoints use publicly-trusted certs, so there is NO TLS proxy and NO
   cert-trust step (unlike the Ollama path in 10_). The cost: every embedding is
   a paid API call, and the data leaves the machine.

   Fill in the placeholders before running (same values as block5/tsql/00_setup.sql):
     <resource>          your Azure OpenAI / Foundry resource name
     <embed-deployment>  your text-embedding-3-small deployment name
     <api-key>           the resource API key
     <master-key-pwd>    any strong password for the database master key

   -------------------------------------------------------------------------
   IMPORTANT -- read before switching models:

   1) DIMENSIONS. text-embedding-3-small returns 1536 dims by default, but the
      Block 4 columns are VECTOR(1024) (sized for Harrier). The text-embedding-3
      models can shorten their output, so PARAMETERS asks for 1024 dims and the
      existing columns, indexes, and VECTOR(1024) variables all work unchanged.

   2) DON'T MIX MODELS. Same dimension count is NOT the same vector space. A
      Foundry query vector compared against Harrier-generated column vectors
      gives meaningless distances. If you switch to Foundry, re-run
      20_generate_embeddings.sql with this model for EVERY embedding column
      (drop the vector index first; see 20_ and 30_), and use the same model
      in 40_ and 50_.

   3) MODEL NAME. This registers FoundryEmbeddings. Scripts 20/40/50 say
      USE MODEL HarrierEmbeddings -- swap the name there when using this path.
   ------------------------------------------------------------------------- */

USE WakeCountyFood;
GO

/* =============================================================================
   PART 1 -- SETUP: make sure SQL Server can reach Foundry
   ============================================================================= */

-- Allow SQL Server to call external REST endpoints (sp_invoke_external_rest_endpoint
-- and AI_GENERATE_EMBEDDINGS both need this).
EXEC sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO

-- A database master key protects the credential's secret. One per database.
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'<master-key-pwd>';
GO

-- One credential for the Foundry resource. Its name must be the URL prefix
-- (scheme + host) of the endpoint it's used for. Drop/recreate so a corrected
-- key takes effect on re-run.
IF EXISTS (SELECT 1 FROM sys.external_models WHERE name = N'FoundryEmbeddings')
    DROP EXTERNAL MODEL FoundryEmbeddings;      -- depends on the credential
IF EXISTS (SELECT 1 FROM sys.database_scoped_credentials
           WHERE name = N'https://<resource>.services.ai.azure.com')
    DROP DATABASE SCOPED CREDENTIAL [https://<resource>.services.ai.azure.com];
GO
CREATE DATABASE SCOPED CREDENTIAL [https://<resource>.services.ai.azure.com]
    WITH IDENTITY = 'HTTPEndpointHeaders', SECRET = '{"api-key":"<api-key>"}';
GO

-- Connection check: call the embeddings endpoint directly. Unlike
-- AI_GENERATE_EMBEDDINGS (which only reports a generic Msg 31608), this shows
-- the real HTTP status and error body.
--   200        -> connection, key, and deployment are all good.
--   401        -> bad <api-key>.
--   404        -> wrong <resource> or <embed-deployment> name.
--   Msg 31608 / no HTTP status -> SQL Server can't reach the host at all
--                 (network/DNS, or the outbound REST endpoint is disabled).
DECLARE @ret INT, @response NVARCHAR(MAX);
EXEC @ret = sp_invoke_external_rest_endpoint
    @url        = N'https://<resource>.services.ai.azure.com/openai/deployments/<embed-deployment>/embeddings?api-version=2024-02-01',
    @method     = 'POST',
    @credential = [https://<resource>.services.ai.azure.com],
    @payload    = N'{"input":"connection test","dimensions":1024}',
    @response   = @response OUTPUT;

SELECT
    @ret                                                         AS return_code,   -- 0 = success
    JSON_VALUE(@response, '$.response.status.http.code')         AS http_status,
    JSON_VALUE(@response, '$.result.model')                      AS model,
    (SELECT COUNT(*) FROM OPENJSON(@response, '$.result.data[0].embedding'))
                                                                 AS dimensions,    -- expect 1024
    JSON_VALUE(@response, '$.result.error.message')              AS error_message;
GO

/* =============================================================================
   PART 2 -- register the model
   ============================================================================= */

-- Register text-embedding-3-small as an EMBEDDINGS model, shortened to 1024 dims
-- to match the VECTOR(1024) columns. retry_count rides out transient 429s
-- (rate limiting) during the bulk embedding in 20_.
IF EXISTS (SELECT 1 FROM sys.external_models WHERE name = N'FoundryEmbeddings')
    DROP EXTERNAL MODEL FoundryEmbeddings;
GO

CREATE EXTERNAL MODEL FoundryEmbeddings
WITH (
    LOCATION   = 'https://<resource>.services.ai.azure.com/openai/deployments/<embed-deployment>/embeddings?api-version=2024-02-01',
    API_FORMAT = 'Azure OpenAI',
    MODEL_TYPE = EMBEDDINGS,
    MODEL      = 'text-embedding-3-small',
    CREDENTIAL = [https://<resource>.services.ai.azure.com],
    PARAMETERS = '{"dimensions":1024,"sql_rest_options":{"retry_count":3}}'
);
GO

-- Smoke test: should report 1024 dimensions, then show the vector itself.
DECLARE @v VECTOR(1024) =
    AI_GENERATE_EMBEDDINGS(N'cold holding temperature violation' USE MODEL FoundryEmbeddings);
SELECT VECTORPROPERTY(@v, 'Dimensions') AS dimensions, @v AS embedding;
GO
