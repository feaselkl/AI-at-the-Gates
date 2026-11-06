# Demo: an agent in SSMS, on your terms

GitHub Copilot Agent mode in SSMS doesn't just suggest T-SQL; it runs it. This demo
shows what it does when it runs as you, then gives it its own low-privilege identity
and a set of house rules, both stored in the database, and shows the difference.

It pairs with [`../perf-triage/`](../perf-triage/), where Claude Code fixes a slow query
while connected as `sa`. That demo shows what an agent can do; this one shows how you
limit what it's allowed to do.

Two ways to present it, depending on time:

| Version | Time | What you need |
|---|---|---|
| Live | about 8 minutes | SSMS on the Azure VM, connected to a copy of WakeCountyFood |
| Screenshots | about 2 minutes | The shots listed below, captured in rehearsal |

## Files

| File | Role |
|---|---|
| `10_constitution.sql` | Creates `CopilotReader` (SELECT on the three tables, denied the inspector-name columns) and the database's `CONSTITUTION.md` extended property, which makes Copilot run as `CopilotReader` and carries the house rules. |
| `20_prove_it.sql` | Runs the same checks by hand with `EXECUTE AS USER = 'CopilotReader'`: allowed query, denied column (Msg 230), denied DDL. Use in rehearsal, or live if Copilot misbehaves. |
| `90_reset.sql` | Removes the constitution and the user. Run it before the demo so beat 1 starts clean, and after. |

All three were tested on 2026-11-01 against the SQL Server 2025 container (as `sa`):
setup, the checks, a second setup run, and reset all behave. **Copilot itself was not
tested.** That needs SSMS on Windows; see "Verify in rehearsal" below.

## Prerequisites

- SSMS 22.10.2 or later (Agent mode is GA there; it arrived in preview in 22.7), with the
  AI Assistance workload, signed in to a GitHub account with Copilot.
- WakeCountyFood on a SQL Server that SSMS on the VM can reach. The simplest route is a
  backup from the container, restored on the VM's SQL Server 2025 instance. The database
  is about 1.5 GB allocated. No embedding endpoint is needed for this demo.

  ```bash
  docker exec wakecounty-sql2025 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa \
    -P 'WakeCounty!2025' -C -Q "BACKUP DATABASE WakeCountyFood TO DISK = '/var/opt/mssql/data/WakeCountyFood.bak' WITH COMPRESSION, INIT"
  docker cp wakecounty-sql2025:/var/opt/mssql/data/WakeCountyFood.bak .
  ```
- Connect in SSMS as a sysadmin (as the container's `sa` does). A sysadmin already has
  IMPERSONATE on `CopilotReader`. Any other login needs the GRANT at the bottom of
  `10_constitution.sql`, or Copilot refuses to run queries in this database.

## The arc (what the room sees)

Before you start: run `90_reset.sql`, open **View > GitHub Copilot Chat**, and pick
**Agent** from the mode dropdown. Agent mode doesn't take its connection from the
active query window, so every prompt names the database and server.

### Beat 1: as you (about 3 minutes)

> In the WakeCountyFood database on `<server>`, which Raleigh restaurants had the most
> critical violations in 2025?

Point at:
- **The approval prompt** before each query (Allow once / for this session / always).
  Microsoft's docs are explicit that this prompt is not a security boundary. It confirms
  your intent; it doesn't limit anything.
- **What it does with "critical".** There is no `'Critical'` value. If it looks at the
  distinct `Severity` values first, that's the difference between an agent and the chat
  window from the prompt makeover. If it guesses `'Critical'` and gets 0 rows, that's the
  makeover's v2 mistake all over again. Either one goes on the ledger.

> Create an index that would make that query faster.

Point at: Agent mode is `READ_ONLY` by default, so it shouldn't run the `CREATE INDEX`
even though you're `sa`. Then say the uncomfortable part: everything else it ran, it ran
as `sa`.

### Beat 2: give it its own identity and rules (about 1 minute)

Run `10_constitution.sql` and show the result. Walk through it:
- The front matter line `agentExecuteAsUser: CopilotReader`. SSMS now wraps every
  Copilot query in `EXECUTE AS` that user.
- The body: the same facts the prompt makeover had to type by hand (what "critical"
  means, join on HSISID, count before joining). Now they live in the database and apply
  to every Copilot user, every time.
- The column-level DENY on inspector names. The rule in the text asks nicely; the DENY
  is what actually stops it.

### Beat 3: as CopilotReader (about 3 minutes)

Start a **new** chat (Copilot reads the constitution when a session opens).

> In the WakeCountyFood database on `<server>`, which Raleigh restaurants had the most
> critical violations in 2025?

Point at: `Severity IN ('Priority', 'Priority Foundation')`, with nobody typing it.
The answer should match `20_prove_it.sql` (TACOS MI TIERRA CALIENTE, 9).

> Which inspectors gave the lowest average scores in 2025?

Point at: Msg 230, SELECT permission denied on column `Inspector`. Watch whether it tries
another route (`InspectedBy` is denied too) or stops, as the constitution tells it to.

> Run SELECT USER_NAME(), ORIGINAL_LOGIN() and tell me who you're running as.

Point at: `CopilotReader`, signed in as you. That's the line that answers "but it ran as sa".

Finish with `90_reset.sql`.

## Screenshots to capture in rehearsal

For the 2-minute version. Save them as PNGs in `slides/screenshots/ssms-agent/` and send them
to Jonathan with the deck. Before you send them, check each one for a GitHub account name,
an email address, a server name, or anything else you wouldn't put on a public slide.

| File | Shows |
|---|---|
| `01-agent-mode.png` | The chat window with Agent selected in the mode dropdown |
| `02-approval.png` | The approval prompt on its first query, Allow dropdown open |
| `03-critical-as-you.png` | Beat 1: how it handled "critical" |
| `04-read-only-index.png` | Beat 1: the CREATE INDEX it proposed but didn't run |
| `05-constitution.png` | Beat 2: the output of `10_constitution.sql` |
| `06-critical-as-reader.png` | Beat 3: the query using Priority and Priority Foundation |
| `07-denied.png` | Beat 3: the inspector question hitting Msg 230 |
| `08-running-as.png` | Beat 3: CopilotReader / your login |

## Verify in rehearsal

These come from the docs, not from a run, so confirm them on the VM:

- How the UI shows a statement that `READ_ONLY` won't run (beat 1, second prompt).
- Whether Copilot reads table metadata as you or as `CopilotReader`. If it reads as
  `CopilotReader`, it may not see the inspector columns at all, and the beat 3 inspector
  prompt ends differently. Either outcome is fine on stage, but know which one you'll get.
- That the constitution is picked up in a new chat without restarting SSMS.

## Facts used (Microsoft Learn, checked 2026-11-01)

- Agent mode runs queries as the signed-in login unless `CONSTITUTION.md` names an
  `agentExecuteAsUser`; SSMS then uses EXECUTE AS, and the signed-in user needs IMPERSONATE
  on that user or Copilot won't run queries in that database.
- Agent mode is `READ_ONLY` by default; `READ_WRITE` is set in mcp.json.
- The approval prompt isn't a security boundary; SQL Server permissions are.
- Admins can disable Agent mode with the Visual Studio ADMX templates (Copilot Settings >
  Disable Agent Mode, SSMS 22.7+) and restrict MCP servers with an allow list in GitHub's
  Copilot policies.
- Pages: ssms/github-copilot/agent-mode, execution-context, database-instructions, admin-controls.
