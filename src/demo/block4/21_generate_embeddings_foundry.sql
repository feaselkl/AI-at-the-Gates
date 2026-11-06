/* =============================================================================
   21_generate_embeddings_foundry.sql   (LIVE DEMO -- not run at build)

   Foundry counterpart to 20_generate_embeddings.sql: fills the same VECTOR(1024)
   columns using the FoundryEmbeddings model from
   11_create_external_model_foundry.sql. Run 11_ first.

   BATCHED, NOT ROW-BY-ROW. AI_GENERATE_EMBEDDINGS makes one REST call per row.
   Against Foundry that measured ~333 ms/row (2026-11-06): ~64 hours for the
   ~691k rows here. The embeddings API takes an array of inputs, so this script
   sends @batchSize texts per call with sp_invoke_external_rest_endpoint and
   writes the vectors back by array position (~20 ms/row at 500 per call, 16x
   faster). The endpoint, credential, and dimensions are read from the
   FoundryEmbeddings definition, so the vectors match what
   AI_GENERATE_EMBEDDINGS(... USE MODEL FoundryEmbeddings) returns in 40_/50_.
   Cost is small: ~31M tokens for everything, well under $1 for
   text-embedding-3-small at the time of writing.

   SAFETY: nothing records which model produced a vector, so this script tags
   each column (extended property EmbeddingModel = 'FoundryEmbeddings') and
   refuses to touch a column holding vectors without that tag -- i.e. Harrier
   vectors from 20_. Clear them with 19_clear_embeddings.sql first. Re-running
   this script resumes: it only fills rows that are still NULL.

   Same rules as 20_: blank/whitespace-only text is skipped, and embed BEFORE
   creating the vector index (a vector-indexed table is read-only).

   After this, 30_ builds the indexes as usual; in 40_ and 50_ swap
   USE MODEL HarrierEmbeddings for USE MODEL FoundryEmbeddings.
   ============================================================================= */

USE WakeCountyFood;
GO

/* =============================================================================
   GUARD -- stop the whole script (SET NOEXEC ON) if anything is unsafe
   ============================================================================= */
SET NOCOUNT ON;
DECLARE @problem NVARCHAR(2048) = NULL;

DECLARE @cols TABLE (
    TableName  SYSNAME,
    ColumnName SYSNAME,
    Embedded   INT,
    Tag        NVARCHAR(128) NULL
);
INSERT @cols (TableName, ColumnName, Embedded) VALUES
    (N'FoodInspection',          N'DescriptionEmbedding', (SELECT COUNT(*) FROM dbo.FoodInspection          WHERE DescriptionEmbedding IS NOT NULL)),
    (N'FoodInspectionViolation', N'ShortDescEmbedding',   (SELECT COUNT(*) FROM dbo.FoodInspectionViolation WHERE ShortDescEmbedding   IS NOT NULL)),
    (N'FoodInspectionViolation', N'CommentsEmbedding',    (SELECT COUNT(*) FROM dbo.FoodInspectionViolation WHERE CommentsEmbedding    IS NOT NULL));

UPDATE c
SET Tag = CAST(ep.value AS NVARCHAR(128))
FROM @cols AS c
JOIN sys.extended_properties AS ep
  ON ep.class = 1
 AND ep.major_id = OBJECT_ID(N'dbo.' + c.TableName)
 AND ep.minor_id = COLUMNPROPERTY(OBJECT_ID(N'dbo.' + c.TableName), c.ColumnName, 'ColumnId')
 AND ep.name = N'EmbeddingModel';

SELECT TableName, ColumnName, Embedded, ISNULL(Tag, N'(untagged)') AS EmbeddingModel FROM @cols;

IF NOT EXISTS (SELECT 1 FROM sys.external_models
               WHERE name = N'FoundryEmbeddings'
                 AND JSON_VALUE(parameters, '$.dimensions') = N'1024')
    SET @problem = N'FoundryEmbeddings is missing or not set to 1024 dimensions. Run 11_create_external_model_foundry.sql first.';
ELSE IF EXISTS (SELECT 1 FROM sys.indexes
                WHERE object_id IN (OBJECT_ID(N'dbo.FoodInspection'), OBJECT_ID(N'dbo.FoodInspectionViolation'))
                  AND type_desc LIKE N'%VECTOR%')
    SET @problem = N'A vector index exists on these tables, which makes them read-only. Drop it first (19_clear_embeddings.sql drops them).';
ELSE IF EXISTS (SELECT 1 FROM @cols WHERE Embedded > 0 AND ISNULL(Tag, N'') <> N'FoundryEmbeddings')
    SET @problem = N'A column already holds vectors from another model (see the list above). Run 19_clear_embeddings.sql first -- never mix models in one column.';

