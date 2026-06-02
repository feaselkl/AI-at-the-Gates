# Runbook: Index and Statistics Maintenance

## Purpose
Keep indexes and statistics healthy without causing production impact. Owner:
Database Platform team.

## Policy
- We use a threshold-based job (nightly, 02:30) rather than blanket rebuilds:
  - Fragmentation **5%–30%**: `ALTER INDEX ... REORGANIZE` (online, lightweight).
  - Fragmentation **> 30%**: `ALTER INDEX ... REBUILD`. Use `WITH (ONLINE = ON)`
    on Enterprise edition to avoid blocking; offline rebuilds take a schema-mod
    lock and will block the table.
  - Skip indexes smaller than 1,000 pages — fragmentation there is noise.
- Update statistics with `FULLSCAN` weekly on the largest tables; rely on
  auto-update for the rest.

## Symptoms that suggest maintenance is overdue
- Query plans suddenly choosing scans over seeks.
- Cardinality estimates wildly off (estimated vs actual rows differ by orders of
  magnitude) — usually stale statistics, fixed by an `UPDATE STATISTICS`.
- Growing logical fragmentation reported by `sys.dm_db_index_physical_stats`.

## Cautions
- Index **rebuilds generate a lot of transaction log**; on databases in FULL
  recovery this can balloon log backups. Schedule around the backup window.
- An online rebuild still needs a brief schema lock at the end to swap the index
  in; long-running transactions can block that final step.
- Do not rebuild during the nightly ETL load — see the failed-nightly-ETL
  post-mortem for what happens when these overlap.

## Vector indexes (SQL Server 2025)
DiskANN vector indexes are different from B-tree indexes and aren't part of this
job. They're rebuilt manually after large data changes; the table is read-only
while the (current) version of the vector index exists.
