# Block 3 — Prompt Engineering for Data Professionals (3.1–3.2)

**Slide-deck outline (build notes, not finished slides).**
Part of *AI at the Gates: The DBA's Guide to Surviving in an LLM World*.

- **Duration:** 30 min (11:30 – 12:00) — the **shortest** block. Keep it tight and
  practical; this is a "use it Monday" skills section, not a deep dive.
- **Audience:** Database professionals — DBAs, data engineers, database
  developers. By now (after Blocks 1–2) they have the mental model and know the
  tooling/governance rules.
- **Goal:** Develop practical prompting skills tailored to database administration
  and development tasks.
- **Platform note:** Unlike Block 1, SQL Server / T-SQL is fair game here (3.2 is
  explicitly about it). But the *techniques* are model-agnostic, so most slides
  are `[Concept]`. Examples use the running **Wake County** schema
  (`FoodInspection` / `FoodInspectionViolation`) for continuity.
- **Callbacks:** Block 1 (hallucination — why context matters), Block 2
  (governance — don't paste secrets), and forward to Blocks 4–5 (where these
  prompts get used inside SSMS Copilot / MCP / pair programming).

---

## How to read this outline

Per slide: **talking points**, an **image idea**, and demo callouts (`▶ DEMO`).
Tagging is light (technique is platform-neutral); `[→ Block N]` marks cross-references.

---

## Section 0 — Opener (1 slide, ~1 min)

### Slide 0.1 — The prompt is the steering wheel
- You *will* use AI to help write and reason about SQL — the quality of what you
  get back is mostly determined by the prompt, not the model.
- 30 minutes, entirely practical: a repeatable recipe + how to apply it to DB work.
- **Image idea:** A steering wheel labeled "prompt" turning a vague question into a
  precise query.

---

## Section 3.1 — Prompt Engineering Fundamentals (6 slides, ~13 min)

### Slide 3.1.1 — Why generic prompting advice falls short for DB work
- "Be specific / act as an expert" doesn't address what database work demands:
  the **exact schema**, the **dialect** (T-SQL vs ANSI), **correctness you can
  verify**, **performance**, and **your shop's conventions**.
- DB work is unforgiving: a hallucinated column or a wrong `JOIN` is a *bug*, not a
  style nit. The bar is higher than "write me a poem."
- **Image idea:** Generic "10 ChatGPT tips" sticky notes on one side; a precise
  schema diagram + query on the other.

### Slide 3.1.2 — The anatomy of an effective prompt (the recipe)
- Five parts, in order:
  1. **Role** — who the model should act as ("a senior SQL Server DBA").
  2. **Context** — schema/DDL, sample rows, environment, constraints it must know.
  3. **Task** — the precise thing you want done.
  4. **Constraints** — dialect, performance goals, what to avoid (no cursors, etc.).
  5. **Output format** — just T-SQL? with inline comments? an explanation too?
- This is the **reusable recipe** for the rest of the block (and a handout).
- **Image idea:** One prompt with the five sections color-coded and labeled — the
  "recipe card." Likely a screenshot-and-keep slide.

### Slide 3.1.3 — Context is king (and why)
- The model **cannot see your database.** Most bad SQL comes from missing context,
  not a weak model.
- Feed it: relevant **DDL**, key **relationships**, a few **sample rows**, and
  rough **cardinality** ("~310k violation rows").
- Direct callback: without the schema, it confidently invents plausible-but-wrong
  column names — the hallucination you saw in Block 1. `[→ Block 1]`
- **Image idea:** Left: model guessing column names with "?" tags. Right: same
  model handed a `CREATE TABLE` and getting them right.

### Slide 3.1.4 — Zero-shot vs few-shot
- **Zero-shot:** just ask. Fine for common, well-trodden patterns.
- **Few-shot:** include 1–3 examples of input→output in *your* style (naming,
  formatting, header comments). Use it to enforce house conventions or an unusual
  pattern the model wouldn't guess.
- Rule of thumb: reach for few-shot when you keep correcting the same thing.
- **Image idea:** An empty prompt (zero-shot) vs a prompt with two small
  "example" cards attached (few-shot).

### Slide 3.1.5 — Chain-of-thought for complex query logic
- For multi-step logic (multi-join, window functions, gaps-and-islands, dedup),
  ask it to **outline the approach first, then write the SQL**.
- Why it helps: forces the model to reason before committing to syntax, catching
  logic errors early.
- Tradeoff: more tokens/time — overkill for a simple `SELECT`.
- **Image idea:** A short numbered "plan" leading into a query block.

### Slide 3.1.6 — Prompting is a loop, not a one-shot
- Draft → **run & verify** → refine. The model gives you a starting point; **you're
  still the DBA** who owns correctness and performance.
- Ties the room back to governance: verify before you trust. `[→ Block 2]`
- **Image idea:** A cycle diagram: prompt → output → verify → refine → (repeat).

---

## Section 3.2 — Prompting for SQL Server Work (6 slides + demo, ~15 min)

### Slide 3.2.1 — Giving the model your schema effectively
- Paste the relevant **DDL** (CREATE TABLE + keys/indexes), a few **sample rows**,
  and note **relationships** and **row counts**.
- Big schema? Include only the relevant tables; summarize the rest. Don't dump
  3,000 columns.
- Example on screen: the `FoodInspection` / `FoodInspectionViolation` DDL and the
  `HSISID` relationship.
- **Image idea:** A `CREATE TABLE` snippet + 3 sample rows flowing into the model.

