/* =============================================================================
   schema.sql  -- structure-only schema context for the Block 3 prompt makeover.

   This is the context you hand the model at step v2 (structure + relationships).
   It deliberately does NOT enumerate the Severity values or define "critical" --
   that domain knowledge is revealed at v3, so the makeover can show the model
   guessing a plausible-but-wrong value when it isn't told. Output format / house
   style / correctness constraints come at v4.

   Three tables, all related on HSISID (the establishment id):
     - dbo.Restaurant            : ~4,100 rows. HSISID is UNIQUE. A current-
                                   restaurants snapshot -- covers only ~half of
                                   inspected establishments, so LEFT JOIN from the
                                   inspection tables (INNER when you only want
                                   named restaurants). No FK is enforced.
     - dbo.FoodInspection        : ~77,000 rows. Many inspections per HSISID over time.
     - dbo.FoodInspectionViolation : ~311,000 rows. Many violations per HSISID over time.
   Dates are DATETIME2 in UTC; the dataset spans ~2012 through early 2026.
   ============================================================================= */

CREATE TABLE dbo.Restaurant (
    OBJECTID     INT          NOT NULL PRIMARY KEY,
    HSISID       VARCHAR(30)  NOT NULL,   -- UNIQUE; links to the inspection tables
    Name         NVARCHAR(100),
    Address1     NVARCHAR(100),
    City         NVARCHAR(50),
    [State]      VARCHAR(2),
    PostalCode   VARCHAR(20),
    OpenDate     DATETIME2(0),
    FacilityType NVARCHAR(60),            -- e.g. '1 - Restaurant'
    Longitude    DECIMAL(9,6),            -- 0 = ungeocoded
    Latitude     DECIMAL(9,6)
    -- (PhoneNumber, GeocodeStatus, PermitID omitted for brevity)
);

CREATE TABLE dbo.FoodInspection (
    OBJECTID       INT          NOT NULL PRIMARY KEY,
    HSISID         VARCHAR(30),           -- establishment (many inspections per HSISID)
    Score          DECIMAL(5,2),          -- inspection score, 0-100
    InspectionDate DATETIME2(0),
    [Description]  NVARCHAR(MAX),         -- inspector narrative
    InspectionType VARCHAR(50),
    Inspector      NVARCHAR(100)
    -- (a DescriptionEmbedding VECTOR(1024) column also exists; not needed here)
);

CREATE TABLE dbo.FoodInspectionViolation (
    OBJECTID      INT          NOT NULL PRIMARY KEY,
    HSISID        VARCHAR(30),            -- establishment (many violations per HSISID)
    InspectDate   DATETIME2(0),
    ViolationCode VARCHAR(2048),
    Severity      NVARCHAR(50),           -- values matter -- tell the model what they are (see v3)
    ShortDesc     NVARCHAR(256),
    Comments      NVARCHAR(MAX),          -- free-text observations
    PointValue    DECIMAL(6,2)
    -- (ShortDescEmbedding / CommentsEmbedding VECTOR(1024) columns also exist; not needed here)
);
