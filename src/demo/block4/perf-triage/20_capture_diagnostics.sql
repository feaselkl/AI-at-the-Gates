/* =============================================================================
   20_capture_diagnostics.sql   (LIVE DEMO -- Block 4, Slide D.7)

   THE EVIDENCE. Three ways to see *why* 10_slow_query.sql is slow. In the demo
   you can run these yourself and read them out. Or, better yet, let Claude Code
   run them (it has a Bash tool and can shell into the container with sqlcmd) and
   narrate the diagnosis for you. See ../perf-triage/README.md for the prompts.

   The point we want the room to internalize: you triage in two passes
     WAITS first ("what was the server waiting ON?")  -> narrows the suspect list
     PLAN  second ("what is the query DOING?")        -> names the root cause
   ============================================================================= */

USE WakeCountyFood;
GO

/* ---------------------------------------------------------------------------
   PASS 1 -- WAITS, scoped to THIS query (the honest, per-statement way).

   Each sqlcmd connection is its own session, so we reset the session wait
   counters, run the query (results dumped to a throwaway temp table so the grid
   doesn't flood the screen), then read the session's waits back. This is far
   cleaner than sys.dm_os_wait_stats, which is instance-wide and full of idle
   background noise.
   --------------------------------------------------------------------------- */
DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR) WITH NO_INFOMSGS;  -- optional: clear instance view too
GO

-- reset THIS session's wait accounting
SET STATISTICS TIME ON;
GO
DECLARE @baseline TABLE (restaurant NVARCHAR(100), City NVARCHAR(50),
                         InspectDate DATETIME2(0), ShortDesc NVARCHAR(256), score DECIMAL(5,2));

INSERT INTO @baseline
SELECT
    r.Name, r.City, v.InspectDate, v.ShortDesc,
    (SELECT TOP (1) fi.Score FROM dbo.FoodInspection AS fi
      WHERE LTRIM(fi.HSISID) = v.HSISID AND fi.InspectionDate <= v.InspectDate
      ORDER BY fi.InspectionDate DESC)
FROM dbo.FoodInspectionViolation AS v
INNER JOIN dbo.Restaurant AS r ON r.HSISID = v.HSISID
WHERE v.Severity LIKE '%Priority%' AND r.City = N'RALEIGH' AND YEAR(v.InspectDate) = 2023;
GO

-- Top waits this session has accumulated, biggest first.
SELECT TOP (12)
    wait_type,
    waiting_tasks_count,
    wait_time_ms,
    max_wait_time_ms,
    signal_wait_time_ms                 -- time runnable-but-waiting-for-CPU (CPU pressure tell)
FROM sys.dm_exec_session_wait_stats
WHERE session_id = @@SPID
ORDER BY wait_time_ms DESC;
GO
/*  EXPECTED (build container): PAGELATCH_EX dominates (tempdb spool contention),
    then CXSYNC_PORT / CXSYNC_CONSUMER (parallelism), then SOS_SCHEDULER_YIELD
    with a high waiting_tasks_count (CPU-bound churn). I/O waits (PAGEIOLATCH_*)
    are absent -- this is NOT a storage problem, and there is no other user to
    block us, so the contention is *self-inflicted* by the plan.  */


/* ---------------------------------------------------------------------------
   PASS 2 -- THE PLAN. Grab the *actual* execution plan. The root operator's
   QueryTimeStats and WaitStats live in the XML, and the shape names the cause.

   In SSMS / Azure Data Studio: toggle "Include Actual Execution Plan" and run
   10_slow_query.sql. From sqlcmd, SET STATISTICS XML ON returns the plan as a
   result column you can save to a .sqlplan file and hand to Claude Code.
   --------------------------------------------------------------------------- */
SET STATISTICS XML ON;
GO
-- (re-run the slow query here, or just point SSMS at 10_slow_query.sql)
SELECT
    r.Name AS restaurant, r.City, v.InspectDate, v.ShortDesc,
    (SELECT TOP (1) fi.Score FROM dbo.FoodInspection AS fi
      WHERE LTRIM(fi.HSISID) = v.HSISID AND fi.InspectionDate <= v.InspectDate
      ORDER BY fi.InspectionDate DESC) AS score_as_of_violation
FROM dbo.FoodInspectionViolation AS v
INNER JOIN dbo.Restaurant AS r ON r.HSISID = v.HSISID
WHERE v.Severity LIKE '%Priority%' AND r.City = N'RALEIGH' AND YEAR(v.InspectDate) = 2023
ORDER BY v.InspectDate DESC;
GO
SET STATISTICS XML OFF;
GO
/*  WHAT TO LOOK FOR IN THE PLAN:
      - Index SCAN on FoodInspection and FoodInspectionViolation (not Seek) --
        the LIKE / YEAR() / LTRIM() predicates can't seek.
      - Two "Index Spool" operators + a parallel (DegreeOfParallelism=8) plan --
        the materialized-and-rewound correlated subquery and the contention it
        causes.
      - Root <QueryTimeStats> CpuMs >> the I/O cost: the work is CPU + latch
        waits, not reads. (STATISTICS IO showed only ~362 logical reads on
        FoodInspection -- a classic "cheap reads, expensive query" tell.)        */


/* ---------------------------------------------------------------------------
   OPTIONAL -- "Why is the plan choosing scans?" Show the missing-index hint and
   the cardinality the optimizer expects. (The hint is a starting point, not
   gospel -- we discuss whether it's worth its write cost in the README / D.6.)
   --------------------------------------------------------------------------- */
-- The actual plan XML also carries a <MissingIndexes> node when one applies;
-- SSMS surfaces it as the green "Missing Index" suggestion above the plan.
GO
