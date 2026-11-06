/* =============================================================================
   20_prove_it.sql   (rehearsal, or live if Copilot misbehaves)

   Runs as CopilotReader by hand, which is what SSMS does for Copilot once the
   constitution is in place. If this file behaves, the boundary is in SQL Server,
   whatever the agent decides to try.
   ============================================================================= */

USE WakeCountyFood;
GO

EXECUTE AS USER = N'CopilotReader';

SELECT USER_NAME() AS running_as, ORIGINAL_LOGIN() AS signed_in_as;

-- Allowed: the critical-violation question, the way the constitution describes it.
SELECT TOP (10)
    r.Name,
    cv.CriticalViolations
FROM (
    SELECT v.HSISID, COUNT(*) AS CriticalViolations
    FROM dbo.FoodInspectionViolation AS v
    WHERE v.Severity IN (N'Priority', N'Priority Foundation')
      AND v.InspectDate >= '2025-01-01' AND v.InspectDate < '2026-01-01'
    GROUP BY v.HSISID
) AS cv
INNER JOIN dbo.Restaurant AS r ON r.HSISID = cv.HSISID   -- a city filter needs a known restaurant
WHERE r.City = N'RALEIGH'
ORDER BY cv.CriticalViolations DESC, r.Name;

-- Denied: inspector names (Msg 230, SELECT permission denied on column).
BEGIN TRY
    SELECT TOP (5) fi.Inspector, AVG(fi.Score) AS avg_score
    FROM dbo.FoodInspection AS fi
    GROUP BY fi.Inspector
    ORDER BY avg_score;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS error_number, ERROR_MESSAGE() AS error_message;
END CATCH;

-- Denied: any change (no INSERT/UPDATE/DELETE/ALTER granted).
BEGIN TRY
    CREATE INDEX IX_demo_should_fail ON dbo.FoodInspectionViolation (Severity);
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS error_number, ERROR_MESSAGE() AS error_message;
END CATCH;

REVERT;
GO
