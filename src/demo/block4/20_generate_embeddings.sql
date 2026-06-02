/* =============================================================================
   20_generate_embeddings.sql   (LIVE DEMO -- not run at build)

   Populates the VECTOR columns by calling the model registered in
   10_create_external_model.sql. Embeds a *subset* by default so the demo runs
   quickly and doesn't rack up a large embedding bill -- remove the TOP (...)
   filters to embed everything (slow + costs money for ~388k rows).

   Embed BEFORE creating the vector index: on SQL Server 2025 a vector-indexed
   table can become read-only, so generate vectors first, index last.
   ============================================================================= */

USE WakeCountyFood;
GO

DECLARE @sampleSize INT = 2000;   -- bump up (or remove the TOP filters) for a fuller demo

/* --- FoodInspection.Description -------------------------------------------- */
UPDATE TOP (@sampleSize) fi
SET DescriptionEmbedding = AI_GENERATE_EMBEDDINGS(fi.[Description] USE MODEL HarrierEmbeddings)
FROM dbo.FoodInspection AS fi
WHERE fi.[Description] IS NOT NULL
  AND fi.DescriptionEmbedding IS NULL;
GO

/* --- FoodInspectionViolation.ShortDesc ------------------------------------- */
UPDATE TOP (2000) v
SET ShortDescEmbedding = AI_GENERATE_EMBEDDINGS(v.ShortDesc USE MODEL HarrierEmbeddings)
FROM dbo.FoodInspectionViolation AS v
WHERE v.ShortDesc IS NOT NULL
  AND v.ShortDescEmbedding IS NULL;
GO

/* --- FoodInspectionViolation.Comments -------------------------------------- */
UPDATE TOP (2000) v
SET CommentsEmbedding = AI_GENERATE_EMBEDDINGS(v.Comments USE MODEL HarrierEmbeddings)
FROM dbo.FoodInspectionViolation AS v
WHERE v.Comments IS NOT NULL
  AND v.CommentsEmbedding IS NULL;
GO

-- How many rows are embedded so far? (Need >= 100 before building an index.)
SELECT
    (SELECT COUNT(*) FROM dbo.FoodInspection          WHERE DescriptionEmbedding IS NOT NULL) AS inspection_desc_embedded,
    (SELECT COUNT(*) FROM dbo.FoodInspectionViolation WHERE ShortDescEmbedding   IS NOT NULL) AS violation_shortdesc_embedded,
    (SELECT COUNT(*) FROM dbo.FoodInspectionViolation WHERE CommentsEmbedding    IS NOT NULL) AS violation_comments_embedded;
GO
