/* =============================================================================
   04_eval.sql  -- Block 5.3 RAG demo (T-SQL): is retrieval finding the right doc?

   A RAG answer can only be as good as the chunks it retrieves. So before judging
   the chat model's answers, test retrieval against a fixed set of questions
   whose correct source document you already know. Rerun it after any change to
   chunk size, overlap, the embedding model, top-k, or the documents, and
   compare the numbers with the last run.

   For each test question it reports:
     expected_doc_rank  -- rank of the first chunk from the right doc (1 = top hit)
     in_top_k           -- 1 if that chunk is among the @k chunks that 03_rag.sql
                           sends to the chat model, else 0
     best_doc / best_distance -- what actually came back first, and how close
   The last question isn't covered by any doc, so it has no expected doc. Watch
   its best_distance: a weak best match is the cue to answer "I don't know".

   Run after 02_index.sql. Calls the embedding model once per question and never
   calls the chat model, so it's cheap to rerun.
   ============================================================================= */

USE DbaDocs;
GO

DECLARE @k INT = 4;   -- keep in step with TOP (4) in 03_rag.sql

DROP TABLE IF EXISTS #test_questions;
CREATE TABLE #test_questions (
    QuestionId        INT IDENTITY PRIMARY KEY,
    Question          NVARCHAR(1000) NOT NULL,
    ExpectedDoc       NVARCHAR(200)  NULL,    -- NULL = no doc should answer this
    QuestionEmbedding VECTOR(1536)   NULL     -- match dbo.KbChunk.Embedding
);

-- Worded the way a user would ask, not the way the runbook is written.
INSERT INTO #test_questions (Question, ExpectedDoc) VALUES
    (N'The nightly data load broke overnight and the log filled up. What happened?',
        N'failed-nightly-etl-postmortem.md'),
    (N'Users say the app is frozen and saving hangs.',
        N'blocking-and-deadlocks-runbook.md'),
    (N'How far back can we recover, and what breaks point-in-time restore?',
        N'backup-restore-runbook.md'),
    (N'How do I fail over to the DR site, and what is the catch?',
        N'availability-group-failover-runbook.md'),
    (N'We see lots of PAGELATCH waits on allocation pages. What should we change?',
        N'tempdb-contention-runbook.md'),
    (N'Queries got slow after a big data change and the plans look wrong. Should we rebuild every index?',
        N'index-maintenance-runbook.md'),
    (N'What is our Kafka topic retention period?',
        NULL);

UPDATE #test_questions
SET QuestionEmbedding = AI_GENERATE_EMBEDDINGS(Question USE MODEL FoundryEmbeddings);

-- Rank every chunk for every question (exact kNN; the corpus is tiny).
DROP TABLE IF EXISTS #ranked;
SELECT q.QuestionId,
       c.DocName,
       VECTOR_DISTANCE('cosine', q.QuestionEmbedding, c.Embedding) AS distance,
       ROW_NUMBER() OVER (PARTITION BY q.QuestionId
                          ORDER BY VECTOR_DISTANCE('cosine', q.QuestionEmbedding, c.Embedding)) AS chunk_rank
INTO #ranked
FROM #test_questions AS q
CROSS JOIN dbo.KbChunk AS c
WHERE c.Embedding IS NOT NULL;

-- One row per question.
SELECT q.QuestionId,
       LEFT(q.Question, 70)                         AS question,
       q.ExpectedDoc                                AS expected_doc,
       hit.expected_doc_rank,
       CASE WHEN q.ExpectedDoc IS NULL THEN NULL
            WHEN hit.expected_doc_rank <= @k THEN 1
            ELSE 0 END                              AS in_top_k,
       top1.DocName                                 AS best_doc,
       CAST(top1.distance AS DECIMAL(5,3))          AS best_distance
FROM #test_questions AS q
OUTER APPLY (
    SELECT MIN(r.chunk_rank) AS expected_doc_rank
    FROM #ranked AS r
    WHERE r.QuestionId = q.QuestionId
      AND r.DocName = q.ExpectedDoc
) AS hit
OUTER APPLY (
    SELECT r.DocName, r.distance
    FROM #ranked AS r
    WHERE r.QuestionId = q.QuestionId
      AND r.chunk_rank = 1
) AS top1
ORDER BY q.QuestionId;

-- The score to track from run to run (in-scope questions only).
SELECT COUNT(*)                                          AS questions_with_an_answer,
       SUM(CASE WHEN r.first_rank <= @k THEN 1 ELSE 0 END) AS found_in_top_k,
       SUM(CASE WHEN r.first_rank = 1  THEN 1 ELSE 0 END) AS found_at_rank_1
FROM (
    SELECT q.QuestionId, MIN(r.chunk_rank) AS first_rank
    FROM #test_questions AS q
    LEFT JOIN #ranked AS r
           ON r.QuestionId = q.QuestionId
          AND r.DocName = q.ExpectedDoc
    WHERE q.ExpectedDoc IS NOT NULL
    GROUP BY q.QuestionId
) AS r;
GO
