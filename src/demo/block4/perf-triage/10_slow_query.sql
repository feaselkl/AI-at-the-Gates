/* =============================================================================
   10_slow_query.sql   (LIVE DEMO -- Block 4, Slide D.7)

   THE PATIENT. A realistic, deliberately slow query against the stock
   WakeCountyFood container. This is the query we hand to Claude Code
   (in VS Code) to triage in front of the room. The fix lives in
   30_fixed_query.sql; don't open it until the reveal.

   The business question (a real DBA would actually be asked this):
     "For every Priority / Priority Foundation violation at a RALEIGH restaurant
      in 2023, show the establishment's inspection score as of the violation date."
   The answer is correct. The query is just slow -- about 200x slower than it
   needs to be -- and it's slow for three classic, layered reasons that a DBA
   audience will recognize the moment the plan is on screen:

     1. NON-SARGABLE DATE FILTER -- YEAR(v.InspectDate) = 2023 wraps the column
        in a function, so the engine can't range-seek a date; it scans.
     2. NON-SARGABLE SEVERITY FILTER -- Severity LIKE '%Priority%' (leading
        wildcard) can't seek either, and it's a sloppy stand-in for an IN list.
     3. CORRELATED SUBQUERY WITH A FUNCTION ON THE JOIN COLUMN --
        LTRIM(fi.HSISID) = v.HSISID defeats the covering index
        IX_FoodInspection_HSISID, so the optimizer materializes an Index Spool
        in tempdb and rewinds it once per outer row. Under a parallel plan the
        worker threads then fight over that spool -- the dominant cost.

   Measured on the build container (your numbers will vary with hardware/load):
     CPU time ~58,000 ms; reliably the same order of magnitude every run.
     Dominant waits: PAGELATCH_EX (tempdb spool contention) and CXSYNC_PORT
     (parallelism). The plan carries two Index Spool operators. See
     20_capture_diagnostics.sql to pull these yourself.

   ============================================================================= */

USE WakeCountyFood;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT
    r.Name AS restaurant,
    r.City,
    v.InspectDate,
    v.ShortDesc,
    (
      SELECT TOP (1) fi.Score
        FROM dbo.FoodInspection AS fi
        WHERE LTRIM(fi.HSISID) = v.HSISID
          AND fi.InspectionDate <= v.InspectDate
        ORDER BY fi.InspectionDate DESC
    ) AS score_as_of_violation
FROM dbo.FoodInspectionViolation AS v
INNER JOIN dbo.Restaurant AS r
   ON r.HSISID = v.HSISID
WHERE v.Severity LIKE '%Priority%'
  AND r.City      = N'RALEIGH'
  AND YEAR(v.InspectDate) = 2023
ORDER BY v.InspectDate DESC;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO
