/* =============================================================================
   20_generate_embeddings.sql   (LIVE DEMO -- not run at build)

   Populates the VECTOR columns by calling the model registered in
   10_create_external_model.sql. FoodInspection.Description embeds a subset
   (@sampleSize rows). The two FoodInspectionViolation loops embed EVERY
   remaining non-NULL row, 2,000 at a time (~311k rows per column): hours on a
   laptop GPU, and real money against a paid endpoint. Run them ahead of time,
   not live.

   The violation loops walk the clustered key (OBJECTID) in batches and always
   move past each batch, so a row the model returns NULL for can't stall the
   loop. An endpoint error stops the loop instead of skipping rows. Re-running
   the script picks up whatever is still NULL; the query at the bottom reports
   rows that have text but no embedding.

   Blank text is skipped. An empty string gets no embedding back from the
   endpoint, and AI_GENERATE_EMBEDDINGS fails the statement with Msg 31744 ("The
   JSON path for embeddings could not be found in the response"), which takes the
   whole batch with it. Whitespace-only text does get a vector, but a vector of
   nothing is noise in a similarity search, so it's skipped too. (Tested
   2026-11-01 against Harrier: N'' fails; N' ', N'  ', and a tab return vectors.)
   This data set has no empty strings and one whitespace-only comment
   (FoodInspectionViolation.OBJECTID 97455, two spaces); the report below counts it.

   Embed BEFORE creating the vector index: on SQL Server 2025 a vector-indexed
   table is read-only, so generate vectors first, index last. If
   30_create_vector_index.sql has already run, these UPDATEs fail until you
   drop the vector index on that table.
   ============================================================================= */

USE WakeCountyFood;
GO

DECLARE @sampleSize INT = 2000;   -- bump up (or remove the TOP filters) for a fuller demo

/* NOTE: this took approximately 3 hours to run for all 70k FoodInspection rows,
    using a laptop with a Radeon 780M GPU. */

/* --- FoodInspection.Description -------------------------------------------- */
UPDATE TOP (@sampleSize) fi
SET DescriptionEmbedding = AI_GENERATE_EMBEDDINGS(fi.[Description] USE MODEL HarrierEmbeddings)
FROM dbo.FoodInspection AS fi
WHERE fi.[Description] IS NOT NULL
  AND TRIM(CHAR(9)+CHAR(10)+CHAR(13)+CHAR(32) FROM fi.[Description]) <> N''
  AND fi.DescriptionEmbedding IS NULL;
GO

/* NOTE: this took approximately 1 hour and 40 minutes to run,
    using a laptop with a Radeon 780M GPU. */

/* --- FoodInspectionViolation.ShortDesc ------------------------------------- */
SET NOCOUNT ON;
DECLARE @batchSize INT = 2000,
        @lastId    INT = 0,
        @upperId   INT;

WHILE 1 = 1
BEGIN
    -- The next @batchSize rows that still need an embedding, in key order.
    SELECT @upperId = MAX(k.OBJECTID)
    FROM (
        SELECT TOP (@batchSize) v.OBJECTID
        FROM dbo.FoodInspectionViolation AS v
        WHERE v.OBJECTID > @lastId
          AND v.ShortDesc IS NOT NULL
          AND TRIM(CHAR(9)+CHAR(10)+CHAR(13)+CHAR(32) FROM v.ShortDesc) <> N''
          AND v.ShortDescEmbedding IS NULL
        ORDER BY v.OBJECTID
    ) AS k;

    IF @upperId IS NULL BREAK;   -- nothing left to embed

    BEGIN TRY
        UPDATE v
        SET ShortDescEmbedding = AI_GENERATE_EMBEDDINGS(v.ShortDesc USE MODEL HarrierEmbeddings)
        FROM dbo.FoodInspectionViolation AS v
        WHERE v.OBJECTID > @lastId
          AND v.OBJECTID <= @upperId
          AND v.ShortDesc IS NOT NULL
          AND TRIM(CHAR(9)+CHAR(10)+CHAR(13)+CHAR(32) FROM v.ShortDesc) <> N''
          AND v.ShortDescEmbedding IS NULL;
    END TRY
    BEGIN CATCH
        -- Stop rather than skip: an endpoint error would otherwise advance past rows.
        RAISERROR('ShortDesc: batch after OBJECTID %d failed; stopping.', 0, 1, @lastId) WITH NOWAIT;
        THROW;
    END CATCH;

    -- Move past this batch even if the model returned NULL for some rows.
    SET @lastId = @upperId;
    RAISERROR('ShortDesc: processed through OBJECTID %d', 0, 1, @lastId) WITH NOWAIT;
END
GO

