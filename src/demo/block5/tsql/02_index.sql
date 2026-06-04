/*
   01_index.sql

   Run AFTER 00_setup.sql and AFTER loading the docs (run load_docs.sql, which
   inserts the runbook text into dbo.KbDoc.

   This is the "index" half of RAG, entirely in T-SQL:
     AI_GENERATE_CHUNKS  -> split each doc into overlapping chunks
     AI_GENERATE_EMBEDDINGS (Foundry) -> a vector per chunk
*/

USE DbaDocs;
GO

TRUNCATE TABLE dbo.KbChunk;
GO

INSERT INTO dbo.KbChunk (DocName, ChunkOrder, ChunkText, Embedding)
SELECT
    d.DocName,
    c.chunk_order,
    c.chunk,
    AI_GENERATE_EMBEDDINGS(c.chunk USE MODEL FoundryEmbeddings)
FROM dbo.KbDoc AS d
CROSS APPLY AI_GENERATE_CHUNKS (
    SOURCE     = d.Content,
    CHUNK_TYPE = FIXED,
    CHUNK_SIZE = 800,     -- ~150-200 tokens per chunk
    OVERLAP    = 15       -- 15% overlap so context isn't cut mid-thought
) AS c;
GO

SELECT COUNT(*) AS chunks,
       COUNT(Embedding) AS embedded,
       COUNT(DISTINCT DocName) AS docs
FROM dbo.KbChunk;
GO
