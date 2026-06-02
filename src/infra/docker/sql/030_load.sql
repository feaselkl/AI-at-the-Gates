/* =============================================================================
   030_load.sql
   Bulk-loads the two CSV files into string staging tables, then converts and
   inserts typed rows into FoodInspection / FoodInspectionViolation.

   Why stage first: BULK INSERT cannot transform during load, and the source
   dates ("2020/05/05 00:00:00+00") and decimals need conversion. Loading raw
   text first, then TRY_CONVERT-ing into the typed tables, is robust and easy to
   debug -- a bad value lands as NULL instead of failing the whole load.

   CSV facts (verified against the source files):
     - UTF-8, comma-delimited, RFC-4180 quoting with '"'
     - LF (0x0a) row terminator, header on row 1
     - no embedded newlines; column counts are 8, 17, and 16 exactly

   UTF-8 note: BULK INSERT does not support the CODEPAGE option on SQL Server for
   Linux. Instead, the staging columns use a UTF-8 collation
   (Latin1_General_100_CI_AS_SC_UTF8), so the UTF-8 source bytes load correctly
   without CODEPAGE. The data does contain non-ASCII characters.

   The CSVs are copied to /csv in the Docker build. Runs automatically during
   build. Safe to edit before delivery day.
   ============================================================================= */

USE WakeCountyFood;
GO

IF SCHEMA_ID(N'stg') IS NULL EXEC (N'CREATE SCHEMA stg;');
GO

/* ===============================  Restaurant  ============================== */
DROP TABLE IF EXISTS stg.Restaurant;
GO
CREATE TABLE stg.Restaurant
(
    OBJECTID           VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    HSISID             VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    NAME               VARCHAR(200)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    ADDRESS1           VARCHAR(200)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    ADDRESS2           VARCHAR(200)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    CITY               VARCHAR(100)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    [STATE]            VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    POSTALCODE         VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    PHONENUMBER        VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    RESTAURANTOPENDATE VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    FACILITYTYPE       VARCHAR(100)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    X                  VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    Y                  VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    GEOCODESTATUS      VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    SHAPE              VARCHAR(MAX)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,   -- always empty; staged to match the CSV, not loaded
    PERMITID           VARCHAR(100)  COLLATE Latin1_General_100_CI_AS_SC_UTF8
);
GO

PRINT 'Bulk loading Restaurants.csv ...';
BULK INSERT stg.Restaurant
FROM '/csv/Restaurants.csv'
WITH (
    FORMAT          = 'CSV',
    FIELDQUOTE      = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',
    FIRSTROW        = 2,
    TABLOCK
);
GO

INSERT INTO dbo.Restaurant
    (OBJECTID, HSISID, Name, Address1, Address2, City, [State], PostalCode,
     PhoneNumber, OpenDate, FacilityType, Longitude, Latitude, GeocodeStatus, PermitID)
SELECT
    TRY_CONVERT(INT, OBJECTID),
    NULLIF(LTRIM(RTRIM(HSISID)), ''),
    NULLIF(LTRIM(RTRIM(NAME)), ''),
    NULLIF(LTRIM(RTRIM(ADDRESS1)), ''),
    NULLIF(LTRIM(RTRIM(ADDRESS2)), ''),
    NULLIF(LTRIM(RTRIM(CITY)), ''),
    NULLIF(LTRIM(RTRIM([STATE])), ''),
    NULLIF(LTRIM(RTRIM(POSTALCODE)), ''),
    NULLIF(LTRIM(RTRIM(PHONENUMBER)), ''),
    TRY_CONVERT(DATETIME2(0), LEFT(RESTAURANTOPENDATE, 19), 111),
    NULLIF(LTRIM(RTRIM(FACILITYTYPE)), ''),
    TRY_CONVERT(DECIMAL(9, 6), X),
    TRY_CONVERT(DECIMAL(9, 6), Y),
    NULLIF(LTRIM(RTRIM(GEOCODESTATUS)), ''),
    NULLIF(LTRIM(RTRIM(PERMITID)), '')
FROM stg.Restaurant
WHERE TRY_CONVERT(INT, OBJECTID) IS NOT NULL
  AND NULLIF(LTRIM(RTRIM(HSISID)), '') IS NOT NULL;   -- HSISID is the (NOT NULL) join key
GO

/* ===========================  FoodInspection  ============================== */
DROP TABLE IF EXISTS stg.FoodInspection;
GO
CREATE TABLE stg.FoodInspection
(
    OBJECTID     VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    HSISID       VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    SCORE        VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    DATE_        VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    DESCRIPTION  VARCHAR(MAX)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    TYPE         VARCHAR(100)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    INSPECTOR    VARCHAR(200)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    PERMITID     VARCHAR(100)  COLLATE Latin1_General_100_CI_AS_SC_UTF8
);
GO

