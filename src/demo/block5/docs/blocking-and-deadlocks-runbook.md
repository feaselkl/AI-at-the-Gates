# Runbook: Blocking and Deadlocks

## Purpose
Diagnose and resolve blocking chains and deadlocks. Symptom from users is usually
"the application is frozen" or "saving takes forever."

## Triage: is it blocking?
1. Check `sys.dm_exec_requests` for sessions with a non-zero `blocking_session_id`.
2. Find the head blocker — the session that is blocking others but is not itself
   blocked. Look at what it's waiting on (`wait_type`) and its open transaction
   (`sys.dm_tran_active_transactions`).
3. Common causes: a long-running transaction left open by an application bug, a
   report running under the default isolation level taking shared locks, or an
   index rebuild holding a schema lock.

## Resolving blocking
- Prefer fixing the head blocker (commit/rollback its transaction) over killing
  sessions. If you must, `KILL <session_id>` the head blocker and confirm the
  chain clears.
- Long-term fixes: add the missing index causing a scan-and-lock, enable Read
  Committed Snapshot Isolation (RCSI) so readers don't block writers, or fix the
  app to keep transactions short.

## Deadlocks
- A deadlock is two sessions each holding a lock the other needs; SQL Server picks
  a victim and rolls it back (error 1205). The app should retry the victim.
- Capture the deadlock graph from the `system_health` Extended Events session
  (it's on by default) to see the resources and queries involved.
- Typical fixes: access objects in a consistent order across transactions, keep
  transactions short, add a covering index to reduce lock footprint.

## Escalation
If blocking persists and is customer-impacting, page on-call. Note the head
blocker's login and query so we can follow up with the owning team.
