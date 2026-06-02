/* =============================================================================
   30_create_vector_index.sql   (LIVE DEMO -- not run at build)

   Builds DiskANN approximate (ANN) vector indexes. DiskANN is the only vector
   index type in the SQL Server family. Requires PREVIEW_FEATURES = ON (already
   baked in) and at least ~100 embedded rows in the column.

   Caveat (SQL Server 2025): a table can become read-only once it has a vector
   index. To add more embeddings later, DROP the index, embed, then recreate it.
   ============================================================================= */

USE WakeCountyFood;
GO

-- Inspection narratives.
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'VIX_FoodInspection_Description'
           AND object_id = OBJECT_ID('dbo.FoodInspection'))
    DROP INDEX VIX_FoodInspection_Description ON dbo.FoodInspection;
GO
CREATE VECTOR INDEX VIX_FoodInspection_Description
    ON dbo.FoodInspection (DescriptionEmbedding)
    WITH (METRIC = 'cosine', TYPE = 'diskANN');
GO

-- Violation comments (the richest free text).
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'VIX_FoodInspectionViolation_Comments'
           AND object_id = OBJECT_ID('dbo.FoodInspectionViolation'))
    DROP INDEX VIX_FoodInspectionViolation_Comments ON dbo.FoodInspectionViolation;
GO
CREATE VECTOR INDEX VIX_FoodInspectionViolation_Comments
    ON dbo.FoodInspectionViolation (CommentsEmbedding)
    WITH (METRIC = 'cosine', TYPE = 'diskANN');
GO

-- Inspect what we built.
SELECT i.name AS index_name, OBJECT_NAME(vi.object_id) AS table_name,
       vi.vector_index_type, vi.distance_metric
FROM sys.vector_indexes AS vi
JOIN sys.indexes AS i
  ON vi.object_id = i.object_id AND vi.index_id = i.index_id;
GO
