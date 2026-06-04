/* =============================================================================
   30_fixed_query.sql   (LIVE DEMO -- Block 4, Slide D.7)   *** THE REVEAL ***

   The tuned query Claude Code should converge on. Same business question, same
   result set (6,256 rows on the build container -- diff it against the slow
   query to prove correctness), about 200x less work.

   Measured on the build container:
       slow  10_slow_query.sql : CPU ~58,000 ms
       fast  this query        : CPU ~290 ms       (~200x less CPU)
   (Trust CPU time, not elapsed -- see the STAGE TIP in 10_slow_query.sql.)

   WHAT CHANGED, and why each change matters -- this is the talk track:

     1. YEAR(v.InspectDate) = 2023   ->   a half-open date RANGE
        v.InspectDate >= '2023-01-01' AND v.InspectDate < '2024-01-01'
        SARGable: the engine can range-seek/scan a date boundary instead of
        evaluating a function on every row. (Half-open avoids midnight/boundary
        bugs -- no BETWEEN ... '2023-12-31'.)

     2. Severity LIKE '%Priority%'   ->   Severity IN (N'Priority', N'Priority Foundation')
        Says exactly what we mean, and is SARGable (no leading wildcard).

     3. Correlated subquery with LTRIM(fi.HSISID)   ->   OUTER APPLY with a clean
        predicate (fi.HSISID = v.HSISID). Dropping the function lets the optimizer
        SEEK IX_FoodInspection_HSISID -- which already INCLUDEs InspectionDate and
        Score, so it's a covering seek. The tempdb Index Spool and the PAGELATCH_EX
        / CXSYNC_PORT contention disappear. OUTER APPLY (not INNER) preserves the
        rows whose establishment has no prior inspection -- same semantics as the
        original correlated subquery, which returned NULL for those.

   No schema change is required for the 200x win -- the rewrite alone does it,
   using indexes the container already ships. The OPTIONAL index at the bottom is
   the "validate the AI's index suggestion" exercise from Slide D.6.
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
    asof.Score    AS score_as_of_violation
FROM dbo.FoodInspectionViolation AS v
   INNER JOIN dbo.Restaurant AS r
      ON r.HSISID = v.HSISID
   OUTER APPLY (
      SELECT TOP (1) fi.Score
      FROM dbo.FoodInspection AS fi
      WHERE fi.HSISID = v.HSISID
         AND fi.InspectionDate <= v.InspectDate
      ORDER BY fi.InspectionDate DESC
   ) AS asof
WHERE v.Severity IN (N'Priority', N'Priority Foundation')
  AND r.City = N'RALEIGH'
  AND v.InspectDate >= '2023-01-01'
  AND v.InspectDate <  '2024-01-01'
ORDER BY v.InspectDate DESC;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

/* ---------------------------------------------------------------------------
   PROVE IT'S THE SAME ANSWER (run once; expect 0 rows from the EXCEPT both ways).
   --------------------------------------------------------------------------- */
-- ;WITH slow AS ( <paste 10_slow_query.sql's SELECT, minus ORDER BY> ),
--       fast AS ( <paste this query's SELECT,     minus ORDER BY> )
-- SELECT 'in slow not fast' AS diff, * FROM slow EXCEPT SELECT 'x',* FROM fast
-- UNION ALL
-- SELECT 'in fast not slow', * FROM fast EXCEPT SELECT 'x',* FROM slow;

/* ---------------------------------------------------------------------------
   OPTIONAL -- the index the missing-index hint will suggest. After the rewrite
   the only remaining work is a single scan of FoodInspectionViolation to apply
   the date + severity filter. A covering index turns that scan into a seek:

       CREATE NONCLUSTERED INDEX IX_FIV_InspectDate_Severity
           ON dbo.FoodInspectionViolation (InspectDate, Severity)
           INCLUDE (HSISID, ShortDesc);

   VALIDATE BEFORE YOU TRUST IT: on this dataset the rewrite alone is
   already sub-second, so this index is a judgment call -- it speeds the filter
   but adds write/storage cost to a 310k-row table and a maintenance obligation.
   Measure the before/after and decide whether it earns its keep. (Note: this
   table has no vector index yet, so it is still writable; once a DiskANN index
   is built on it, the table goes read-only and you'd add this index first.)
   --------------------------------------------------------------------------- */
GO
