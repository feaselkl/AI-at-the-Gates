/* =============================================================================
   19_clear_embeddings.sql   (PREP -- not run at build, not a live demo step)

   Wipes every embedding in WakeCountyFood so the columns can be re-filled with a
   different model (e.g. switching from Harrier/Ollama in 20_ to Foundry in 21_).
   Vectors from two models must never share a column: equal dimension counts do
   NOT mean comparable vectors, and nothing in the data records which model
   produced a given vector.

   What it does:
     1. Drops the vector indexes on the two tables (a vector-indexed table is
        read-only on SQL Server 2025, so the UPDATEs below would fail).
        Rebuild them afterwards with 30_create_vector_index.sql.
     2. Sets DescriptionEmbedding, ShortDescEmbedding, and CommentsEmbedding to
        NULL, in batches with a CHECKPOINT between them so the log (SIMPLE
        recovery) doesn't balloon.
     3. Removes the EmbeddingModel tag that 21_ puts on each column.

   DESTRUCTIVE: Harrier vectors took hours of GPU time to generate. Set
   @confirm = 1 below to run it; with 0 the script reports what it would clear
   and stops.
   ============================================================================= */

USE WakeCountyFood;
GO

DECLARE @confirm BIT = 0;     -- set to 1 to actually clear the embeddings

SELECT
    (SELECT COUNT(*) FROM dbo.FoodInspection          WHERE DescriptionEmbedding IS NOT NULL) AS inspection_desc_embedded,
    (SELECT COUNT(*) FROM dbo.FoodInspectionViolation WHERE ShortDescEmbedding   IS NOT NULL) AS violation_shortdesc_embedded,
    (SELECT COUNT(*) FROM dbo.FoodInspectionViolation WHERE CommentsEmbedding    IS NOT NULL) AS violation_comments_embedded;

IF @confirm = 0
BEGIN
    RAISERROR('@confirm = 0: nothing cleared. Set @confirm = 1 to clear the counts above.', 16, 1);
    SET NOEXEC ON;            -- skip every remaining batch in this script
END
GO

/* --- 1. Drop vector indexes on the two tables ------------------------------ */
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += N'DROP INDEX ' + QUOTENAME(i.name) + N' ON dbo.' + QUOTENAME(OBJECT_NAME(i.object_id)) + N';' + CHAR(10)
FROM sys.indexes AS i
WHERE i.object_id IN (OBJECT_ID(N'dbo.FoodInspection'), OBJECT_ID(N'dbo.FoodInspectionViolation'))
  AND i.type_desc LIKE N'%VECTOR%';
IF @sql <> N''
BEGIN
    PRINT @sql;
    EXEC sys.sp_executesql @sql;
END
GO

/* --- 2. NULL out the vectors, in batches ----------------------------------- */
SET NOCOUNT ON;
DECLARE @batchSize INT = 20000, @rows INT;

WHILE 1 = 1
BEGIN
    UPDATE TOP (@batchSize) dbo.FoodInspection
    SET DescriptionEmbedding = NULL
    WHERE DescriptionEmbedding IS NOT NULL;
    SET @rows = @@ROWCOUNT;
    IF @rows = 0 BREAK;
    CHECKPOINT;
    RAISERROR('Description: cleared %d rows', 0, 1, @rows) WITH NOWAIT;
END

WHILE 1 = 1
BEGIN
    UPDATE TOP (@batchSize) dbo.FoodInspectionViolation
    SET ShortDescEmbedding = NULL
    WHERE ShortDescEmbedding IS NOT NULL;
    SET @rows = @@ROWCOUNT;
    IF @rows = 0 BREAK;
    CHECKPOINT;
    RAISERROR('ShortDesc: cleared %d rows', 0, 1, @rows) WITH NOWAIT;
END

WHILE 1 = 1
BEGIN
    UPDATE TOP (@batchSize) dbo.FoodInspectionViolation
    SET CommentsEmbedding = NULL
    WHERE CommentsEmbedding IS NOT NULL;
    SET @rows = @@ROWCOUNT;
    IF @rows = 0 BREAK;
    CHECKPOINT;
    RAISERROR('Comments: cleared %d rows', 0, 1, @rows) WITH NOWAIT;
END
GO

/* --- 3. Remove the model tags (set by 21_generate_embeddings_foundry.sql) -- */
DECLARE @t SYSNAME, @c SYSNAME;
DECLARE tags CURSOR LOCAL FAST_FORWARD FOR
    SELECT OBJECT_NAME(ep.major_id), COL_NAME(ep.major_id, ep.minor_id)
    FROM sys.extended_properties AS ep
    WHERE ep.class = 1 AND ep.minor_id > 0 AND ep.name = N'EmbeddingModel'
      AND ep.major_id IN (OBJECT_ID(N'dbo.FoodInspection'), OBJECT_ID(N'dbo.FoodInspectionViolation'));
OPEN tags;
FETCH NEXT FROM tags INTO @t, @c;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC sys.sp_dropextendedproperty @name = N'EmbeddingModel',
         @level0type = N'SCHEMA', @level0name = N'dbo',
         @level1type = N'TABLE',  @level1name = @t,
         @level2type = N'COLUMN', @level2name = @c;
    FETCH NEXT FROM tags INTO @t, @c;
END
CLOSE tags; DEALLOCATE tags;
GO

-- Should be all zeros.
SELECT
    (SELECT COUNT(*) FROM dbo.FoodInspection          WHERE DescriptionEmbedding IS NOT NULL) AS inspection_desc_embedded,
    (SELECT COUNT(*) FROM dbo.FoodInspectionViolation WHERE ShortDescEmbedding   IS NOT NULL) AS violation_shortdesc_embedded,
    (SELECT COUNT(*) FROM dbo.FoodInspectionViolation WHERE CommentsEmbedding    IS NOT NULL) AS violation_comments_embedded;
GO

SET NOEXEC OFF;   -- restore normal execution for the rest of this session
GO
