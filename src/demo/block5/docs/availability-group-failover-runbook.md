# Runbook: Always On Availability Group Failover

## Purpose
Plan and execute failover of our production Always On Availability Group (AG), and
recognize when an automatic failover has happened.

## Topology
- AG name `AG-PROD`, two synchronous replicas in the primary datacenter (automatic
  failover between them) plus one asynchronous replica in the DR site (manual
  failover only, possible data loss).
- The listener `agprod-listener` is what applications connect to; it always points
  at the current primary. Apps should connect through the listener, never to a node.

## Planned failover (synchronous replica, no data loss)
1. Confirm the target secondary is **synchronized** (not just synchronizing) in
   the dashboard or `sys.dm_hadr_availability_replica_states`.
2. From the current primary, run `ALTER AVAILABILITY GROUP [AG-PROD] FAILOVER`
   while connected to the target secondary, or use the SSMS failover wizard.
3. Confirm the listener now resolves to the new primary and the app reconnects.

## Forced failover to DR (asynchronous, possible data loss)
- Only during a real datacenter outage and with incident-commander approval.
- `ALTER AVAILABILITY GROUP [AG-PROD] FORCE_FAILOVER_ALLOW_DATA_LOSS`. Because the
  DR replica is asynchronous, transactions not yet shipped are lost; record the
  estimated data loss from `sys.dm_hadr_database_replica_states`.

## After any failover
- Resume data movement on the old primary once it rejoins as a secondary.
- Run `DBCC CHECKDB` if the failover was due to suspected corruption.
- A database in an AG can't be restored over directly — remove it from the AG
  first (see the backup/restore runbook).

## Recognizing an automatic failover
Symptoms: a brief connection blip, the listener pointing at a different node, and
AG health events in the `system_health` session and the SQL error log. Find out
*why* it failed over (node reboot, storage, quorum loss) before failing back.
