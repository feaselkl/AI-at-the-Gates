/* =============================================================================
   02_rag.sql  -- Block 5.3 RAG demo (T-SQL): the full RAG query, entirely in T-SQL.

   Embed the question -> retrieve the closest chunks (exact kNN) -> build a chat
   payload with that context -> call the Foundry chat model -> return the grounded,
   cited answer. Change @question and re-run.

   Fill in <resource> and <chat-deployment> to match your Foundry deployment.
   ============================================================================= */

USE DbaDocs;
GO

DECLARE @question NVARCHAR(1000) =
    N'The nightly data load failed overnight and the transaction log filled up. What happened, and how do we stop it recurring?';

-- -- Secondary question for testing.
-- DECLARE @question NVARCHAR(1000) =
--     N'Rick in Accounts Payable says that the Music City Miracle was an illegal forward pass and I''m still bitter about it. Give me proof that I am correct in my belief.';

/* 1. Embed the question with the same model used for the chunks. */
DECLARE @qv VECTOR(1536) = AI_GENERATE_EMBEDDINGS(@question USE MODEL FoundryEmbeddings);

/* 2. Retrieve the top-k chunks by exact cosine kNN (small corpus -> no ANN index). */
DECLARE @context NVARCHAR(MAX);
SELECT @context = STRING_AGG(CONCAT('[', DocName, ']', CHAR(13)+CHAR(10), ChunkText),
                             CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10))
                  WITHIN GROUP (ORDER BY distance)
FROM (
    SELECT TOP (4)
        DocName, ChunkText,
        VECTOR_DISTANCE('cosine', @qv, Embedding) AS distance
    FROM dbo.KbChunk
    WHERE Embedding IS NOT NULL
    ORDER BY distance
) AS top_chunks;

/* 3. Build the chat payload: a grounding system prompt + the question with context. */
DECLARE @system NVARCHAR(MAX) =
    N'You are a DBA assistant. Answer ONLY from the provided context. Cite the source '
  + N'document name in square brackets after each claim. If the answer is not in the '
  + N'context, say you do not know.';
DECLARE @user NVARCHAR(MAX) =
    CONCAT(N'Context:', CHAR(13)+CHAR(10), @context, CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10),
           N'Question: ', @question);

DECLARE @payload NVARCHAR(MAX) =
    JSON_OBJECT(
        'messages': JSON_ARRAY(
            JSON_OBJECT('role': 'system', 'content': @system),
            JSON_OBJECT('role': 'user',   'content': @user)
        )
    );

/* 4. Call the Foundry chat-completions endpoint (HTTPS, publicly-trusted cert). */
DECLARE @ret INT, @response NVARCHAR(MAX);
EXEC @ret = sp_invoke_external_rest_endpoint
    @url        = N'https://csvcaifoundry.services.ai.azure.com/openai/deployments/gpt-5-mini/chat/completions?api-version=2024-10-21',
    @method     = 'POST',
    @credential = [https://csvcaifoundry.services.ai.azure.com],
    @payload    = @payload,
    @response   = @response OUTPUT;

/* 5. The grounded answer is in the chat response; sp_invoke nests it under $.result. */
SELECT
    JSON_VALUE(@response, '$.result.choices[0].message.content') AS answer,
    @context AS retrieved_context;
GO