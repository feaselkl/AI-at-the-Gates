# Demo: GenAI triages a real performance problem

Slide 5.18 in the Portland order, right before the SSMS Agent mode demo. We hand a deliberately slow query to
**Claude Code in VS Code**, let it pull the waits and the execution plan, watch it
diagnose the root cause, apply a fix, and **validate the before/after**. This models
the disciplined "treat the AI as a thinking partner, not an oracle" behavior we
preach.

## Files

| File | Role |
|------|------|
| `10_slow_query.sql` | **The patient.** A realistic, ~200x-too-slow query. |
| `20_capture_diagnostics.sql` | **The evidence.** Per-session wait stats + the actual plan. Run it yourself, or let Claude Code run it. |
| `30_fixed_query.sql` | **The reveal.** The tuned query (same 6,256-row result), plus the optional missing-index discussion. |

## Prerequisites

- The SQL container is up (see [`../../../infra/README.md`](../../../infra/README.md)).
  Connect at `localhost,1433`, `sa` / `WakeCounty!2025`, database `WakeCountyFood`.
- This repo open in **VS Code** with **Claude Code** (the panel or the CLI in the
  integrated terminal).
- *(Nice to have)* the **SQL Server (mssql)** VS Code extension, so you can run the
  queries and view the graphical plan in the same window you're driving Claude from.

---

## The arc (what the room sees)

1. **Show the pain.** Run `10_slow_query.sql`. It spins for the better part of a
   minute (~58s of CPU on the build box). Read the business question aloud so the
   slowness feels real, not academic.
2. **Hand it to Claude.** Type the triage prompt (below) into Claude Code.
3. **Watch it work the two passes** — waits first, then the plan — and name the
   root cause.
4. **Apply + validate.** Claude rewrites the query and re-runs it: ~58,000 ms →
   ~290 ms CPU, **identical result set**. Show the diff is empty.
5. **Land the guardrail.** It proposed an index too, but we should validate it first.

---

## How Claude Code triages it: two possible workflows

### Workflow A (recommended): let Claude drive the database

Claude Code has a **Bash** tool, so it can run the diagnostics itself against the
container. This is the demo that lands — the AI doesn't just *advise*, it *operates*.

The one thing it needs to know is how to reach SQL. Paste this connection helper
into the prompt (or keep it in `CLAUDE.md` so it's always in context):

```bash
docker exec wakecounty-sql2025 /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'WakeCounty!2025' -C -d WakeCountyFood -Q "<T-SQL here>"
```

**Prompt 1 — diagnose:**

> The query in `src/demo/block4/perf-triage/10_slow_query.sql` is slow. Connect to
> the WakeCountyFood SQL Server container with sqlcmd (helper command in
> `20_capture_diagnostics.sql`) and triage it like a DBA: first capture this
> query's **wait statistics** from `sys.dm_exec_session_wait_stats`, then capture
> its **actual execution plan** (`SET STATISTICS XML ON`) and `STATISTICS IO/TIME`.
> Tell me, in order: what the server is waiting *on*, what the plan is *doing*, and
> the single root cause. Don't change anything yet.

What it should find and say back (your script in `20_capture_diagnostics.sql`
produces exactly this evidence):

- **Waits:** `PAGELATCH_EX` dominates, then `CXSYNC_PORT` / `CXSYNC_CONSUMER`, then
  `SOS_SCHEDULER_YIELD` — i.e. **tempdb worktable contention under a parallel plan
  plus CPU churn**, with *no* `PAGEIOLATCH` (so it is **not** an I/O problem) and no
  other session to block it (so the contention is **self-inflicted**).
- **Plan:** index **Scans** (not Seeks) on both tables, two **Index Spool**
  operators, `DegreeOfParallelism = 8`. `STATISTICS IO` shows only ~362 logical
  reads on `FoodInspection` despite ~58s of CPU — the classic *"cheap reads,
  expensive query"* tell that the cost is computation/latching, not data volume.
- **Root cause:** three **non-SARGable** predicates — `YEAR(InspectDate)`,
  `LIKE '%Priority%'`, and `LTRIM(fi.HSISID)` inside the correlated subquery. The
  last one defeats `IX_FoodInspection_HSISID`, forcing the spool-and-rewind that
  the parallel threads then fight over.

**Prompt 2 — fix and prove it:**

> Good. Now propose the minimal rewrite that keeps the result set identical, apply
> it to a new file `30_fixed_query_live.sql`, and run both versions to show the
> before/after CPU time. Prove the results match (an `EXCEPT` both directions
> should return zero rows). Use **CPU time**, not elapsed, for the comparison and
> explain why.

It should converge on the three fixes in `30_fixed_query.sql`: date **range**
instead of `YEAR()`, `IN (...)` instead of `LIKE`, and an **`OUTER APPLY`** with a
clean `HSISID` predicate so the subquery seeks the covering index. Expected
payoff: **~58,000 ms → ~290 ms CPU**, same 6,256 rows.


### Workflow B (the guardrail-friendly fallback): Claude never touches the DB

Use this when the room's policy is *"the AI tool does not connect to the database"*,
such as a scenario with regulated/PII data.

1. **You** capture the evidence in SSMS / the mssql extension: run the query with
   the actual plan on, **Save Execution Plan As…** → `slow.sqlplan`, and copy the
   `sys.dm_exec_session_wait_stats` output and `STATISTICS IO/TIME` into a text
   file in the repo.
2. Ask Claude Code to **read those local files** and diagnose. This means no live connection:

   > Read `slow.sqlplan` and `waits.txt`. Diagnose the bottleneck and propose a
   > tuning strategy. You don't have database access — reason from the plan and
   > the wait stats only.

3. **You** apply and validate the suggestion in SSMS.

A `.sqlplan` is XML. It contains your **schema, query text, and row-count
estimates**, but **no row data**. That's usually shareable when raw data isn't.
That said, Workflow B still sends the plan and schema to the model. For regulated
data, scrub identifiers from the plan or keep to an in-tenant tool.

Treat every suggestion as a **conjecture to validate against your workload**, never a verdict.

---

## Talking points to hit

- **Waits before plan.** Waits tell you *which kind* of problem you have (I/O vs
  CPU vs locking vs intra-query parallel contention) before you ever read
  an operator. The AI does both passes in seconds; the *discipline* is yours to model.
- **"Cheap reads, expensive query."** 362 logical reads and 58 seconds of CPU in
  the same query is the signature of work hidden in spools/computation, not data
  volume. It's the kind of thing that is easy to miss by eye and a great use of an
  AI second pair of eyes.
- **The fix is boring on purpose.** The solution involves SARGable predicates and an
  `OUTER APPLY` statement. We're not using new features or magic here. Vector workloads
  may be new, but tuning them involves the same craft DBAs already know.
- **Validate the index suggestion.** The missing-index hint is a *starting
  point*. The rewrite alone already wins; adding `IX_FIV_InspectDate_Severity` buys
  a little more but costs writes and storage on a 310k-row table. Decide with
  numbers, not with the AI's confidence. *(And remember: once a DiskANN vector
  index makes that table read-only, you can't add this index after the fact — order
  matters.)*

## Reset between runs

Nothing to clean up — the demo only reads. If you created the optional index while
exploring, drop it:

```sql
DROP INDEX IF EXISTS IX_FIV_InspectDate_Severity ON dbo.FoodInspectionViolation;
```