IF @problem IS NOT NULL
BEGIN
    RAISERROR(N'STOPPING: %s', 16, 1, @problem);
    SET NOEXEC ON;            -- skip every remaining batch in this script
END
ELSE
BEGIN
    -- Tag the columns so a later run (or 19_) knows which model filled them.
    DECLARE @t SYSNAME, @c SYSNAME, @hasTag BIT;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR
        SELECT TableName, ColumnName, CASE WHEN Tag IS NULL THEN 0 ELSE 1 END FROM @cols;
    OPEN c;
    FETCH NEXT FROM c INTO @t, @c, @hasTag;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @hasTag = 1
            EXEC sys.sp_updateextendedproperty @name = N'EmbeddingModel', @value = N'FoundryEmbeddings',
                 @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = @t,
                 @level2type = N'COLUMN', @level2name = @c;
        ELSE
            EXEC sys.sp_addextendedproperty @name = N'EmbeddingModel', @value = N'FoundryEmbeddings',
                 @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = @t,
                 @level2type = N'COLUMN', @level2name = @c;
        FETCH NEXT FROM c INTO @t, @c, @hasTag;
    END
    CLOSE c; DEALLOCATE c;
END
GO

/* =============================================================================
   #EmbedColumn -- batched embedding of one text column into one VECTOR column.
   A temporary procedure: it lives only for this session, nothing is left behind.
   ============================================================================= */
DROP PROCEDURE IF EXISTS #EmbedColumn;
GO
CREATE PROCEDURE #EmbedColumn
    @table     SYSNAME,
    @textCol   SYSNAME,
    @vecCol    SYSNAME,
    @batchSize INT = 500,         -- texts per API call (API max 2048; keep each call well under @timeout)
    @maxRows   INT = NULL         -- stop after this many rows (NULL = all remaining)