### Slide 3.2.2 — Generation, optimization, refactoring
- **Generation:** role + schema + precise task + output format.
- **Optimization:** paste the query *and* the execution plan / wait stats, ask for
  improvements **with the reasoning**.
- **Refactoring:** "rewrite this cursor as set-based," "modernize to window
  functions," "make this SARGable."
- **Image idea:** Three labeled arrows — generate / optimize / refactor — off one
  query block.

### Slide 3.2.3 — Troubleshooting & execution plan analysis
- Paste the **error text** or the **plan** (XML or screenshot) plus context; ask for
  likely cause + fix.
- Honest caveat: the model can't see your data distribution or stats — treat its
  answers as **hypotheses to test**, not verdicts.
- This previews the AI-assisted tuning demo in Block 4. `[→ Block 4]`
- **Image idea:** An error message / plan → a "likely cause + fix" bubble with a
  small "verify" stamp.

### Slide 3.2.4 — Administrative-task prompts (with guardrails)
- Useful for: backup-strategy drafting, index recommendations, capacity-planning
  math, writing runbooks.
- **Guardrails (loud):** never paste secrets, connection strings, or PII; validate
  every suggestion against *your* SLAs/edition/environment; the model doesn't know
  why that "redundant" index exists. `[→ Block 2]`
- **Image idea:** An admin checklist with caution tape across the "paste secrets"
  row.

### Slide 3.2.5 — ▶ DEMO / interactive: the prompt makeover
- **Open with a hook (~2 min) — "spot the hallucination":** show a confident,
  wrong query (an invented column or a bad join) generated with *no* schema given;
  let the room find the bug; then reveal that supplying schema context fixes it.
  Motivates *why* the recipe matters before you teach it.
- **Main segment — the prompt makeover (pre-captured):** one realistic Wake County
  task; the prompt evolves v1 → v4 (naive → full anatomy) and the output improves
  to production-quality T-SQL. Outputs are **pre-captured** from a capable model so
  the segment is reliable; narrate the "why" at each step. (More talk-through than
  show-and-tell — which fits a 30-min slot.)
- **Reality check:** use a capable model — the laptop's `llama3.2:1b` is for Block
  1's temperature demo, **not** for production T-SQL.
- Ship the **recipe card** (appendix) as a takeaway handout; a ready-to-use
  makeover script is in the appendix.
- **Image idea:** v1 and v4 prompts side by side, with their outputs; the diff in
  output quality is the punchline.

---

## Section wrap (1 slide, ~1 min)

### Slide 3.W — Takeaways
- Remember the recipe: **Role · Context · Task · Constraints · Output format** —
  and **verify everything**.
- Context is the highest-leverage ingredient; few-shot enforces your style;
  chain-of-thought rescues complex logic.
- Next: Blocks 4–5 put these prompts to work *inside the tools* (Copilot in SSMS,
  MCP, pair programming). `[→ Block 4]` `[→ Block 5]`
- **Image idea:** The recipe card, with a bridge to "the tools" (Block 4–5).

---

## Appendix — Presenter notes (not slides)

### The reusable "DB prompt recipe card" (handout / takeaway slide)
```
ROLE:        You are a senior SQL Server 2025 (T-SQL) DBA.
CONTEXT:     <paste relevant CREATE TABLE DDL, keys/indexes, a few sample rows,
             row counts, and table relationships>
TASK:        <the precise thing you want — one clear ask>
CONSTRAINTS: T-SQL for SQL Server 2025; set-based (no cursors); SARGable;
             explain any assumption you make.
OUTPUT:      Return only the T-SQL in one code block, with brief inline comments.
```

### The prompt-makeover demo (built — two variants in `src/demo/block3/`)
Task (fixed throughout): *"Find the restaurants with the most **critical**
violations in the last 12 months, with the count and their most recent inspection
score, worst first."* (Wake County data.)

Each prompt adds **one layer of context**, and the bug at each step is exactly what
that layer prevents — all behaviors **verified against the `WakeCountyFood` database**:
- **v1 (no context):** invents tables/columns, non-T-SQL → the "spot the hallucination" hook.
- **v2 (+ role + structure, [`schema.sql`]):** right tables, but guesses
  `Severity = 'Critical'` → **0 rows** (real values: `Core`/`Priority`/`Priority Foundation`).
- **v3 (+ domain values + window + "most recent score"):** correct filters, but a
  naive `JOIN dbo.FoodInspection` **fans out** and inflates counts (5 → 165).
- **v4 (+ correctness constraints + house style):** derived-table count +
  `OUTER APPLY TOP (1)` for the score → production-quality, correct.
- Punchline: same model throughout — the **prompt** carried the improvement.

Two ready variants (same prompts/lessons; pick by connectivity):
- **Online:** [`src/demo/block3/claude-code-online.md`](../src/demo/block3/claude-code-online.md)
  — drive Claude Code in VS Code live; optionally run each query against the
  container to show 0-rows → inflation → correct.
- **Offline:** [`src/demo/block3/prompt-makeover-offline.md`](../src/demo/block3/prompt-makeover-offline.md)
  — pre-captured outputs, no internet.

### Demo logistics
- Default to the **offline** variant for a guaranteed arc; use **online** when
  connectivity is solid (a strong model may compress the arc — that's its own talking point).
- Do **not** rely on the local `llama3.2:1b` for this — it isn't strong enough for
  trustworthy T-SQL. (It's great for the Block 1 temperature contrast, not this.)
