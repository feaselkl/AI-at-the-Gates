# Block 5 — Database Development in a Generative AI World (5.1–5.3)

**Slide-deck outline (build notes, not finished slides).**
Part of *AI at the Gates: The DBA's Guide to Surviving in an LLM World*.

- **Duration:** Block 5 is 60 min (2:30 – 3:30). 5.1 Pair Programming (~25 min,
  opens, demo-heavy), 5.2 Leveraging MCP Servers (~20 min), 5.3 RAG over Internal
  Documentation (~15 min). After lunch + Kevin's DBA block, this re-energizes with
  hands-on dev.
- **Audience:** DBAs, data engineers, database developers — who, by mid-afternoon,
  have seen embeddings (Block 1), the governance rules (Block 2), prompting (Block 3),
  and SQL Server 2025 vector storage/search + in-DB AI functions (Block 4).
- **Goal:** Make the morning's prompting theory muscle memory (5.1), introduce MCP as
  the way to stop hand-feeding context (5.2), and assemble the day's pieces into RAG
  over your own docs (5.3).
- **Owners:** 5.1, 5.2 — Jonathan; 5.3 — Kevin. MCP is fully Jonathan's, end-to-end:
  *use* it here (5.2), *build* it in 6.2 — no handoff seam. RAG (5.3) is fully Kevin's.

---

## How to read this outline

Per slide: **talking points**, an **image idea**, and demo callouts (`▶ DEMO`).
Tags: `[Concept]` for platform-neutral ideas; `[SS2025 GA]` / `[SS2025 Preview]` for
SQL Server 2025 features (consistent with Block 4); `[Non-MS]` for third-party tools;
`[→ Block N]` for callbacks. A presenter **prep & fact-check** is in the appendix.

---

## Section 5.0 — Block opener (1 slide, ~1 min)

### Slide 5.0 — From admin to development
- Block 4 was the DBA's day (vectors, ops); Block 5 is the developer's: pair
  programming, MCP, and RAG — AI as a force multiplier for building, not just running.
- Roadmap: pair-program with AI (5.1) → let it fetch its own context via MCP (5.2) →
  ground it in your docs with RAG (5.3).
- **Image idea:** A split: "run the database" (Block 4) → "build with the database" (Block 5).

---

## Section 5.1 — Pair Programming with Generative AI `[JS]` (7 slides + demo, ~25 min, opens the block)

### Slide 5.1.1 — You drive, it types, you review every line (hook)
- "Pair programming with AI isn't 'press tab, accept the magic.' It's a sharp junior
  who types 100× faster, has read every doc, and never shipped to *your* production.
  You drive. It types. You review every line like a PR — because it is."
- **Image idea:** Two seats at one keyboard — a human "driver" and an AI "typist."

