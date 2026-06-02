/* =============================================================================
   040_post_load.sql
   Adds the join indexes and validates the load. If either table came back
   empty, this RAISERROR fails the Docker build instead of shipping an empty
   image -- catch the problem at build time, not in front of the room.

   Restaurant, FoodInspection, and FoodInspectionViolation relate on HSISID (the
   establishment). HSISID is unique in Restaurant but NOT unique in the other two
   (an establishment has many inspections/violations over time). No foreign key is
   enforced: Restaurant is a current-restaurants snapshot and doesn't cover every
   inspected establishment, so a FK would reject the orphans. Join on HSISID
   (LEFT JOIN from inspections to Restaurant), plus the date for a single inspection.

   Runs automatically during the Docker build. Safe to edit before delivery day.
   ============================================================================= */

USE WakeCountyFood;
GO

-- HSISID is unique in Restaurant; this index enforces that and speeds link-back joins.
CREATE UNIQUE NONCLUSTERED INDEX UQ_Restaurant_HSISID
    ON dbo.Restaurant (HSISID) INCLUDE (Name, City, [State]);
GO

CREATE NONCLUSTERED INDEX IX_FoodInspection_HSISID
    ON dbo.FoodInspection (HSISID) INCLUDE (InspectionDate, Score);
GO

CREATE NONCLUSTERED INDEX IX_FoodInspectionViolation_HSISID
    ON dbo.FoodInspectionViolation (HSISID) INCLUDE (InspectDate, Severity);
GO

DECLARE @restaurants INT = (SELECT COUNT(*) FROM dbo.Restaurant);
DECLARE @inspections INT = (SELECT COUNT(*) FROM dbo.FoodInspection);
DECLARE @violations  INT = (SELECT COUNT(*) FROM dbo.FoodInspectionViolation);
DECLARE @matched     INT = (SELECT COUNT(DISTINCT fi.HSISID)
                            FROM dbo.FoodInspection fi
                            WHERE EXISTS (SELECT 1 FROM dbo.Restaurant r WHERE r.HSISID = fi.HSISID));

PRINT CONCAT('Restaurant rows              : ', @restaurants);
PRINT CONCAT('FoodInspection rows          : ', @inspections);
PRINT CONCAT('FoodInspectionViolation rows : ', @violations);
PRINT CONCAT('Inspection establishments with a Restaurant match: ', @matched);

IF @restaurants = 0 OR @inspections = 0 OR @violations = 0
    RAISERROR('Load validation FAILED: a table is empty.', 16, 1);
ELSE
    PRINT 'Load validation passed.';
GO
