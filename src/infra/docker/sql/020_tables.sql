/* =============================================================================
   020_tables.sql
   Creates the destination tables: Restaurant, FoodInspection, and
   FoodInspectionViolation. All three relate on HSISID (the establishment id).

   Column widths are sized from the actual Wake County, NC source data (with
   headroom). Source timestamps are all UTC ("+00"), so the date columns are
   DATETIME2 in UTC -- see 030_load.sql for the conversion.

   Each free-text column that we want to search semantically gets a *nullable*
   VECTOR column. We do NOT populate these at build time; embeddings and the
   vector index are created live in the demo (see src/demo/block4/). VECTOR(1024) matches
   the Harrier embedding model (microsoft/harrier-oss-v1-0.6b) served via Ollama.
   If you embed with a different model in the demo, change the dimension to match.

   Runs automatically during the Docker build. Safe to edit before delivery day.
   ============================================================================= */

USE WakeCountyFood;
GO

DROP TABLE IF EXISTS dbo.FoodInspectionViolation;
DROP TABLE IF EXISTS dbo.FoodInspection;
DROP TABLE IF EXISTS dbo.Restaurant;
GO

/* ---------------------------------------------------------------------------
   Restaurant  (source: Restaurants.csv -- one row per establishment)
   The link-back table: turns an HSISID into a real restaurant name/address/
   location. HSISID is unique here. NOTE: this is a current-restaurants snapshot,
   so it covers only ~half of the establishments that appear in FoodInspection
   (the rest are closed or non-restaurant facilities). Join with a LEFT JOIN and
   expect some inspections to have no matching restaurant. No FK is enforced for
   this reason. Not used for vector search -- relational link-back only.
   --------------------------------------------------------------------------- */
CREATE TABLE dbo.Restaurant
(
    OBJECTID      INT            NOT NULL,   -- surrogate key from the source system
    HSISID        VARCHAR(30)    NOT NULL,   -- establishment id (links to FoodInspection/Violation)
    Name          NVARCHAR(100)  NULL,
    Address1      NVARCHAR(100)  NULL,
    Address2      NVARCHAR(100)  NULL,
    City          NVARCHAR(50)   NULL,
    [State]       VARCHAR(2)     NULL,
    PostalCode    VARCHAR(20)    NULL,
    PhoneNumber   VARCHAR(30)    NULL,
    OpenDate      DATETIME2(0)   NULL,       -- source RESTAURANTOPENDATE, UTC
    FacilityType  NVARCHAR(60)   NULL,       -- e.g. "1 - Restaurant"
    Longitude     DECIMAL(9, 6)  NULL,       -- source X; 0 = ungeocoded
    Latitude      DECIMAL(9, 6)  NULL,       -- source Y; 0 = ungeocoded
    GeocodeStatus VARCHAR(5)     NULL,
    PermitID      VARCHAR(50)    NULL,
    -- (the source SHAPE column is always empty and is not loaded)
    CONSTRAINT PK_Restaurant PRIMARY KEY CLUSTERED (OBJECTID)
);
GO

/* ---------------------------------------------------------------------------
   FoodInspection  (source: Food_Inspections.csv -- one row per inspection)
   --------------------------------------------------------------------------- */
CREATE TABLE dbo.FoodInspection
(
    OBJECTID             INT            NOT NULL,   -- surrogate key from the source system
    HSISID               VARCHAR(30)    NULL,       -- establishment identifier (join key)
    Score                DECIMAL(5, 2)  NULL,       -- inspection score, 0-100
    InspectionDate       DATETIME2(0)   NULL,       -- source DATE_, UTC
    [Description]        NVARCHAR(MAX)  NULL,       -- inspector narrative  <-- embedded in the demo
    InspectionType       VARCHAR(50)    NULL,       -- source TYPE, e.g. "1 - INSPECTION"
    Inspector            NVARCHAR(100)  NULL,
    PermitID             VARCHAR(50)    NULL,
    DescriptionEmbedding VECTOR(1024)   NULL,       -- populated live (AI_GENERATE_EMBEDDINGS)
    CONSTRAINT PK_FoodInspection PRIMARY KEY CLUSTERED (OBJECTID)
);
GO

/* ---------------------------------------------------------------------------
   FoodInspectionViolation  (source: Food_Inspection_Violations.csv)
   One row per violation observed; joins to FoodInspection on HSISID (+ date).
   --------------------------------------------------------------------------- */
CREATE TABLE dbo.FoodInspectionViolation
(
    OBJECTID           INT            NOT NULL,
    HSISID             VARCHAR(30)    NULL,         -- establishment identifier (join key)
    InspectDate        DATETIME2(0)   NULL,         -- source INSPECTDATE, UTC
    Category           NVARCHAR(100)  NULL,
    StateCode          NVARCHAR(50)   NULL,
    QuestionNo         INT            NULL,
    ViolationCode      VARCHAR(2048)  NULL,         -- some rows concatenate codes (max ~1024 observed)
    Severity           NVARCHAR(50)   NULL,         -- e.g. "Core", "Priority"
    ShortDesc          NVARCHAR(256)  NULL,         -- standardized description  <-- embedded in the demo
    InspectedBy        NVARCHAR(100)  NULL,
    Comments           NVARCHAR(MAX)  NULL,         -- free-text observations    <-- embedded in the demo
    PointValue         DECIMAL(6, 2)  NULL,
    ObservationType    NVARCHAR(50)   NULL,         -- e.g. "Out", "In"
    ViolationType      NVARCHAR(50)   NULL,
    CDCRiskFactor      NVARCHAR(50)   NULL,
    CDCDataItem        NVARCHAR(50)   NULL,
    PermitID           VARCHAR(50)    NULL,
    ShortDescEmbedding VECTOR(1024)   NULL,         -- populated live (AI_GENERATE_EMBEDDINGS)
    CommentsEmbedding  VECTOR(1024)   NULL,         -- populated live (AI_GENERATE_EMBEDDINGS)
    CONSTRAINT PK_FoodInspectionViolation PRIMARY KEY CLUSTERED (OBJECTID)
);
GO

PRINT 'Tables Restaurant, FoodInspection, and FoodInspectionViolation created.';
GO
