# Block 5 — Database Development in a Generative AI World (5.3 only)

**Slide-deck outline (build notes, not finished slides).**
Part of *AI at the Gates: The DBA's Guide to Surviving in an LLM World*.

- **Duration:** Block 5 is 60 min (2:30 – 3:30). **This file covers 5.3 only**
  ("RAG over Internal Documentation"), ~15–20 min. 5.1 and 5.2 are outlined
  separately / by a co-presenter.
- **Audience:** DBAs, data engineers, database developers — who, by mid-afternoon,
  have seen embeddings (Block 1), the governance rules (Block 2), and SQL Server
  2025 vector storage/search + in-DB AI functions (Block 4).
- **Goal of 5.3:** Show that **RAG is just the day's pieces assembled** — and that
  SQL Server 2025 can be the whole retrieval backend for your team's docs.
- **Format:** discussion **plus a live demo** — RAG over internal DBA runbooks with
  **SQL Server 2025 as the vector store** and **Microsoft Foundry** supplying the
  embedding + chat models (no local GPU). Built two ways: a simple Python app and
  an entirely-in-T-SQL version. See [`src/demo/block5/`](../src/demo/block5/).

---

## How to read this outline

Per slide: **talking points** and an **image idea**. Tags: `[Concept]` for
platform-neutral RAG ideas; `[SS2025 GA]` / `[SS2025 Preview]` for SQL Server 2025
features (consistent with Block 4); `[→ Block N]` for callbacks.

---

## Section 5.3.0 — Opener (1 slide, ~1 min)

### Slide 5.3.0 — You've already built every piece
- RAG = **Retrieval-Augmented Generation**: fetch the right context from *your*
  documents at query time and hand it to the LLM.
- By now you've seen all the parts — embeddings (Block 1), vector storage/search
  in SQL Server 2025 (Block 4), in-DB chunking/embeddings (Block 4). 5.3 snaps them
  together. `[→ Block 1]` `[→ Block 4]`
- **Image idea:** Puzzle pieces labeled "embeddings / vectors / chunking / LLM"
  clicking into one "RAG" picture.

---

## Section 5.3.1 — What RAG is (2 slides, ~5 min)

### Slide 5.3.1a — Retrieval-Augmented Generation, plainly
- The model doesn't *know* your runbooks. RAG **retrieves** relevant snippets and
  **stuffs them into the prompt**, so the answer is grounded in your content — with
  **citations** back to the source. `[Concept]`
- It's **not fine-tuning**: no retraining, no model weights to manage; you change
  the answer by changing the *documents*, not the model. Cheaper, current, auditable.
- **Image idea:** Question → retrieve top snippets from a doc store → prompt
  (question + snippets) → grounded answer with source links.

### Slide 5.3.1b — Why a DBA should care
- Grounds answers in **your** environment (your schema, your incident history),
  which sharply reduces the confident-but-wrong hallucinations from Block 1.
  `[→ Block 1]`
- It's the pattern behind "chat with your docs," internal help bots, and
  schema/runbook Q&A — and you, the data platform owner, own the retrieval layer.
- **Image idea:** A generic LLM answer (vague/guessy) beside a RAG answer (specific,
  cites your runbook).

---

## Section 5.3.2 — Turning tribal knowledge into context (1 slide, ~3 min)

### Slide 5.3.2 — The DBA's gold mine
- The best RAG corpus is the stuff already lying around: **runbooks, incident /
  post-mortem logs, schema docs, deployment notes, internal wikis, ticket history.**
- RAG turns "the thing only Bob knows" into searchable, always-available context —
  resilient to Bob being on vacation (or gone). `[Concept]`
- Discussion hook for the room: *what would you point this at first?* Where does
  your team's tribal knowledge actually live?
- **Image idea:** A pile of sticky notes / wiki pages / PDFs funneling into a
  searchable index.

---

## Section 5.3.3 — Chunking (1 slide, ~3 min)

### Slide 5.3.3 — Chunking: why and how
- Two reasons to split docs into **chunks**: they're too big for the context
  window, and you want to retrieve only the **relevant slice**, not the whole
  manual. `[Concept]`
