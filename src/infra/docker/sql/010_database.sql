/* =============================================================================
   010_database.sql
   Creates the WakeCountyFood database and enables the preview features that
   SQL Server 2025 requires for vector *indexing*.

   Runs automatically during the Docker build (see ../build/init-build.sh).
   Safe to edit or remove before delivery day.

   Notes:
   - The VECTOR data type itself is GA in SQL Server 2025 and needs no flag.
   - CREATE VECTOR INDEX / VECTOR_SEARCH (the live demo) require the database
     scoped configuration PREVIEW_FEATURES = ON. Setting it here bakes it into
     the image so learners do not have to enable it themselves.
   ============================================================================= */

IF DB_ID(N'WakeCountyFood') IS NULL
BEGIN
    PRINT 'Creating database WakeCountyFood...';
    CREATE DATABASE WakeCountyFood;
END
GO

ALTER DATABASE WakeCountyFood SET RECOVERY SIMPLE;   -- classroom image; keeps the log small
GO

USE WakeCountyFood;
GO

-- Required for the live vector-index / VECTOR_SEARCH demo (SQL Server 2025 preview gate).
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO

PRINT 'Database WakeCountyFood ready; PREVIEW_FEATURES = ON.';
GO
