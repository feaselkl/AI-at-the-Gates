# Runbook: Backup and Restore (Production SQL Server)

## Purpose
How our team backs up production databases and how to restore them during an
incident. Owner: Database Platform team. Review cadence: quarterly.

## Backup schedule
- **Full backups:** nightly at 01:00 to the `\\backupsan\sql\full` share.
- **Differential backups:** every 6 hours.
- **Transaction log backups:** every 15 minutes for all databases in FULL
  recovery model. This caps potential data loss (RPO) at roughly 15 minutes.
- Backups are written with `CHECKSUM` and verified nightly with `RESTORE
  VERIFYONLY`. A weekly test restore runs on the recovery server.

## Restore: point-in-time recovery
1. Identify the most recent full backup before the target time, plus the
   differential and the chain of log backups up to the target time.
2. Restore the full backup `WITH NORECOVERY`.
3. Restore the latest differential `WITH NORECOVERY`.
4. Restore each log backup in order `WITH NORECOVERY`; for the final one use
   `WITH STOPAT = '<target time>', RECOVERY`.
5. Run `DBCC CHECKDB` on the restored database before handing it back to the app
   team.

## Common pitfalls
- A broken log chain (someone took an out-of-band backup, or the model was
  switched to SIMPLE) makes point-in-time restore impossible — you can only
  restore to the last full/diff. Never switch recovery models without a change
  ticket.
- Restoring over a database in an Availability Group requires removing it from
  the AG first. See the Availability Group failover runbook.
- Watch free space on the restore target; a restore needs room for the full data
  and log files.

## Escalation
If the most recent backups are missing or corrupt, page the on-call DBA and open
a Sev-2. Do not delete the existing (possibly damaged) database until a restore
is confirmed good.