/* --- FoodInspectionViolation.Comments -------------------------------------- */
SET NOCOUNT ON;
DECLARE @batchSize INT = 2000,
        @lastId    INT = 0,
        @upperId   INT;

WHILE 1 = 1
BEGIN
    -- The next @batchSize rows that still need an embedding, in key order.
    SELECT @upperId = MAX(k.OBJECTID)
    FROM (
        SELECT TOP (@batchSize) v.OBJECTID
        FROM dbo.FoodInspectionViolation AS v
        WHERE v.OBJECTID > @lastId
          AND v.Comments IS NOT NULL
          AND TRIM(CHAR(9)+CHAR(10)+CHAR(13)+CHAR(32) FROM v.Comments) <> N''
          AND v.CommentsEmbedding IS NULL
        ORDER BY v.OBJECTID
    ) AS k;

    IF @upperId IS NULL BREAK;   -- nothing left to embed

    BEGIN TRY
        UPDATE v
        SET CommentsEmbedding = AI_GENERATE_EMBEDDINGS(v.Comments USE MODEL HarrierEmbeddings)
        FROM dbo.FoodInspectionViolation AS v
        WHERE v.OBJECTID > @lastId
          AND v.OBJECTID <= @upperId
          AND v.Comments IS NOT NULL
          AND TRIM(CHAR(9)+CHAR(10)+CHAR(13)+CHAR(32) FROM v.Comments) <> N''
          AND v.CommentsEmbedding IS NULL;
    END TRY
    BEGIN CATCH
        -- Stop rather than skip: an endpoint error would otherwise advance past rows.
        RAISERROR('Comments: batch after OBJECTID %d failed; stopping.', 0, 1, @lastId) WITH NOWAIT;
        THROW;
    END CATCH;

    -- Move past this batch even if the model returned NULL for some rows.
    SET @lastId = @upperId;
    RAISERROR('Comments: processed through OBJECTID %d', 0, 1, @lastId) WITH NOWAIT;
END
GO

-- Rows with text but no embedding: the model returned NULL, or the loop hasn't reached them yet.
-- Whitespace-only rows are counted separately; they are skipped on purpose.
DECLARE @ws NVARCHAR(4) = CHAR(9)+CHAR(10)+CHAR(13)+CHAR(32);
SELECT
    (SELECT COUNT(*) FROM dbo.FoodInspectionViolation WHERE ShortDesc IS NOT NULL AND TRIM(@ws FROM ShortDesc) <> N'' AND ShortDescEmbedding IS NULL) AS violation_shortdesc_missing,
    (SELECT COUNT(*) FROM dbo.FoodInspectionViolation WHERE Comments  IS NOT NULL AND TRIM(@ws FROM Comments)  <> N'' AND CommentsEmbedding  IS NULL) AS violation_comments_missing,
    (SELECT COUNT(*) FROM dbo.FoodInspectionViolation WHERE Comments  IS NOT NULL AND TRIM(@ws FROM Comments)  =  N'') AS violation_comments_whitespace_only;
GO

-- How many rows are embedded so far? (Need >= 100 before building an index.)
SELECT
    (SELECT COUNT(*) FROM dbo.FoodInspection          WHERE DescriptionEmbedding IS NOT NULL) AS inspection_desc_embedded,
    (SELECT COUNT(*) FROM dbo.FoodInspectionViolation WHERE ShortDescEmbedding   IS NOT NULL) AS violation_shortdesc_embedded,
    (SELECT COUNT(*) FROM dbo.FoodInspectionViolation WHERE CommentsEmbedding    IS NOT NULL) AS violation_comments_embedded;
GO

-- How much space is being used by the embeddings and the rest of our data?
-- Total space used by the table (data + indexes, including vector indexes once we build them).
EXEC dbo.sp_spaceused 'dbo.FoodInspection';

-- Just the embedding vectors (the VECTOR columns are VARBINARY under the hood, so
-- DATALENGTH gives us the size in bytes).
SELECT
    FORMAT(SUM(DATALENGTH(DescriptionEmbedding)), 'N0') AS inspection_desc_embedding_bytes
FROM dbo.FoodInspection WITH(NOLOCK);
GO


-- Total space used by the table (data + indexes, including vector indexes once we build them).
EXEC dbo.sp_spaceused 'dbo.FoodInspectionViolation';

-- Just the embedding vectors (the VECTOR columns are VARBINARY under the hood, so
-- DATALENGTH gives us the size in bytes).
SELECT
    FORMAT(SUM(DATALENGTH(ShortDescEmbedding)), 'N0') AS violation_shortdesc_embedding_bytes,
    FORMAT(SUM(DATALENGTH(CommentsEmbedding)), 'N0') AS violation_comments_embedding_bytes
FROM dbo.FoodInspectionViolation WITH(NOLOCK);
GO