- Strategies: split by **section/heading**, or **fixed size with overlap** so
  context isn't cut mid-thought. Tradeoff: too big → noisy, dilutes relevance; too
  small → loses surrounding context. `[Concept]`
- In SQL Server 2025 you can chunk **in the database** with `AI_GENERATE_CHUNKS`
  (e.g., `CHUNK_TYPE = FIXED`, `CHUNK_SIZE = …`). `[SS2025 Preview]` `[→ Block 4]`
- **Image idea:** A long document sliced into overlapping passages, each becoming a
  vector.

---

## Section 5.3.4 — A simple RAG pipeline (2 slides, ~5 min)

### Slide 5.3.4a — The pipeline (architecture)
- **Index time:** ingest docs → **chunk** → **embed** each chunk → store
  chunk-text + vector. **Query time:** embed the question → **vector-search** the
  top-k closest chunks → build a prompt (question + chunks) → LLM answers with
  citations. `[Concept]`
- Every box maps to something from today: chunk/embed (Block 4 AI functions),
  store/search (Block 4 `VECTOR` + DiskANN), embeddings intuition (Block 1).
- **Image idea:** Two-lane flow diagram (index lane on top, query lane on bottom)
  sharing the same vector store in the middle.

### Slide 5.3.4b — Doing it *in* SQL Server 2025
- One table: `(chunk_text NVARCHAR(MAX), embedding VECTOR(n), source, …)`.
  Populate with `AI_GENERATE_CHUNKS` + `AI_GENERATE_EMBEDDINGS`; retrieve with
  `VECTOR_DISTANCE` (kNN) or `VECTOR_SEARCH` over a DiskANN index; hand the chunks
  to an LLM (app-side or via an external model). The **database is the retrieval
  layer.** `[SS2025 GA]` (type, kNN) / `[SS2025 Preview]` (index, search) `[→ Block 4]`
- Not the only option — Azure AI Search or a dedicated vector DB also work; use the
  Block 4 "in-database vs dedicated" decision framework. `[→ Block 4]`
- **Image idea:** A single SQL table icon labeled "chunks + vectors" sitting at the
  center of the pipeline.

---

## Section 5.3.5 — Make it actually good (1 slide, ~3 min)

### Slide 5.3.5 — Gotchas that separate a toy from a tool
- **Chunk quality** drives everything — garbage chunks, garbage retrieval.
- **Keep embeddings fresh:** re-embed when the source doc changes (the staleness
  problem). `[→ Block 4]`
- **Hybrid search:** combine vector + keyword so exact tokens (error numbers,
  object names, KB IDs) aren't missed; consider **re-ranking** the top-k. `[→ Block 4]`
- **Cite sources** (trust) and **respect access control** — don't surface a doc to
  someone who shouldn't see it. `[Concept]`
- **Evaluate retrieval** (is the right chunk in the top-k? — recall). `[Concept]`
- **Image idea:** A checklist card: freshness · hybrid · re-rank · cite · permissions
  · evaluate.

---

## Section 5.3.6 — ▶ DEMO: RAG over our runbooks (2 slides, ~6 min)

### Slide 5.3.6a — The demo, and why Foundry
- Corpus: ~6 realistic **internal DBA runbooks** (backup/restore, index maintenance,
  blocking/deadlocks, tempdb, an ETL-failure post-mortem, AG failover).
- **Models from Microsoft Foundry** (embeddings + chat) — no local GPU needed; and
  Foundry's publicly-trusted cert means SQL Server trusts it with **zero cert
  setup** (unlike the local-Ollama path). **Store = SQL Server 2025** (`VECTOR` +
  `VECTOR_DISTANCE`; no ANN index — the corpus is tiny). `[SS2025 GA]` / embed+chunk `[SS2025 Preview]`
- **Image idea:** the pipeline diagram with "Foundry" on the model boxes and "SQL
  Server 2025" on the store box.

