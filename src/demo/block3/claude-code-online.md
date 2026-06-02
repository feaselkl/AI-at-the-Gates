# Block 3 demo — prompt makeover, ONLINE (Claude Code in VS Code)

Run this when you have solid internet. You drive **Claude Code in VS Code** live,
evolving one prompt from naive (v1) to production-quality (v4) on the Wake County
schema. The **offline** variant ([`prompt-makeover-offline.md`](prompt-makeover-offline.md))
uses the *same task and same prompts* with pre-captured outputs — use it if the
room's connectivity is shaky.

> Design idea: each prompt adds **one layer of context**, and the bug at each step
> is exactly what that layer prevents. That's the whole lesson — the model is only
> as good as what you tell it, and you still verify.

## Prereqs
- VS Code with the **Claude Code** extension, signed in, internet available.
- This repo open in VS Code (so Claude Code can read `schema.sql`).
- *Optional but powerful:* the SQL Server container running (see
  [`../../infra/docker/`](../../infra/docker/)) plus the **mssql** VS Code
  extension or `sqlcmd`, so you can **run each generated query live** and let the
  room watch it fail and then succeed.
- Connect: `localhost,1433`, `sa` / `WakeCounty!2025`, database `WakeCountyFood`.

## The task (one sentence, kept fixed the whole way)
> "Find the restaurants with the most **critical** violations in the last 12
> months, with the count and their most recent inspection score, worst first."

---

## v1 — no context (the hook: "spot the hallucination")
Paste into Claude Code:

> *Without reading any files in this repo, write a SQL query to find the
> restaurants with the most health-code violations.*

**What to expect / narrate:** with nothing to go on, it invents a schema —
table names like `restaurants` / `violations`, columns like `restaurant_id`,
and often `LIMIT 10` (not T-SQL). Ask the room to **spot the invented names**.
Lesson: confident, fluent, and wrong — because it had zero context.

> A strong model may hedge ("assuming a schema like…"). That hedge *is* the point:
> it's guessing. If you ran it against the database, it wouldn't even parse.

## v2 — add role + structure
> *You are a senior SQL Server 2025 (T-SQL) DBA. Use the schema in
> `src/demo/block3/schema.sql`. Rewrite the query: the restaurants with the most
> **critical** violations, with the count, worst first.*

**What to expect / narrate:** now it uses the real tables/columns and T-SQL. But
it has to **guess what "critical" means** — almost always `Severity = 'Critical'`.
**Run it live → 0 rows.** The real values are `Core` / `Priority` /
`Priority Foundation`. Lesson: structure isn't enough; the model can't know your
data's *vocabulary*.

## v3 — add domain knowledge + task precision
> *In this data, `Severity` is one of `'Core'`, `'Priority'`,
> `'Priority Foundation'` (or NULL); treat `'Priority'` and `'Priority Foundation'`
> as critical. Restrict to violations in the 12 months ending a reference date
> `@AsOf = '2026-03-31'`. Also include each restaurant's most recent inspection
> score as of that date. Top 20, worst first.*

**What to expect / narrate:** severity and the window are right now, but it
commonly grabs the score with a plain `JOIN dbo.FoodInspection` — which **fans out**
(one row per inspection), inflating the counts. **Run it live →** a restaurant
shows a wildly inflated count (e.g., 5 real violations × 33 inspections = 165) and
duplicate rows. Lesson: correct filters, classic join-fan-out bug.

## v4 — add correctness constraints + output format (house style)
> *Constraints: set-based and SARGable (don't wrap `InspectDate` in a function);
> avoid the fan-out — count critical violations in a derived table, and get the
> most recent score with `OUTER APPLY ... TOP (1)`. `INNER JOIN` to `Restaurant`
> (named restaurants only). Output a single T-SQL code block in our house style:
> a header comment block describing the query, UPPERCASE keywords, schema-qualified
> names, 4-space indentation. Match this example's style:*
>
> ```sql
> /* -----------------------------------------------------------------------------
>    <one-line purpose>
>    <assumptions / notes>
>    ----------------------------------------------------------------------------- */
> DECLARE @AsOf date = '2026-03-31';
> SELECT TOP (10)
>     t.ColumnA AS FriendlyName,
>     t.ColumnB
> FROM dbo.SomeTable AS t
> WHERE t.SomeDate >= DATEADD(MONTH, -12, @AsOf)
> ORDER BY t.ColumnA;
> ```

**What to expect / narrate:** production-quality T-SQL — correct counts, most
recent score via `OUTER APPLY` (NULL when there's no qualifying inspection),
parameterized `@AsOf` for a reproducible window, and your house format. **Run it
live →** a clean top 20 (e.g., HIBACHI CHINA BUFFET, Cary — 10). The reference
v4 query and its verified result are in
[`prompt-makeover-offline.md`](prompt-makeover-offline.md).

---

## Closing beats
- Same model the whole time — the **prompt** carried the improvement.
- You supplied what the model *couldn't* know: your **vocabulary** (severity
  values), your **intent** (window, "most recent"), your **correctness bar**
  (no fan-out, SARGable), and your **house style**.
- You **ran every version** and verified — you're still the DBA.

## If the live model "compresses" the arc
A strong model given good context may skip straight to a near-correct answer at v2
or v3. That's not a failure — call it out: *better models need less hand-holding,
but they still can't know your data's vocabulary, your environment, or your house
style, and you still verify.* If you need the guaranteed four-step arc (e.g., a
recorded talk), run the **offline** version instead.

## Reset between runs
Start each version in a fresh Claude Code conversation (or tell it to ignore prior
turns) so earlier context doesn't leak into the "naive" v1.
