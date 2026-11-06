# Block 3 demo — the prompt makeover

Two variants of the **same** demo (slide 5.9 in the Portland order): evolve one prompt from naive to
production-quality T-SQL on the Wake County schema, opening with a 2-minute
"spot the hallucination" hook. Pick by connectivity — the **task, the prompts, and
the lessons are identical**; only execution differs.

| Variant | File | Use when |
|---------|------|----------|
| **Online** | [`claude-code-online.md`](claude-code-online.md) | Internet is solid — drive **Claude Code in VS Code** live (optionally run each query against the container to show it fail, then pass). |
| **Offline** | [`prompt-makeover-offline.md`](prompt-makeover-offline.md) | No/variable internet, or a recorded talk — pre-captured outputs, just narrate. |

Shared context: [`schema.sql`](schema.sql) — the structure-only schema you hand the
model at step **v2**. It intentionally omits the `Severity` values and the
definition of "critical"; those are revealed at **v3**, so the makeover can show
the model guessing a plausible-but-wrong value when under-informed.

## The four-step arc (each step adds one layer of context)
1. **v1** — no context → hallucinated tables/columns, non-T-SQL. *(the hook)*
2. **v2** — role + structure → right tables, but guesses `Severity = 'Critical'` → **0 rows**.
3. **v3** — domain values + window + "most recent score" → correct filters, but a
   naive join **fans out** and inflates counts (e.g., 5 → 165).
4. **v4** — correctness constraints + house style → production-quality, verified correct.

## Prereqs
- **Online:** VS Code + Claude Code (signed in) + internet; this repo open.
- **Either, optional but great:** the SQL Server container running (see
  [`../../infra/docker/`](../../infra/docker/)) + the **mssql** VS Code extension or
  `sqlcmd`, to run each query live and show 0-rows → inflation → correct.
- **Not used here:** the laptop's `llama3.2:1b` — too weak for trustworthy T-SQL.
  (That model is for the Block 1 temperature demo.)

## Develop-once note
The online flow was designed first; the offline outputs were derived from it. The
v2–v4 SQL is real and its behavior (0 rows / fan-out / correct) is **verified
against the `WakeCountyFood` database**. If you re-capture wording from your own
model run, keep the prompts and the lessons in sync across both files.
