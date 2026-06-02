# Post-mortem: Nightly ETL Load Failure (2026-02-18)

## Summary
On the night of 2026-02-18 the nightly ETL load into the warehouse failed and the
morning dashboards were stale. Root cause was a transaction log that filled up
because an index rebuild ran at the same time as the bulk load, and the log backup
job could not keep up. Customer impact: ~3 hours of stale reporting. Severity: 2.

## Timeline
- 02:30 — the index maintenance job started a REBUILD of a large clustered index.
- 02:34 — the ETL bulk load began inserting ~40 million rows.
- 02:51 — the transaction log for the warehouse database hit 100% and the load
  failed with error 9002 ("transaction log is full").
- 03:05 — on-call paged. 03:20 — added a temporary log file to get breathing room
  and let the log backup drain the log. 05:10 — re-ran the ETL successfully.

## Root cause
The index rebuild and the bulk load both generated heavy transaction log at once.
Under FULL recovery the log can only be truncated after a log backup, and the
15-minute log backups couldn't drain it fast enough. The two heavy jobs were never
meant to overlap; a schedule change three weeks earlier moved the ETL 30 minutes
earlier, into the maintenance window.

## What fixed it
- Added a second log file temporarily (error 9002 immediate relief).
- Took an out-of-cycle log backup to truncate the log.
- Re-ran the ETL after the rebuild finished.

## Preventive actions
- Separate the maintenance window from the ETL window; the index job now starts
  only after the ETL "load complete" signal.
- Pre-size the warehouse log for the known nightly volume instead of relying on
  autogrowth.
- Alert when log used % exceeds 70% during the load window.

## Lesson
Never schedule index rebuilds to overlap a large load on a FULL-recovery database.
See the index maintenance and backup/restore runbooks.