PRINT 'Bulk loading Food_Inspections.csv ...';
BULK INSERT stg.FoodInspection
FROM '/csv/Food_Inspections.csv'
WITH (
    FORMAT          = 'CSV',
    FIELDQUOTE      = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',
    FIRSTROW        = 2,
    TABLOCK
);
GO

INSERT INTO dbo.FoodInspection
    (OBJECTID, HSISID, Score, InspectionDate, [Description], InspectionType, Inspector, PermitID)
SELECT
    TRY_CONVERT(INT, OBJECTID),
    NULLIF(LTRIM(RTRIM(HSISID)), ''),
    TRY_CONVERT(DECIMAL(5, 2), SCORE),
    TRY_CONVERT(DATETIME2(0), LEFT(DATE_, 19), 111),   -- "yyyy/MM/dd HH:mm:ss"; offset is always +00 (UTC)
    DESCRIPTION,
    NULLIF(LTRIM(RTRIM(TYPE)), ''),
    NULLIF(LTRIM(RTRIM(INSPECTOR)), ''),
    NULLIF(LTRIM(RTRIM(PERMITID)), '')
FROM stg.FoodInspection
WHERE TRY_CONVERT(INT, OBJECTID) IS NOT NULL;   -- skip any malformed/blank trailing rows
GO

/* ======================  FoodInspectionViolation  ========================= */
DROP TABLE IF EXISTS stg.FoodInspectionViolation;
GO
CREATE TABLE stg.FoodInspectionViolation
(
    OBJECTID        VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    HSISID          VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    INSPECTDATE     VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    CATEGORY        VARCHAR(200)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    STATECODE       VARCHAR(100)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    QUESTIONNO      VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    VIOLATIONCODE   VARCHAR(MAX)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    SEVERITY        VARCHAR(100)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    SHORTDESC       VARCHAR(MAX)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    INSPECTEDBY     VARCHAR(200)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    COMMENTS        VARCHAR(MAX)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    POINTVALUE      VARCHAR(50)   COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    OBSERVATIONTYPE VARCHAR(100)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    VIOLATIONTYPE   VARCHAR(100)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    CDCRISKFACTOR   VARCHAR(100)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    CDCDATAITEM     VARCHAR(100)  COLLATE Latin1_General_100_CI_AS_SC_UTF8,
    PERMITID        VARCHAR(100)  COLLATE Latin1_General_100_CI_AS_SC_UTF8
);
GO

PRINT 'Bulk loading Food_Inspection_Violations.csv ...';
BULK INSERT stg.FoodInspectionViolation
FROM '/csv/Food_Inspection_Violations.csv'
WITH (
    FORMAT          = 'CSV',
    FIELDQUOTE      = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',
    FIRSTROW        = 2,
    TABLOCK
);
GO

INSERT INTO dbo.FoodInspectionViolation
    (OBJECTID, HSISID, InspectDate, Category, StateCode, QuestionNo, ViolationCode, Severity,
     ShortDesc, InspectedBy, Comments, PointValue, ObservationType, ViolationType,
     CDCRiskFactor, CDCDataItem, PermitID)
SELECT
    TRY_CONVERT(INT, OBJECTID),
    NULLIF(LTRIM(RTRIM(HSISID)), ''),
    TRY_CONVERT(DATETIME2(0), LEFT(INSPECTDATE, 19), 111),
    NULLIF(LTRIM(RTRIM(CATEGORY)), ''),
    NULLIF(LTRIM(RTRIM(STATECODE)), ''),
    TRY_CONVERT(INT, QUESTIONNO),
    NULLIF(LTRIM(RTRIM(VIOLATIONCODE)), ''),
    NULLIF(LTRIM(RTRIM(SEVERITY)), ''),
    NULLIF(LTRIM(RTRIM(SHORTDESC)), ''),
    NULLIF(LTRIM(RTRIM(INSPECTEDBY)), ''),
    COMMENTS,
    TRY_CONVERT(DECIMAL(6, 2), POINTVALUE),
    NULLIF(LTRIM(RTRIM(OBSERVATIONTYPE)), ''),
    NULLIF(LTRIM(RTRIM(VIOLATIONTYPE)), ''),
    NULLIF(LTRIM(RTRIM(CDCRISKFACTOR)), ''),
    NULLIF(LTRIM(RTRIM(CDCDATAITEM)), ''),
    NULLIF(LTRIM(RTRIM(PERMITID)), '')
FROM stg.FoodInspectionViolation
WHERE TRY_CONVERT(INT, OBJECTID) IS NOT NULL;
GO

/* Drop staging so the baked image stays lean. */
DROP TABLE IF EXISTS stg.Restaurant;
DROP TABLE IF EXISTS stg.FoodInspection;
DROP TABLE IF EXISTS stg.FoodInspectionViolation;
GO
IF SCHEMA_ID(N'stg') IS NOT NULL EXEC (N'DROP SCHEMA stg;');
GO

PRINT 'Data load complete.';
GO