### Slide 5.1.2 — The real loop (specify → draft → review → correct)
- **You specify (3.1's R-C-T-C-O) → it drafts → you review → you correct → repeat.**
  A conversation with a fast, literal partner — not dictation, not autopilot. `[→ 3.1]`
- Two modes: **autocomplete** (Copilot-style inline) for the obvious next line,
  boilerplate, repetition — low stakes, high frequency; **conversational/agentic**
  (chat or CLI agent) for "write this proc," "refactor this," "why is this slow" —
  higher stakes, more review.
- Mindset shift: your job moves from *typing* to *specifying and reviewing* — a
  promotion, but only if you actually do the reviewing.
- **Image idea:** A cycle: specify → draft → review → correct, with two side-tags
  (autocomplete / agentic).

### Slide 5.1.3 — T-SQL generation: where it earns its keep
- Strong fits: stored procedures and boilerplate, CRUD, views, parameterized queries,
  format/lookup tables, turning a clear requirement into a first draft.
- The trick is feeding it the **schema context** (3.1) — without it, it invents column
  names; with it, the first draft is often 80% there. `[→ 3.1]`
- Reality check: "80% there" means *you* own the 20% that's wrong — and the 20% is
  where the production incident lives.
- **Image idea:** A requirement → an 80%-complete proc with a highlighted "your 20%."

### Slide 5.1.4 — Code review & refactoring (the underrated win)
- Often *more* valuable than generation — the correctness bar is lower (you're
  improving working code, not trusting net-new):
  - "Review this proc for perf anti-patterns" (RBAR, non-SARGable predicates,
    implicit conversions, missing `SET NOCOUNT`).
  - "Refactor this cursor to set-based." (Kevin's 4.x owns the perf angle; here it's
    the *dev* workflow.) `[→ Block 4]`
  - "Explain what this 200-line proc I inherited actually does" — the
    legacy-archaeology use case that alone justifies the tool to most DBAs.
- Pattern: paste working code, ask for *specific* classes of issue, treat findings as
  a second set of eyes — not gospel.
- **Image idea:** A proc with AI margin-comments flagging specific anti-patterns.

### Slide 5.1.5 — Unit test generation for database objects
- Underused, high-value: "Generate tSQLt tests for this proc covering empty input,
  nulls, duplicate keys, and the happy path."
- It's good at *enumerating edge cases you'd forget* — even if you don't use its exact
  test code, the case list is the value.
- **Image idea:** A proc → a checklist of generated edge-case tests.

### Slide 5.1.6 — When AI gets it wrong (the trust slide — do NOT skip)
- The section's spine — a DBA audience trusts you *more* when you lead with failure modes:
  - **Hallucinated objects** — invented DMVs, functions, columns, hints. `[→ 2.3]`
  - **Plausible-but-wrong logic** — wrong join grain → duplicate rows; off-by-one date
    boundaries; `NOT IN` with NULLs.
  - **Outdated/version-mismatched syntax** — a feature your version lacks, or a
    deprecated pattern.
  - **Confidently wrong perf advice** — an index that already exists, or one that helps
    the demo and hurts the workload.
  - **The dangerous one: it never says "I don't know."** It always produces *something*.
- Catch it: read the plan, run against real(istic) data, check row counts at every
  grain — you don't accept a junior's PR on faith; don't accept the AI's either. `[→ 2.1]`
- > Closing line: "The people who get burned aren't the ones who don't trust it —
  they're the ones who trust it *too much, too early*. Trust is earned per task."
- **Image idea:** Five labeled failure-mode cards, the fifth ("never says I don't know")
  highlighted.

### Slide 5.1.7 — ▶ DEMO: requirements → stored procedure (+ transition)
- Live pair-programming (~6–8 min): start from a plain-English requirement against a
  known demo schema. Show the full loop — under-specified prompt → mediocre draft →
  add R-C-T-C-O context → better draft → spot a **real bug** (grain/duplicate) →
  correct → verify row counts.
- Deliberately surface at least one *wrong* answer and fix it live — the failure-mode
  point lands 10× harder shown than told.
- **Backup:** pre-recorded capture of the full loop + the final correct proc saved.
  Reuse the demo schema across 2.3 / 5.1 / 6.2 for continuity.
- Transition: "You saw how much better it gets when it can see your schema. What if it
  could *always* see it, automatically? That's MCP." → 5.2.
- **Image idea:** Before/after procs with the corrected grain bug circled.

---

## Section 5.2 — Leveraging MCP Servers for Contextual Development `[JS]` (6 slides + demo, ~20 min)

### Slide 5.2.1 — Go look it up yourself (hook)
- "Every good answer in the last section, you hand-fed the context — you pasted the
  schema, you told it the version. Chores don't get done. MCP is how the AI fetches
  that context *itself*." `[→ 5.1]`
- One-liner: "MCP turns 'here, let me paste my schema' into 'go look it up yourself.'"
- **Image idea:** A hand-pasting-schema icon crossed out; the AI reaching for the
  schema on its own.

### Slide 5.2.2 — What MCP is (the open standard)
- **Model Context Protocol** — an open standard giving AI assistants a consistent way
  to reach external tools and data. "USB-C for AI context": one plug, many devices. `[Concept]`
- Why a *standard* matters: before MCP every tool↔AI integration was bespoke; now any
  MCP-speaking client (Claude, Copilot, others) can use any MCP server — write once,
  use everywhere. (Lock-in callback to 2.4: open standards lower exit cost.) `[→ 2.4]`
- Payoff: the AI stops being a clever stranger and becomes a teammate with *your*
  docs, *your* schema, *your* query history at hand.
- **Image idea:** A USB-C hub labeled "MCP" with a client on one side, DB/docs/APIs on the other.

### Slide 5.2.3 — How it fits together (keep light — 6.2 goes deep)
- **Client** (Claude Desktop / Code, Copilot) ↔ **MCP server** ↔ your stuff
  (database, docs, APIs).
- A server exposes three things — name them now, they recur in 6.2:
  - **Tools** — actions the AI can take ("run this read-only query," "describe this table").
  - **Resources** — data/context the AI can read (docs, schema, runbooks).
  - **Prompts** — reusable prompt templates the server offers.
- "That's the *what*. In 6.2 we build one. Right now, let's *use* one." `[→ 6.2]`
- **Image idea:** Client ↔ server ↔ stuff, with Tools/Resources/Prompts on the server.

### Slide 5.2.4 — Microsoft Learn MCP — the safe, zero-setup win
- A first-party MCP server that puts official Microsoft/Azure/SQL docs in your AI
  workflow — search and fetch real docs instead of trusting the training cutoff.
- The perfect teaching example: **no data leaves, no credentials, no risk** — it reads
  public docs. Directly answers 5.1's "hallucinated/outdated syntax" failure mode by
  grounding the answer in current docs. `[→ 5.1]`
- Home turf — it's running in the workshop environment right now.
- **Image idea:** A version-specific question → the model fetching + citing a Learn doc.

### Slide 5.2.5 — Database MCP servers — the real power (and the real risk)
- Connect the AI to your *actual* database metadata: tables, columns, procs, indexes,
  query history. "Write me a proc" now uses real names, types, relationships — no pasting.
- The 5.1 schema-blind problem? Gone — the AI just *knows*. `[→ 5.1]`
- But (security thread from 2.1, hard): the moment a server touches your DB you must
  ask — read-only? which credentials? what's the blast radius? Name it; this is the
  cliffhanger for 6.2's guardrails. `[→ 2.1]` `[→ 6.2]`
- **Image idea:** An AI reading live schema, with a red "who holds the keys?" tag.

### Slide 5.2.6 — ▶ DEMO: Microsoft Learn MCP, live (+ config + transition)
- Ask a version-specific SQL Server question *without* MCP → it guesses or hedges
  (reuse a 5.1-style hallucination). Enable the Learn MCP server → ask again → it
  fetches and **cites** the real doc. "Same model, same question — it can now look it
  up. That's MCP." (~4–5 min; low risk — good to run live.)
- Config in brief: an MCP client has a config (e.g., `.mcp.json`) listing servers, how
  to launch them, and env/credentials — secrets passed in, **never hardcoded**. `[→ 2.1]`
- Transition (into Kevin's 5.3, then the break, then Block 6): "Context was the whole
  game in 3.1 and the chore in 5.1 — MCP makes the chore disappear. Hold onto the 'I
  could build one of these' feeling: in the last block, you will." `[→ 6.2]`
- **Backup:** pre-captured before/after screenshots; config snippet pre-shown.
- **Image idea:** Split before/after: hedge answer vs cited-doc answer, same prompt.

---

## Section 5.3 — RAG over Internal Documentation `[KF]` (8 slides + demo, ~15 min)

> Goal of 5.3: show that **RAG is just the day's pieces assembled** — and that SQL
> Server 2025 can be the whole retrieval backend for your team's docs. Format:
> discussion **plus a live demo** — RAG over internal DBA runbooks with **SQL Server
> 2025 as the vector store** and **Microsoft Foundry** supplying the embedding + chat
> models (no local GPU). Built two ways: a simple Python app and an entirely-in-T-SQL
> version. See [`src/demo/block5/`](../src/demo/block5/).

### Slide 5.3.0 — You've already built every piece
- RAG = **Retrieval-Augmented Generation**: fetch the right context from *your*
  documents at query time and hand it to the LLM.
- By now you've seen all the parts — embeddings (Block 1), vector storage/search in
  SQL Server 2025 (Block 4), in-DB chunking/embeddings (Block 4). 5.3 snaps them
  together. `[→ Block 1]` `[→ Block 4]`
- **Image idea:** Puzzle pieces labeled "embeddings / vectors / chunking / LLM"
  clicking into one "RAG" picture.

### Slide 5.3.1a — Retrieval-Augmented Generation, plainly
- The model doesn't *know* your runbooks. RAG **retrieves** relevant snippets and
  **stuffs them into the prompt**, so the answer is grounded in your content — with
  **citations** back to the source. `[Concept]`
- It's **not fine-tuning**: no retraining, no model weights to manage; you change the
  answer by changing the *documents*, not the model. Cheaper, current, auditable.
- **Image idea:** Question → retrieve top snippets from a doc store → prompt
  (question + snippets) → grounded answer with source links.

### Slide 5.3.1b — Why a DBA should care
- Grounds answers in **your** environment (your schema, your incident history),
  sharply reducing the confident-but-wrong hallucinations from Block 1. `[→ Block 1]`
- It's the pattern behind "chat with your docs," internal help bots, and
  schema/runbook Q&A — and you, the data platform owner, own the retrieval layer.
- **Image idea:** A generic LLM answer (vague/guessy) beside a RAG answer (specific,
  cites your runbook).

### Slide 5.3.2 — The DBA's gold mine (tribal knowledge)
- The best RAG corpus is the stuff already lying around: **runbooks, incident /
  post-mortem logs, schema docs, deployment notes, internal wikis, ticket history.**
- RAG turns "the thing only Bob knows" into searchable, always-available context —
  resilient to Bob being on vacation (or gone). `[Concept]`
- Discussion hook: *what would you point this at first?* Where does your team's tribal
  knowledge actually live?
- **Image idea:** A pile of sticky notes / wiki pages / PDFs funneling into a
  searchable index.

### Slide 5.3.3 — Chunking: why and how
- Two reasons to split docs into **chunks**: too big for the context window, and you
  want to retrieve only the **relevant slice**, not the whole manual. `[Concept]`
- Strategies: split by **section/heading**, or **fixed size with overlap** so context
  isn't cut mid-thought. Tradeoff: too big → noisy; too small → loses context. `[Concept]`
- In SQL Server 2025 you can chunk **in the database** with `AI_GENERATE_CHUNKS`
  (e.g., `CHUNK_TYPE = FIXED`, `CHUNK_SIZE = …`). `[SS2025 Preview]` `[→ Block 4]`
- **Image idea:** A long document sliced into overlapping passages, each becoming a vector.

### Slide 5.3.4a — The pipeline (architecture)
- **Index time:** ingest docs → **chunk** → **embed** each chunk → store chunk-text +
  vector. **Query time:** embed the question → **vector-search** the top-k closest
  chunks → build a prompt (question + chunks) → LLM answers with citations. `[Concept]`
- Every box maps to today: chunk/embed (Block 4 AI functions), store/search (Block 4
  `VECTOR` + DiskANN), embeddings intuition (Block 1).
- **Image idea:** Two-lane flow (index lane on top, query lane on bottom) sharing the
  same vector store in the middle.

### Slide 5.3.4b — Doing it *in* SQL Server 2025
- One table: `(chunk_text NVARCHAR(MAX), embedding VECTOR(n), source, …)`. Populate
  with `AI_GENERATE_CHUNKS` + `AI_GENERATE_EMBEDDINGS`; retrieve with `VECTOR_DISTANCE`
  (kNN) or `VECTOR_SEARCH` over a DiskANN index; hand chunks to an LLM (app-side or via
  external model). The **database is the retrieval layer.** `[SS2025 GA]` (type, kNN) /
  `[SS2025 Preview]` (index, search) `[→ Block 4]`
- Not the only option — Azure AI Search or a dedicated vector DB also work; use the
  Block 4 "in-database vs dedicated" decision framework. `[→ Block 4]`
- **Image idea:** A single SQL table icon labeled "chunks + vectors" at the center of
  the pipeline.

### Slide 5.3.5 — Gotchas that separate a toy from a tool
- **Chunk quality** drives everything — garbage chunks, garbage retrieval.
- **Keep embeddings fresh:** re-embed when the source doc changes (staleness). `[→ Block 4]`
- **Hybrid search:** combine vector + keyword so exact tokens (error numbers, object
  names, KB IDs) aren't missed; consider **re-ranking** the top-k. `[→ Block 4]`
- **Cite sources** (trust) and **respect access control** — don't surface a doc to
  someone who shouldn't see it. `[Concept]`
- **Evaluate retrieval** (is the right chunk in the top-k? — recall). `[Concept]`
- **Image idea:** A checklist card: freshness · hybrid · re-rank · cite · permissions · evaluate.

### Slide 5.3.6a — The demo, and why Foundry
- Corpus: ~6 realistic **internal DBA runbooks** (backup/restore, index maintenance,
  blocking/deadlocks, tempdb, an ETL-failure post-mortem, AG failover).
- **Models from Microsoft Foundry** (embeddings + chat) — no local GPU; and Foundry's
  publicly-trusted cert means SQL Server trusts it with **zero cert setup** (unlike the
  local-Ollama path). **Store = SQL Server 2025** (`VECTOR` + `VECTOR_DISTANCE`; no ANN
  index — the corpus is tiny). `[SS2025 GA]` / embed+chunk `[SS2025 Preview]`
- **Image idea:** The pipeline diagram with "Foundry" on the model boxes and "SQL
  Server 2025" on the store box.

### Slide 5.3.6b — ▶ DEMO: RAG over our runbooks (two ways)
- **Ask a question in your own words** → it retrieves the right runbook chunk and
  answers grounded, **with citations** — even when the question's words don't match the
  doc's. Marquee: *"The nightly load broke overnight and the log filled up — what
  happened?"* → the ETL post-mortem.
- Show it **entirely in T-SQL** (`AI_GENERATE_CHUNKS` + `AI_GENERATE_EMBEDDINGS` +
  `VECTOR_DISTANCE` + `sp_invoke_external_rest_endpoint` to the Foundry chat model)
  **and/or** as a **Python app** (Foundry for models, SQL Server for the vector store).
  Then ask something **not** in the docs → it says "I don't know" (grounding beats
  hallucination — callback to Block 1). `[→ Block 1]`
- Scripts: [`src/demo/block5/`](../src/demo/block5/) (`tsql/` and `python/`).
- **Image idea:** Split screen — a SQL query window vs a terminal — same question, same
  grounded answer + citation.

---

## Section 5 wrap (1 slide, ~1 min)

### Slide 5.W — Takeaways
- **Pair programming** is specify → draft → review → correct — you own correctness;
  trust is earned per task (5.1).
- **MCP** makes the context chore disappear — *use* a server now (5.2), *build* one
  after the break (6.2). `[→ 6.2]`
- **RAG** turns scattered institutional knowledge into a **grounded** assistant —
  answers from *your* docs, with citations, no fine-tuning; SQL Server 2025 can be the
  whole retrieval backend (5.3).
- Bridge: Block 6 — building your own AI-powered tools (and MCP servers) on this foundation.
- **Image idea:** Three takeaway chips (pair / MCP / RAG) with an arrow to Block 6.

---

## Appendix — Presenter prep & fact-check (not slides)

### Demo prep
- **5.1 pair-programming (JS):** lock the demo schema + scenario; reuse across 2.3 /
  5.1 / 6.2. Pick the tool to pair in live (Copilot inline vs Claude Code agentic) —
  one, mention the other. Source one genuine sanitized "AI got it wrong" example.
  Pre-record the full loop + save the final correct proc.
- **5.2 Microsoft Learn MCP (JS):** run on home turf (Claude Code/Desktop); confirm the
  workshop machine has it configured. Decide whether to *show* a DB MCP server here
  read-only or fully defer the DB-connected demo to 6.2 (lean defer, to protect its
  thunder). Pre-capture before/after screenshots + the config snippet.
- **5.3 RAG (KF — built, `src/demo/block5/`):** SQL Server 2025 container running; a
  **Foundry** resource with an embedding deployment (e.g. `text-embedding-3-small`) +
  a chat deployment (e.g. `gpt-4o-mini`) + API key. Python variant also needs `pyodbc`
  + MS ODBC Driver 18. Copy `.env.example` → `.env`. **T-SQL run order:** `00_setup.sql`
  → `load_docs.sql` → `01_index.sql` → `02_rag.sql` (edit `@question`). **Python:**
  `rag.py index` then `rag.py ask "<question>"`. Verified locally: chunking, doc load,
  `VECTOR_DISTANCE` retrieval; re-test the Foundry embed/chat calls before delivery.

### Coordination & callbacks
- Architecture depth split: introduce Tools/Resources/Prompts in 5.2, **build** them
  in 6.2 — don't teach twice.
- How the 5.3 pieces map back (KF narration): embeddings & similarity → Block 1;
  `VECTOR` / DiskANN / `VECTOR_SEARCH` / hybrid+RRF / re-ranking / `AI_GENERATE_CHUNKS`
  / `AI_GENERATE_EMBEDDINGS` → Block 4; governance (don't leak docs, verify) → Block 2.
- 6.3's runbook-assistant idea points back here — keep 5.3 the *technique*, 6.3 the *tool*.

### Fact-check (verify before delivery)
- `AI_GENERATE_CHUNKS`, `AI_GENERATE_EMBEDDINGS`, `VECTOR_SEARCH`, `CREATE VECTOR INDEX`
  are **SQL Server 2025 preview** (need `PREVIEW_FEATURES = ON`); `VECTOR` type and
  `VECTOR_DISTANCE` (kNN) are **GA**. (Same fact sheet as Block 4.)
- Hybrid search = vector + full-text fused with RRF; re-ranking via RRF or a semantic
  re-ranker — consistent with Block 4's 4.3.
- **MCP** SDKs are pre-1.0 — re-verify any live config/API near the event (context7).