AS
BEGIN
    SET NOCOUNT ON;

    -- Endpoint, credential, and request parameters come from the registered model.
    DECLARE @url NVARCHAR(4000), @cred SYSNAME, @params NVARCHAR(MAX);
    SELECT @url = m.location, @cred = dsc.name, @params = CONVERT(NVARCHAR(MAX), m.parameters)  -- json type
    FROM sys.external_models AS m
    JOIN sys.database_scoped_credentials AS dsc ON dsc.credential_id = m.credential_id
    WHERE m.name = N'FoundryEmbeddings';
    DECLARE @dims NVARCHAR(10) = JSON_VALUE(@params, '$.dimensions');

    DECLARE @ws NVARCHAR(4) = CHAR(9)+CHAR(10)+CHAR(13)+CHAR(32),
            @lastId INT = 0, @done INT = 0, @take INT, @n INT, @updated INT,
            @payload NVARCHAR(MAX), @response NVARCHAR(MAX), @ret INT,
            @attempt INT, @wait INT, @err NVARCHAR(2048), @delay CHAR(8);

    CREATE TABLE #batch (rn INT PRIMARY KEY, OBJECTID INT NOT NULL, txt NVARCHAR(MAX) NOT NULL);

    -- The next rows that still need an embedding, in key order (same filter as 20_).
    DECLARE @select NVARCHAR(MAX) = N'
        INSERT #batch (rn, OBJECTID, txt)
        SELECT ROW_NUMBER() OVER (ORDER BY k.OBJECTID) - 1, k.OBJECTID, k.txt
        FROM (
            SELECT TOP (@take) t.OBJECTID, t.' + QUOTENAME(@textCol) + N' AS txt
            FROM dbo.' + QUOTENAME(@table) + N' AS t
            WHERE t.OBJECTID > @lastId
              AND t.' + QUOTENAME(@textCol) + N' IS NOT NULL
              AND TRIM(@ws FROM t.' + QUOTENAME(@textCol) + N') <> N''''
              AND t.' + QUOTENAME(@vecCol) + N' IS NULL
            ORDER BY t.OBJECTID
        ) AS k;';

    -- Write vectors back: response item [index] = n matches the n-th input text.
    DECLARE @update NVARCHAR(MAX) = N'
        UPDATE t
        SET ' + QUOTENAME(@vecCol) + N' = CAST(j.embedding AS VECTOR(' + @dims + N'))
        FROM dbo.' + QUOTENAME(@table) + N' AS t
        JOIN #batch AS b ON b.OBJECTID = t.OBJECTID
        JOIN OPENJSON(@response, ''$.result.data'')
             WITH ([index] INT ''$.index'', embedding NVARCHAR(MAX) ''$.embedding'' AS JSON) AS j
          ON j.[index] = b.rn;
        SET @updated = @@ROWCOUNT;';

    WHILE @maxRows IS NULL OR @done < @maxRows
    BEGIN
        TRUNCATE TABLE #batch;
        SET @take = CASE WHEN @maxRows IS NULL OR @maxRows - @done > @batchSize
                         THEN @batchSize ELSE @maxRows - @done END;
        EXEC sys.sp_executesql @select, N'@take INT, @lastId INT, @ws NVARCHAR(4)', @take, @lastId, @ws;
        SET @n = @@ROWCOUNT;
        IF @n = 0 BREAK;           -- nothing left to embed

        SET @payload = (SELECT N'{"dimensions":' + @dims + N',"input":' + JSON_ARRAYAGG(txt ORDER BY rn) + N'}'
                        FROM #batch);

        -- Call the API. Retry 429s, 5xx, timeouts, and network blips with backoff;
        -- stop on anything else (bad key, bad deployment, oversized request).
        SET @attempt = 0;
        WHILE 1 = 1
        BEGIN
            SELECT @attempt += 1, @response = NULL, @ret = NULL, @err = NULL;
            BEGIN TRY
                EXEC @ret = sys.sp_invoke_external_rest_endpoint
                    @url = @url, @method = 'POST', @credential = @cred,
                    @payload = @payload, @timeout = 230, @response = @response OUTPUT;
            END TRY
            BEGIN CATCH
                SET @err = ERROR_MESSAGE();     -- network/DNS failure or timeout: no HTTP status
            END CATCH;

            IF @ret = 0 BREAK;                  -- HTTP 2xx

            IF @err IS NULL
                SET @err = CONCAT(N'HTTP ', @ret, N': ',
                                  ISNULL(JSON_VALUE(@response, '$.result.error.message'), N'(no message)'));

            IF @attempt >= 6 OR (@ret BETWEEN 400 AND 499 AND @ret NOT IN (408, 429))
            BEGIN
                RAISERROR(N'%s.%s: batch after OBJECTID %d failed (attempt %d): %s -- stopping. Re-run to resume.',
                          16, 1, @table, @textCol, @lastId, @attempt, @err);
                RETURN;
            END

            SET @wait = POWER(2, @attempt) * 5;  -- 10, 20, 40, 80, 160 s
            SET @delay = CONVERT(CHAR(8), DATEADD(SECOND, @wait, 0), 108);
            RAISERROR(N'%s.%s: %s -- retrying in %d s', 0, 1, @table, @textCol, @err, @wait) WITH NOWAIT;
            WAITFOR DELAY @delay;
        END

        EXEC sys.sp_executesql @update, N'@response NVARCHAR(MAX), @updated INT OUTPUT',
             @response, @updated OUTPUT;
        IF @updated <> @n
        BEGIN
            RAISERROR(N'%s.%s: sent %d texts but wrote %d vectors after OBJECTID %d -- stopping.',
                      16, 1, @table, @textCol, @n, @updated, @lastId);
            RETURN;
        END

        SELECT @lastId = MAX(OBJECTID) FROM #batch;
        SET @done += @n;
        RAISERROR(N'%s.%s: %d rows embedded, through OBJECTID %d', 0, 1, @table, @textCol, @done, @lastId) WITH NOWAIT;
    END
END
GO

/* =============================================================================
   RUN IT
   ============================================================================= */

/* --- FoodInspection.Description: a sample, as in 20_ ------------------------ */
DECLARE @sampleSize INT = 2000;   -- NULL embeds all ~70k rows (~25 min)
EXEC #EmbedColumn N'FoodInspection', N'Description', N'DescriptionEmbedding', @maxRows = @sampleSize;
GO

/* --- FoodInspectionViolation.ShortDesc: every row (~311k, ~1.5-2 h) ---------- */
EXEC #EmbedColumn N'FoodInspectionViolation', N'ShortDesc', N'ShortDescEmbedding';
GO

/* --- FoodInspectionViolation.Comments: every row (~310k, ~1.5-2 h) ----------- */
EXEC #EmbedColumn N'FoodInspectionViolation', N'Comments', N'CommentsEmbedding';
GO

/* =============================================================================
   REPORTS (same as 20_)
   ============================================================================= */

-- Rows with text but no embedding: the loop stopped early or hasn't reached them yet.
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

-- Sanity check: a batched vector should match what AI_GENERATE_EMBEDDINGS returns
-- for the same text (cosine distance ~0; tiny float noise is normal).
SELECT TOP (1)
    v.OBJECTID,
    VECTOR_DISTANCE('cosine', v.ShortDescEmbedding,
        CAST(AI_GENERATE_EMBEDDINGS(v.ShortDesc USE MODEL FoundryEmbeddings) AS VECTOR(1024)))   -- returns json
        AS distance_batched_vs_function
FROM dbo.FoodInspectionViolation AS v
WHERE v.ShortDescEmbedding IS NOT NULL
ORDER BY v.OBJECTID;
GO

SET NOEXEC OFF;   -- restore normal execution for the rest of this session
GO
