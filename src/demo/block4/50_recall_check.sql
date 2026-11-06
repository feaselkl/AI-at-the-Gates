/* =============================================================================
   50_recall_check.sql   (LIVE DEMO -- not run at build)

   "Is the index giving me the right answers?" A vector index is approximate,
   so measure it before you trust it. For a sample of query vectors, compare
   the index's top 10 (VECTOR_SEARCH) with the exact top 10 (VECTOR_DISTANCE).
   Recall@10 is the share of the exact top 10 that the index also found:
   1.00 means the index returned the same answers a full scan would.

     A. Recall over a sample of rows. No embedding endpoint needed: the query
        vectors are embeddings already stored in the table.
     B. One typed question, both lists side by side (needs the endpoint).

   Run after 30_create_vector_index.sql. Rerun whenever the row count, the
   embedding model, or the index changes: recall measured on 2,000 rows says
   little about recall on 2 million.

   Ties: violation comments repeat word for word ("Observed ..."), and repeated
   text gets an identical vector. When several rows tie at the 10th-place
   distance, the exact and index lists can pick different rows from that tie,
   and comparing row IDs alone would call that a miss. So A reports two numbers:
     id_recall    -- rows in both lists (INTERSECT), the naive measure
     tie_recall   -- index rows at least as close as the exact 10th-place row,
                     which is the measure benchmark suites use
   ============================================================================= */

USE WakeCountyFood;
GO

/* ---------------------------------------------------------------------------
   A. Recall@10 over a sample of rows.
   --------------------------------------------------------------------------- */
SET NOCOUNT ON;

DECLARE @samples INT = 25;

-- Evenly spaced rows from everything that has an embedding.
DROP TABLE IF EXISTS #queries;
WITH numbered AS (
    SELECT v.OBJECTID,
           ROW_NUMBER() OVER (ORDER BY v.OBJECTID) AS rn,
           COUNT(*) OVER () AS n
    FROM dbo.FoodInspectionViolation AS v
    WHERE v.CommentsEmbedding IS NOT NULL
)
SELECT TOP (@samples) OBJECTID AS QueryId
INTO #queries
FROM numbered
WHERE rn % CASE WHEN n < @samples THEN 1 ELSE n / @samples END = 0
ORDER BY OBJECTID;

DROP TABLE IF EXISTS #results;
CREATE TABLE #results (
    QueryId     INT PRIMARY KEY,
    ExactRows   INT,
    IndexRows   INT,
    IdMatches   INT,
    TieMatches  INT
);

DECLARE @exact  TABLE (Id INT PRIMARY KEY, Distance FLOAT);
DECLARE @approx TABLE (Id INT PRIMARY KEY, Distance FLOAT);
DECLARE @id INT, @qv VECTOR(1024), @kth FLOAT;

DECLARE q CURSOR LOCAL FAST_FORWARD FOR SELECT QueryId FROM #queries ORDER BY QueryId;
OPEN q;
FETCH NEXT FROM q INTO @id;
WHILE @@FETCH_STATUS = 0
BEGIN
    DELETE FROM @exact;
    DELETE FROM @approx;

    SELECT @qv = v.CommentsEmbedding
    FROM dbo.FoodInspectionViolation AS v
    WHERE v.OBJECTID = @id;

    -- Exact: distance to every embedded row. The query row itself is left out.
    INSERT INTO @exact (Id, Distance)
    SELECT TOP (10) v.OBJECTID, VECTOR_DISTANCE('cosine', @qv, v.CommentsEmbedding)
    FROM dbo.FoodInspectionViolation AS v
    WHERE v.CommentsEmbedding IS NOT NULL
      AND v.OBJECTID <> @id
    ORDER BY VECTOR_DISTANCE('cosine', @qv, v.CommentsEmbedding);

    -- Index: ask for 11 so there are still 10 after dropping the query row.
    INSERT INTO @approx (Id, Distance)
    SELECT TOP (10) v.OBJECTID, s.distance
    FROM VECTOR_SEARCH(
            TABLE      = dbo.FoodInspectionViolation AS v,
            COLUMN     = CommentsEmbedding,
            SIMILAR_TO = @qv,
            METRIC     = 'cosine',
            TOP_N      = 11
         ) AS s
    WHERE v.OBJECTID <> @id
    ORDER BY s.distance;

    SELECT @kth = MAX(Distance) FROM @exact;

    INSERT INTO #results (QueryId, ExactRows, IndexRows, IdMatches, TieMatches)
    SELECT @id,
           (SELECT COUNT(*) FROM @exact),
           (SELECT COUNT(*) FROM @approx),
           (SELECT COUNT(*) FROM (SELECT Id FROM @exact INTERSECT SELECT Id FROM @approx) AS both_lists),
           -- 1e-6 absorbs float rounding between the two code paths.
           (SELECT COUNT(*) FROM @approx WHERE Distance <= @kth + 1e-6);

    FETCH NEXT FROM q INTO @id;
END
CLOSE q;
DEALLOCATE q;

SELECT COUNT(*)                                   AS queries,
       CAST(AVG(IdMatches  / 10.0) AS DECIMAL(4,2)) AS id_recall,
       CAST(AVG(TieMatches / 10.0) AS DECIMAL(4,2)) AS tie_recall,
       CAST(MIN(TieMatches / 10.0) AS DECIMAL(4,2)) AS worst_query_tie_recall
FROM #results;

-- The queries where the index came back different. Empty is good news.
SELECT r.QueryId, r.IdMatches, r.TieMatches,
       LEFT(v.Comments, 100) AS query_text
FROM #results AS r
JOIN dbo.FoodInspectionViolation AS v ON v.OBJECTID = r.QueryId
WHERE r.TieMatches < 10 OR r.IdMatches < 10
ORDER BY r.TieMatches, r.IdMatches;
GO

/* ---------------------------------------------------------------------------
   B. One typed question, both lists side by side. in_both = 0 marks a row only
      one method returned.
   --------------------------------------------------------------------------- */
DECLARE @q VECTOR(1024) =
    AI_GENERATE_EMBEDDINGS(N'rodent or pest activity in the kitchen' USE MODEL HarrierEmbeddings);

WITH exact_top AS (
    SELECT TOP (10) v.OBJECTID, VECTOR_DISTANCE('cosine', @q, v.CommentsEmbedding) AS distance
    FROM dbo.FoodInspectionViolation AS v
    WHERE v.CommentsEmbedding IS NOT NULL
    ORDER BY distance
),
index_top AS (
    SELECT v.OBJECTID, s.distance
    FROM VECTOR_SEARCH(
            TABLE      = dbo.FoodInspectionViolation AS v,
            COLUMN     = CommentsEmbedding,
            SIMILAR_TO = @q,
            METRIC     = 'cosine',
            TOP_N      = 10
         ) AS s
)
SELECT COALESCE(e.OBJECTID, i.OBJECTID) AS OBJECTID,
       e.distance AS exact_distance,
       i.distance AS index_distance,
       CASE WHEN e.OBJECTID IS NOT NULL AND i.OBJECTID IS NOT NULL THEN 1 ELSE 0 END AS in_both,
       LEFT(v.Comments, 100) AS comments_snippet
FROM exact_top AS e
FULL OUTER JOIN index_top AS i ON i.OBJECTID = e.OBJECTID
JOIN dbo.FoodInspectionViolation AS v ON v.OBJECTID = COALESCE(e.OBJECTID, i.OBJECTID)
ORDER BY COALESCE(e.distance, i.distance);
GO