### Slide 5.3.6b — ▶ DEMO: two ways
- **Ask a question in your own words** → it retrieves the right runbook chunk and
  answers grounded, **with citations** — even when the question's words don't match
  the doc's. Marquee: *"The nightly load broke overnight and the log filled up —
  what happened?"* → the ETL post-mortem.
- Show it **entirely in T-SQL** (`AI_GENERATE_CHUNKS` + `AI_GENERATE_EMBEDDINGS` +
  `VECTOR_DISTANCE` + `sp_invoke_external_rest_endpoint` to the Foundry chat model)
  **and/or** as a **simple Python app** (Foundry for models, SQL Server for the
  vector store). Then ask something **not** in the docs → it says "I don't know"
  (grounding beats hallucination — callback to Block 1).
- Scripts: [`src/demo/block5/`](../src/demo/block5/) (`tsql/` and `python/`).
- **Image idea:** split screen — a SQL query window vs a terminal — same question,
  same grounded answer + citation.

---

## Section 5.3 wrap (1 slide, ~1 min)

### Slide 5.3.W — Takeaways
- RAG turns scattered institutional knowledge into a **grounded** AI assistant —
  answers from *your* docs, with citations, no fine-tuning.
- SQL Server 2025 can be the **entire retrieval backend** (chunk → embed → store →
  search), reusing exactly what you saw in Block 4.
- You already understand every component — the work is assembly and curation, not
  magic.
- Bridge: Block 6 — building your own AI-powered tools (and MCP servers) on top of
  this foundation.
- **Image idea:** The assembled RAG picture from 5.3.0, now with a "powered by SQL
  Server 2025" stamp and an arrow to Block 6.

---

## Appendix — Presenter notes (not slides)

### Demo prep (built — `src/demo/block5/`)
- **Prereqs:** the SQL Server 2025 container running; a **Foundry** resource with an
  embedding deployment (e.g. `text-embedding-3-small`) + a chat deployment (e.g.
  `gpt-4o-mini`) + the API key. Python variant also needs `pyodbc` + the MS ODBC
  Driver 18.
- **Config:** copy `src/demo/block5/.env.example` → `.env`, fill in endpoint /
  deployments / key (same values fill the `<...>` placeholders in `tsql/`).
- **T-SQL run order:** `tsql/00_setup.sql` → `tsql/load_docs.sql` → `tsql/01_index.sql`
  → `tsql/02_rag.sql` (edit `@question`). **Python:** `python3 python/rag.py index`,
  then `python3 python/rag.py ask "<question>"`.
- **Verified locally:** chunking (`AI_GENERATE_CHUNKS`), doc load, and retrieval
  (`VECTOR_DISTANCE`) run against the container. The Foundry embed/chat calls need
  your endpoint + key, so re-test those before delivery.
- **Sample questions** that land well are listed in `src/demo/block5/README.md`.

### Discussion prompts
- "What three internal docs would you RAG first, and why?"
- "Where does your tribal knowledge live today — wiki, tickets, someone's head?"
- "In-database (SQL Server 2025) vs Azure AI Search vs a dedicated vector DB —
  which fits your shop, using the Block 4 criteria?"

### How the pieces map back (for your narration)
- Embeddings & similarity → Block 1. Vector type / DiskANN / `VECTOR_SEARCH` /
  hybrid + RRF / re-ranking / `AI_GENERATE_CHUNKS` / `AI_GENERATE_EMBEDDINGS` →
  Block 4. Governance (don't leak docs, verify) → Block 2.

### Fact-check (verify before delivery)
- `AI_GENERATE_CHUNKS`, `AI_GENERATE_EMBEDDINGS`, `VECTOR_SEARCH`, `CREATE VECTOR
  INDEX` are **SQL Server 2025 preview** (need `PREVIEW_FEATURES = ON`); `VECTOR`
  type and `VECTOR_DISTANCE` (kNN) are **GA**. (Same fact sheet as Block 4.)
- Hybrid search = vector + full-text fused with RRF; re-ranking via RRF or a
  semantic re-ranker — consistent with Block 4's 4.3.
