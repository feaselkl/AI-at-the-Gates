# Runbook: tempdb Contention

## Purpose
Recognize and relieve tempdb allocation contention, which shows up as
intermittent, instance-wide slowness that doesn't map to a single query.

## Symptoms
- Many sessions waiting on `PAGELATCH_UP` / `PAGELATCH_EX` on pages in database
  id 2 (tempdb), often pages like `2:1:1` (PFS), `2:1:2` (GAM), `2:1:3` (SGAM).
- Slowness correlates with workload that creates many temp tables or table
  variables, or heavy sort/hash spills.

## Diagnosis
1. Query `sys.dm_exec_requests` / `sys.dm_os_waiting_tasks` and look for
   `PAGELATCH` waits with a `resource_description` pointing at tempdb system pages.
2. Check how many tempdb data files exist and whether they're equally sized.

## Standard fixes
- **Multiple, equally sized tempdb data files.** Start with a number equal to the
  number of logical processors up to 8; add more (in multiples of 4) only if
  contention persists. All files must be the **same size** with the **same
  autogrowth**, or the proportional-fill algorithm sends most allocations to one
  file and reintroduces the hot spot.
- Modern SQL Server enables uniform extent allocation and auto-growth-all-files
  for tempdb by default; confirm these are on.
- Reduce the workload's tempdb footprint: fix spills with better indexes/stats,
  avoid unnecessary temp tables, and review code that creates large table
  variables.

## Cautions
- Do not put tempdb on the same slow volume as user data/log. Fast local NVMe is
  ideal; tempdb is recreated on restart so durability isn't a concern.
- Changing tempdb file count/size requires a SQL Server service restart to take
  effect.
