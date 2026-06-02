/* =============================================================================
   40_vector_search.sql   (LIVE DEMO -- not run at build)

   Three ways to search, all joining back to dbo.Restaurant so results show a real
   restaurant name/city instead of an opaque HSISID:
     A. Exact kNN with VECTOR_DISTANCE -- GA, no index needed.
     B. Approximate (ANN) with VECTOR_SEARCH over the DiskANN index -- preview.
     C. Filtered search -- narrow by restaurant metadata (city), then exact kNN.

   The query text is embedded on the fly with the same model, so the query vector
   matches the stored vectors' dimensions (1024, from Harrier).

   Restaurant link-back note: dbo.Restaurant is a current-restaurants snapshot, so
   it doesn't cover every inspected establishment. A/B use LEFT JOIN (name may be
   NULL); C uses INNER JOIN because the city filter implies a known restaurant.
   ============================================================================= */

USE WakeCountyFood;
GO

/* ---------------------------------------------------------------------------
   A. Exact kNN  (VECTOR_DISTANCE) -- "find inspections whose narrative is most
      similar to this concern," with the restaurant name attached.
   --------------------------------------------------------------------------- */
DECLARE @q VECTOR(1024) =
    AI_GENERATE_EMBEDDINGS(N'food stored at unsafe temperature' USE MODEL HarrierEmbeddings);

SELECT TOP (10)
    r.Name AS restaurant,             -- NULL when the snapshot has no match for this HSISID
    r.City,
    fi.InspectionDate,
    fi.Score,
    LEFT(fi.[Description], 120) AS description_snippet,
    VECTOR_DISTANCE('cosine', @q, fi.DescriptionEmbedding) AS distance
FROM dbo.FoodInspection AS fi
LEFT JOIN dbo.Restaurant AS r ON r.HSISID = fi.HSISID
WHERE fi.DescriptionEmbedding IS NOT NULL
ORDER BY distance;            -- smaller cosine distance = more similar
GO

/* ---------------------------------------------------------------------------
   B. Approximate (ANN) with the DiskANN index, over violation comments.
      SQL Server 2025 form: pass TOP_N inside VECTOR_SEARCH.
   --------------------------------------------------------------------------- */
DECLARE @qv VECTOR(1024) =
    AI_GENERATE_EMBEDDINGS(N'rodent or pest activity in the kitchen' USE MODEL HarrierEmbeddings);

SELECT
    r.Name AS restaurant,
    r.City,
    v.ShortDesc,
    LEFT(v.Comments, 160) AS comments_snippet,
    s.distance
FROM VECTOR_SEARCH(
        TABLE      = dbo.FoodInspectionViolation AS v,
        COLUMN     = CommentsEmbedding,
        SIMILAR_TO = @qv,
        METRIC     = 'cosine',
        TOP_N      = 10
     ) AS s
LEFT JOIN dbo.Restaurant AS r ON r.HSISID = v.HSISID
ORDER BY s.distance;
GO

/* ---------------------------------------------------------------------------
   C. Filtered vector search -- "pest-like violations at restaurants in Raleigh."
      The metadata filter (City) shrinks the candidate set, so exact kNN over the
      filtered rows is the right tool (no ANN index needed once the set is small).
      This is the filtered-search pattern from 4.3, made concrete by the link-back.
   --------------------------------------------------------------------------- */
DECLARE @qf VECTOR(1024) =
    AI_GENERATE_EMBEDDINGS(N'rodent or pest activity in the kitchen' USE MODEL HarrierEmbeddings);

SELECT TOP (10)
    r.Name AS restaurant,
    r.City,
    v.ShortDesc,
    LEFT(v.Comments, 160) AS comments_snippet,
    VECTOR_DISTANCE('cosine', @qf, v.CommentsEmbedding) AS distance
FROM dbo.FoodInspectionViolation AS v
INNER JOIN dbo.Restaurant AS r ON r.HSISID = v.HSISID
WHERE v.CommentsEmbedding IS NOT NULL
  AND r.City = N'RALEIGH'
ORDER BY distance;
GO

/* ---------------------------------------------------------------------------
   B'. On Azure SQL Database / SQL database in Fabric (latest index version), the
       ANN query uses SELECT TOP (N) WITH APPROXIMATE instead of TOP_N:

   DECLARE @qv VECTOR(1024) =
       AI_GENERATE_EMBEDDINGS(N'rodent or pest activity in the kitchen' USE MODEL HarrierEmbeddings);

   SELECT TOP (10) WITH APPROXIMATE
       r.Name, r.City, v.ShortDesc, s.distance
   FROM VECTOR_SEARCH(
           TABLE      = dbo.FoodInspectionViolation AS v,
           COLUMN     = CommentsEmbedding,
           SIMILAR_TO = @qv,
           METRIC     = 'cosine'
        ) AS s
   LEFT JOIN dbo.Restaurant AS r ON r.HSISID = v.HSISID
   ORDER BY s.distance;
   --------------------------------------------------------------------------- */
