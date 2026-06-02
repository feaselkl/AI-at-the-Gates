# Block 4 — Database Administration in a Generative AI World

**Slide-deck outline (build notes, not finished slides).**
Part of *AI at the Gates: The DBA's Guide to Surviving in an LLM World*.

- **Duration:** ~75 minutes (1:00 – 2:15), with two demos interspersed.
- **Audience:** Database professionals — DBAs, data engineers, database developers. Assume strong relational/T-SQL skills; do **not** assume comfort with linear algebra or trigonometry. Build intuition, not proofs.
- **Target platform:** SQL Server 2025 (17.x). Other Azure data platforms are fair game when called out explicitly.
- **Goal:** Understand the new workloads, storage patterns, and operational considerations that generative AI brings to database administration.

---

## How to read this outline

Every slide lists: **talking points**, a **validation tag**, and an **image idea**. Demos are marked **▶ DEMO**.

**Validation tags** (every factual claim carries one — this is the accuracy contract for the deck):

- `[SS2025 GA]` — Generally available in SQL Server 2025 (17.x).
- `[SS2025 Preview]` — In SQL Server 2025 but requires `ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;` (and sometimes additional `sp_configure` flags).
- `[Azure SQL DB / Fabric]` — Behavior or version that is currently in Azure SQL Database and/or SQL database in Microsoft Fabric, **not yet** in box-product SQL Server 2025.
- `[Azure other]` — A different Azure data service (Cosmos DB, Azure AI Search, Azure Database for PostgreSQL, etc.).
- `[Non-MS]` — Third-party / open-source platform.
- `[Concept]` — Platform-neutral concept, true regardless of engine.

> **Standing correction baked into this deck:** the original course outline described SQL Server vectors as "roadmap" and listed "IVFFlat, HNSW" as the index types. Both are now stale. SQL Server 2025 *shipped* vector support, and the entire Microsoft SQL family uses **DiskANN only** (`sys.vector_indexes.vector_index_type` literally reports "DiskANN only for now"). IVFFlat and HNSW are pgvector / dedicated-vector-DB concepts. The deck teaches all three as a mental model but attributes them correctly.

---

## Section 0 — Opener (2 slides, ~3 min)

### Slide 0.1 — "Your database just became an AI workload"
- The pitch: embeddings, vector search, and in-database AI calls are now first-class SQL Server features — which means they're now **your** problem to size, secure, back up, and tune.
- Frame the DBA's question for the next 75 minutes: *"What actually changes in my day job?"*
- Honest scope: we focus on operating these workloads. Syntax lives in the demos.
- **Validation:** `[Concept]`
- **Image idea:** A castle gate (callback to the talk title) with data flowing through — or a split image: classic SSMS object explorer on the left, a glowing vector cloud on the right, joined by a bridge.

### Slide 0.2 — Block 4 roadmap
- Four stops: (A) how vector indexes think, (B) where vectors live, (C) how we query them, (D) how we run them in production.
- Two demos: creating/querying a vector index; using GenAI to triage a performance problem.
- **Validation:** `[Concept]`
- **Image idea:** A simple 4-station "subway map" of the block; reuse this as a progress indicator on section-divider slides.

---

## Section A — Vector Indexes: A DBA's Mental Model (4.1) (6 slides, ~14 min)

### Slide A.1 — Bridge: from "stored embeddings" to "fast search"
- Recap from Block 1: an embedding is just an array of floats stored in a `VECTOR(n)` column. `[SS2025 GA]`
- Each element is a 4-byte single-precision float by default; dimensions are fixed per column (1–1998 for float32). `[SS2025 GA]`
- The new question: *given a query vector, how do I find the closest rows — fast — when I have millions of them?*
- **Validation:** `VECTOR` data type and 1–1998 float32 dimension range are `[SS2025 GA]`.
- **Image idea:** A table row morphing into `[0.12, -0.04, 0.88, …]`, then a magnifying glass hovering over a cloud of dots. Keep it concrete — this audience thinks in rows and columns.

### Slide A.2 — The baseline: exact search (kNN) is a full scan
- Exact nearest-neighbor / k-NN: compute `VECTOR_DISTANCE` from the query vector to **every** row, sort, take top N. `[SS2025 GA]`
- That's a table scan plus a per-row distance computation — predictable, precise, and expensive.
- Microsoft's own guidance: exact search is fine under **~50,000 vectors**, *or* when a `WHERE` predicate trims the candidate set below that. `[Concept]` (Microsoft recommendation)
- Takeaway: you don't always need an index. Reach for exact search first when the working set is small.
- **Validation:** `VECTOR_DISTANCE` and the kNN pattern are `[SS2025 GA]`; the ~50k rule of thumb is Microsoft's published recommendation.
- **Image idea:** A "brute force" visual — one query point with lines drawn to every other point in a scatter cloud. Contrast with the next slide.

### Slide A.3 — Trading accuracy for speed: ANN and "recall"
- Approximate Nearest Neighbor (ANN): give up *guaranteed* correctness for a large speed/scale win. `[Concept]`
- **Recall** defined for DBAs: the fraction of the *true* top-N neighbors the approximate search actually returned. Recall = 1.0 means "identical to exact search." `[Concept]`
- The mindset shift to name out loud: **a vector index returns approximate results.** This is unlike every B-tree index you've ever tuned — "index seek" no longer means "exact."
- Why it's acceptable: embeddings are *already* lossy approximations of meaning, so a recall of ~0.95–0.99 usually changes nothing the user notices.
- **Validation:** `[Concept]` — recall definition and the ANN tradeoff are platform-neutral and consistent with Microsoft docs.
- **Image idea:** Two side-by-side result lists ("Exact" vs "Approx") that are 95% identical, with one row highlighted as different. A small recall dial/gauge graphic.

### Slide A.4 — The index-family landscape (conceptual, correctly attributed)
- Three families you'll hear about. You don't need the math — just the shape:
  - **IVFFlat** — partition vectors into clusters, search only the nearest few clusters. Fast to build, cheaper memory, recall sensitive to how many clusters you probe. *Used by:* pgvector. `[Non-MS]`
  - **HNSW** — a multi-layer "small-world" proximity graph; start coarse at the top, descend to refine. Excellent recall/latency, but **memory-resident** and expensive to build/update. *Used by:* pgvector, Pinecone, Weaviate, Qdrant. `[Non-MS]`
  - **DiskANN** — a single graph engineered to live on **SSD**, not RAM; billion-scale on modest memory. *Used by:* SQL Server 2025, Azure SQL, Cosmos DB. `[SS2025 Preview]` / `[Azure other]`
- Compare on four axes DBAs care about: **build time, memory footprint, recall, update cost.**
- **Validation:** DiskANN as the Microsoft SQL family's index type is `[SS2025 Preview]`/`[Azure other]`; IVFFlat and HNSW attributions are `[Non-MS]`.
- **Image idea:** A 2×2 or three-panel diagram — clusters (IVFFlat), layered graph (HNSW), flat-on-disk graph (DiskANN) — with a small comparison table beneath on the four axes. This is a likely "screenshot-and-keep" slide; make it clean.

### Slide A.5 — Why Microsoft chose DiskANN
- The defining property: the graph is **SSD-resident with minimal memory use**, so you can index far more vectors than fit in RAM while holding high QPS and low latency. `[Concept]` (DiskANN design; Microsoft Research)
- For a DBA this is the headline: **you do not have to size your buffer pool to hold the entire vector index.** Contrast with HNSW's in-memory assumption.
- It balances memory / CPU / I/O — a familiar tradeoff triangle for anyone who tunes storage.
- **Validation:** `[Concept]` — DiskANN's SSD/low-memory design is documented by Microsoft and originates in Microsoft Research.
- **Image idea:** A balance/triangle graphic (Memory ↔ CPU ↔ I/O), with HNSW pinned to the "Memory" corner and DiskANN sitting in the middle. Or a RAM stick vs SSD size comparison.

### Slide A.6 — Decision: index or brute force?
- Simple rule of thumb to anchor the section:
  - **< ~50k candidate vectors** → exact kNN with `VECTOR_DISTANCE`, no index. `[SS2025 GA]`
  - **Large sets, latency-sensitive** → ANN via a vector index. `[SS2025 Preview]`
  - **Selective filter present?** → the filter may shrink the set enough that exact search wins again.
- Tuning knobs reality check: SQL Server 2025's `CREATE VECTOR INDEX` exposes only `METRIC`, `TYPE = 'DiskANN'`, and `MAXDOP` — far fewer knobs than pgvector or Cosmos DB. Most quality tuning is about *choosing exact vs approximate* and *getting filters right*, not turning dials. `[SS2025 Preview]`
- **Validation:** Knob set (`METRIC`/`TYPE`/`MAXDOP`) verified against `CREATE VECTOR INDEX` syntax `[SS2025 Preview]`.
- **Image idea:** A flowchart: "How many candidate vectors?" → branches. Keep it to one decision diamond and two/three outcomes.

---

## Section B — The Vector Storage Landscape (4.2) (6 slides + demo, ~16 min)

### Slide B.1 — What SQL Server 2025 *actually* shipped (GA vs Preview)
- Set the record straight with a status table:
  | Capability | Status |
  |---|---|
  | `VECTOR(n)` data type, vector scalar functions | `[SS2025 GA]` |
  | Exact kNN via `VECTOR_DISTANCE('cosine'|'dot'|'euclidean', …)` | `[SS2025 GA]` |
  | `CREATE VECTOR INDEX` (DiskANN) + `VECTOR_SEARCH` (ANN) | `[SS2025 Preview]` — needs `PREVIEW_FEATURES = ON` |
  | `AI_GENERATE_EMBEDDINGS`, `AI_GENERATE_CHUNKS`, `CREATE EXTERNAL MODEL` | `[SS2025 Preview]` — needs preview features + endpoint config |
  | `float16` (half-precision) vectors, up to 3,996 dims | `[SS2025 Preview]` |
- Practical note: GA features are safe to design production around today; preview features ship but are subject to change and must be explicitly enabled.
- **Validation:** Each row tagged; index/search/embeddings/float16 all confirmed preview-gated in SS2025.
- **Image idea:** A clean GA/Preview status board — green checks vs amber "preview" badges. Mirrors a release-notes aesthetic DBAs trust.

### Slide B.2 — The Microsoft SQL family matrix (and the one big nuance)
- Where vectors run across the family:
  - **SQL Server 2025** — full type + functions; index/search in preview behind a flag. `[SS2025 Preview]`
  - **Azure SQL Database** — vectors available; **no `PREVIEW_FEATURES` flag needed**. `[Azure SQL DB / Fabric]`
  - **SQL database in Microsoft Fabric** — same modern capabilities as Azure SQL DB. `[Azure SQL DB / Fabric]`
  - **Azure SQL Managed Instance** — vectors available when configured with the **SQL Server 2025** or **Always-up-to-date** update policy. `[Azure other]`
- **The nuance to call out explicitly:** the *latest* vector-index version — with **full DML support** (INSERT/UPDATE/DELETE/MERGE with live index maintenance), **iterative filtering**, and **advanced quantization** — is currently **Azure SQL DB / Fabric only**. `[Azure SQL DB / Fabric]`
- SQL Server 2025's current index version carries real limits: the table is effectively **read-only after index creation**, and you need **≥ 100 rows** before building. Plan ETL around that. `[SS2025 Preview]`
- **Validation:** DML/iterative-filtering/quantization availability and the read-only + 100-row constraints all verified against current docs.
- **Image idea:** A capability matrix (rows = features, columns = SS2025 / Azure SQL DB / Fabric / MI) with check/partial/X marks. Highlight the "latest index version" row.

### Slide B.3 — Azure Cosmos DB for vectors
- DiskANN-based, plus `quantizedFlat` and `flat` index options; tuned via JSON index policy. `[Azure other]`
- DBA-relevant levers: **quantization** (smaller index, faster, lower recall) and **sharded / partition-scoped DiskANN** (one graph per partition-key value) — ideal for **multitenant** isolation and noisy-neighbor protection. `[Azure other]`
- Cost model is **RU-based**, not core/memory — a different mental model for capacity planning.
- When it fits: your operational data already lives in Cosmos DB and you want search co-located with it.
- **Validation:** `[Azure other]` — DiskANN/quantizedFlat, `vectorIndexShardKey`, and RU model verified against Cosmos DB docs.
- **Image idea:** Multitenant diagram — several tenant "lanes," each with its own small DiskANN graph, vs one giant shared graph. Reinforces the sharding idea.

### Slide B.4 — Beyond Microsoft: the rest of the field
- One comparison slide so attendees can talk to stakeholders, then back to SQL:
  - **pgvector** (incl. **Azure Database for PostgreSQL**) — HNSW + IVFFlat, in-database, open source. `[Azure other]` / `[Non-MS]`
  - **Azure AI Search** — managed vector + hybrid + semantic ranking; a search service, not a database. `[Azure other]`
  - **Dedicated vector DBs** — Pinecone (managed), Weaviate, Qdrant, Milvus. Purpose-built, HNSW-centric. `[Non-MS]`
- The honest framing: these are *specialized* and often excellent at pure vector scale — but they're another system to secure, sync, and back up.
- **Validation:** pgvector index types and the dedicated-DB names are `[Non-MS]`; Azure AI Search / Azure DB for PostgreSQL are `[Azure other]`.
- **Image idea:** A landscape "quadrant" or logo grid grouped into three buckets: In-database (SQL family, pgvector) / Managed search (Azure AI Search) / Dedicated vector DBs. Avoid implying a ranking.

### Slide B.5 — Decision framework: in-database vs dedicated store
- The choice that actually matters. Decide with these criteria:
  - **Data gravity** — are the vectors describing rows that already live in SQL Server? Co-location avoids a sync pipeline.
  - **Transactional consistency** — do embeddings need to stay in sync with their source rows atomically? In-DB wins.
  - **Operational burden** — one engine to back up/secure/patch vs two.
  - **Scale & latency** — billions of vectors at sub-10ms may justify a dedicated store.
  - **Cost model & team skills** — RU vs core licensing; does your team already run SQL Server?
- **Recommendation (state it plainly):** for most DBA-owned workloads where vectors annotate existing relational data, keep them **in SQL Server / Azure SQL**. Reach for a dedicated store only when scale or latency proves you must.
- **Validation:** `[Concept]` — decision criteria are platform-neutral guidance.
- **Image idea:** A decision scorecard / weighted checklist graphic, or a balance scale: "Keep it in the database" vs "Add a dedicated vector store."

### Slide B.6 — ▶ DEMO: Create and query a vector index in SQL Server 2025
- Setup beats only (syntax lives in the live demo): enable `PREVIEW_FEATURES`; create a `VECTOR` column; `CREATE VECTOR INDEX … WITH (METRIC='cosine', TYPE='DiskANN')`; query with `SELECT TOP (N) WITH APPROXIMATE … FROM VECTOR_SEARCH(…) ORDER BY distance`. `[SS2025 Preview]`
- Point to watch: the optimizer decides DiskANN-vs-kNN automatically; `FORCE_ANN_ONLY` exists if you must override. `[SS2025 Preview]`
- **Link-back:** results `LEFT JOIN` the `Restaurant` table so the room sees real names ("ANGUS BARN, Raleigh") instead of an `HSISID`. (Restaurant is relational only — not vectorized.) `[Concept]`
- **Validation:** All demo surface area is `[SS2025 Preview]`; flag the preview switch on screen.
- **Image idea:** Demo title slide / "to the keyboard" interstitial with an SSMS 21 screenshot framing.

---

## Section C — Vector Access Patterns (4.3) (5 slides, ~12 min)

### Slide C.1 — Pure vector vs hybrid search
- **Pure vector** — rank purely by semantic similarity. Great for "find me things *about* this." `[Concept]`
- **Hybrid** — combine vector similarity with **full-text/keyword (BM25)** search in one query. `[SS2025 GA]` (full-text) + `[SS2025 Preview]` (vector)
- Why hybrid exists: pure vector search fumbles exact tokens — product codes, SKUs, person names, rare jargon — where keyword search is precise.
- **Validation:** Full-text search is `[SS2025 GA]`; combining it with vector search is the hybrid pattern (vector side `[SS2025 Preview]`).
- **Image idea:** Venn diagram — "semantic similarity" circle and "keyword match" circle, overlap labeled "hybrid."

### Slide C.2 — Filtered vector search and the post-filter trap
- The common need: "find similar rows **where** `region = 'EU'` and `status = 'active'`." `[Concept]`
- **The trap to teach:** run ANN first (top-N), *then* filter — and you may be left with almost nothing, because the filtered-out rows used up your top-N slots. Post-filtering silently wrecks recall. `[Concept]`
- **The fix:** **iterative filtering** applies the `WHERE` predicate *during* the graph search, not after. Available with the latest index version. `[Azure SQL DB / Fabric]`
- DBA guidance for SQL Server 2025 today: when filters are highly selective, exact kNN over the filtered set is often the safer, simpler choice. `[SS2025 GA]`
- **Demo tie-in:** "pest-like violations at restaurants **in Raleigh**" — filter on `Restaurant.City`, then exact kNN on the small filtered set. Concrete filtered-search example powered by the `Restaurant` link-back. `[SS2025 GA]`
- **Validation:** Iterative filtering availability is `[Azure SQL DB / Fabric]`; the post-filter recall problem is `[Concept]`.
- **Image idea:** Before/after: a top-10 ANN result list with 8 rows greyed out by a filter (leaving 2) vs iterative filtering returning a full, correct 10.

### Slide C.3 — Hybrid ranking with Reciprocal Rank Fusion (RRF)
- Problem: vector distance scores and BM25 scores aren't on the same scale — you can't just add them. `[Concept]`
- **RRF** fuses two ranked lists using each item's *rank position* (not raw score), and supports per-list **weights** to favor semantic or keyword results. `[Concept]`
- In the SQL family this is implemented in T-SQL (combine `VECTOR_DISTANCE`/`VECTOR_SEARCH` with full-text), and there are EF Core helpers (`Rrf`, `FullTextScore`). `[SS2025 GA]`/`[Azure other]`
- Benchmarks consistently show hybrid + ranking beats either method alone for relevance.
- **Validation:** RRF mechanics are `[Concept]`; SQL/EF Core implementations verified `[SS2025 GA]`/`[Azure other]`.
- **Image idea:** Two ranked lists feeding into an "RRF" funnel that emits one merged, re-ordered list. Show rank numbers, not scores.

### Slide C.4 — Re-ranking strategies
- **RRF re-ranking** — cheap, rank-based, no extra model. Good default. `[Concept]`
- **Semantic re-ranking** — a specialized model (cross-encoder / late-interaction, e.g. **Cohere Rerank**) scores each candidate against the query for higher precision. `[Azure other]`/`[Non-MS]`
- The tradeoff to name: semantic re-ranking adds an external model call → more latency and cost per query. Use it to polish the top-K, not the whole result set.
- **Validation:** Cohere Rerank integration with Azure SQL / SQL Server 2025 is documented `[Azure other]`/`[Non-MS]`.
- **Image idea:** A two-stage pipeline: "Retrieve top 50 (cheap)" → "Re-rank top 10 (expensive model)". Cost/latency meter increasing at stage two.

### Slide C.5 — Batch vs real-time embedding generation
- **In-database** generation: `AI_GENERATE_EMBEDDINGS(text USE MODEL …)` calls a registered `EXTERNAL MODEL` (Azure OpenAI, OpenAI, Ollama, or a local ONNX model). `[SS2025 Preview]`
- **Batch** (e.g., `CROSS APPLY AI_GENERATE_CHUNKS` + `AI_GENERATE_EMBEDDINGS` over a table) vs **real-time** (embed on insert/update). `[SS2025 Preview]`
- **The staleness problem** — every DBA's new maintenance job: when source text changes, its embedding is now wrong until regenerated. You own that refresh strategy (triggers, CDC, scheduled jobs).
- **Validation:** `AI_GENERATE_EMBEDDINGS` / `AI_GENERATE_CHUNKS` / `CREATE EXTERNAL MODEL` are `[SS2025 Preview]`.
- **Image idea:** A timeline showing a row's text edited at T1 but its embedding still reflecting the old text until a refresh at T2 — a red "stale" window between them.

---

## Section D — Operational Considerations for AI-Augmented Workloads (4.4) (6 slides + demo, ~17 min)

### Slide D.1 — Capacity planning: do the vector math
- Storage rule: an element is 4 bytes (float32). A **1024-dim** vector = **4,104 bytes** (4,096 payload + 8-byte header). `[SS2025 GA]`
- Page reality: a SQL data page holds **8,060 bytes** → a 1024-dim vector is **one vector per page**. Vectors are big, off-row citizens; they don't pack like `INT`s. `[SS2025 GA]`
- Worked example to show on slide: 1536-dim (`text-embedding-ada-002`) ≈ **~6 KB/row**; **10M rows ≈ ~60 GB** of vector payload *before* index overhead. `[Concept]` (arithmetic from the GA byte sizes)
- Lever: **`float16` halves storage** (and enables up to 3,996 dims) at some recall cost. `[SS2025 Preview]`
- Planning takeaways: embeddings frequently **dwarf the source rows**; size data + log + backups accordingly; pick the smallest embedding dimension that meets quality.
- **Validation:** Byte sizes and the 8,060-byte page fact are `[SS2025 GA]`; the 10M-row figure is straightforward arithmetic from those; float16 is `[SS2025 Preview]`.
- **Image idea:** A "what fits on a page" graphic: a page packed with hundreds of INTs vs the same page holding a single 1024-dim vector. Plus a bar chart: source table size vs embedding column size.

### Slide D.2 — Memory, build time, and DiskANN's promise
- DiskANN's operational headline again, now quantified for planning: the graph is **SSD-resident**, so RAM pressure is far lower than an in-memory HNSW index of the same data. `[Concept]`
- **Build time** scales with row count and parallelism; `MAXDOP` is your lever in `CREATE VECTOR INDEX`. `[SS2025 Preview]`
- Two operational gotchas to schedule around (SS2025 current index version): **≥ 100 rows required** before build, and the indexed table is **read-only after index creation** — so build *after* bulk load, and rebuild after large changes. `[SS2025 Preview]`
- **Validation:** `MAXDOP` knob, 100-row minimum, read-only-after-build all `[SS2025 Preview]`; DiskANN memory profile `[Concept]`.
- **Image idea:** Timeline of an ETL run: "bulk load → build vector index (read-only gate closes) → serve queries," with the read-only window shaded.

### Slide D.3 — Monitoring: new metrics and a new external dependency
- New surface to watch:
  - `sys.vector_indexes` — index type, distance metric, build parameters/version. `[SS2025 GA]` (catalog view)
  - **Extended Events** for in-DB AI calls: `ai_generate_embeddings_summary`, `external_rest_endpoint_summary` (status codes, errors, model name). `[SS2025 Preview]`
  - **The big new one: an external REST dependency.** In-DB embedding generation calls out to a model endpoint — now you must monitor **endpoint latency, throttling, and failures** as part of database health. `[SS2025 Preview]`
  - **Recall drift** — as data grows/changes, an approximate index's recall can degrade; sample-validate it over time. `[Concept]`
- Query Store, wait stats, and your existing tooling still apply — vector queries show up as ordinary query plans.
- **Validation:** `sys.vector_indexes` is `[SS2025 GA]`; the XEvents are `[SS2025 Preview]`; recall drift is `[Concept]`.
- **Image idea:** A monitoring dashboard mockup with a familiar SQL panel plus two *new* tiles: "Embedding endpoint latency" and "Recall %". The new tiles visually highlighted.

### Slide D.4 — Backup, recovery, and reproducibility
- Good news: vectors are just columns in the database → **normal backup/restore covers them automatically.** A genuine advantage of keeping vectors in-DB vs a separate store you'd back up independently. `[Concept]`
- What backups *don't* fully capture — your recovery runbook must include:
  - **`EXTERNAL MODEL` definitions and credentials** (database-scoped credentials, managed identity / Azure Arc config). `[SS2025 Preview]`
  - **Embedding model + version pinning** — restoring data is useless if you can't reproduce embeddings with the *same* model later. `[Concept]`
  - **`TRUNCATE TABLE` is blocked** on vector-indexed tables — drop the index, truncate, reload (≥100 rows), rebuild. `[SS2025 Preview]`
- **Validation:** TRUNCATE restriction and external-model/credential dependency are `[SS2025 Preview]`; backup coverage and model-version reproducibility are `[Concept]`.
- **Image idea:** A backup "checklist" graphic — database backup (✓ auto) plus three easy-to-forget items (model def, credentials, model version) as separate sticky notes.

### Slide D.5 — Performance tuning for vector query patterns
- What's genuinely new vs classic tuning:
  - **kNN vs ANN plan choice** — the optimizer picks based on query shape; `FORCE_ANN_ONLY` hint overrides it. `[SS2025 Preview]`
  - **Metric must match the index** — a `VECTOR_SEARCH` whose `METRIC` doesn't match the index's metric falls back to exact kNN (with a warning). Easy, silent performance footgun. `[SS2025 Preview]`
  - **Filter placement** — selective filters can favor exact search; non-selective ones favor the index (see C.2). `[Concept]`
- What's reassuringly familiar: it's still query plans, statistics, I/O, and waits. Your instincts transfer.
- **Validation:** `FORCE_ANN_ONLY` and metric-fallback behavior are `[SS2025 Preview]`.
- **Image idea:** A query plan screenshot contrasting an "index scan + distance compute" (kNN) plan vs an ANN plan, annotated. Or a "metric mismatch → silent kNN fallback" warning callout.

### Slide D.6 — AI-assisted performance tuning (and its guardrails)
- The opportunity: **GitHub Copilot in SSMS 21** (and Copilot in Azure for Azure SQL) can read wait stats, explain a plan, and suggest indexes in natural language. `[SS2025 GA]` (Copilot in SSMS)
- Where it helps most: triaging unfamiliar waits, drafting index/rewrite candidates, explaining someone else's query.
- **Guardrails — tie back to Block 2 (governance):**
  - Treat suggestions as *hypotheses*, not truth — validate against your workload before applying.
  - **Don't paste sensitive schema, data, or PII into public LLM tools.** Prefer in-tenant Copilot with your data-governance boundaries.
  - The AI doesn't know your business context, SLAs, or why that "redundant" index exists.
- **Validation:** GitHub Copilot in SSMS is `[SS2025 GA]` (listed in "What's new in SQL Server 2025").
- **Image idea:** Split slide — left: Copilot suggesting an index in SSMS; right: a "verify before you trust" stamp / caution tape. Reinforce the thinking-partner-not-oracle stance.

### Slide D.7 — ▶ DEMO: GenAI triages a real performance problem
- Demo arc (narration, not syntax): present a slow vector/relational query → ask Copilot in SSMS to analyze waits and the plan → it proposes an index or rewrite → **validate** the suggestion and show the before/after. `[SS2025 GA]`
- Emphasize the validation step on screen — model the disciplined behavior you just preached.
- **Validation:** Copilot in SSMS is `[SS2025 GA]`.
- **Image idea:** "To the keyboard" interstitial; afterward, a before/after duration bar to make the payoff concrete.

---

## Section E — Wrap (1 slide, ~2 min)

### Slide E.1 — Takeaways & bridge to Block 5
- Five things to remember:
  1. Vector indexes are **approximate** — "seek" no longer means "exact." Mind recall.
  2. SQL Server 2025 vectors are **real today**: type + kNN are GA; index/search/embeddings are preview behind a flag.
  3. The whole Microsoft SQL family is **DiskANN** — SSD-resident, low memory; the newest index features lead in Azure SQL DB / Fabric first.
  4. Embeddings are **big and perishable** — plan storage, refresh, and an external-endpoint dependency you now have to monitor.
  5. Keep vectors **in the database** unless scale/latency forces a dedicated store.
- Bridge: Block 4 was *running* AI workloads. **Block 5** is *building* with them — pair programming and MCP servers for database development.
- **Validation:** Summary of tagged claims above.
- **Image idea:** The 4-station subway map from Slide 0.2 with all stations now "complete," and a track extending toward "Block 5."

---

## Appendix — Verified fact sheet (for the presenter, not a slide)

All verified against Microsoft Learn for SQL Server 2025 (ver17), May 2026.

- **`VECTOR(n)`**: float32 default, 1–1998 dims; float16 preview, up to 3,996 dims, half storage. Stored binary, shown as JSON array. `[SS2025 GA]` (float16 `[SS2025 Preview]`)
- **Distance metrics**: `'cosine'`, `'dot'`, `'euclidean'`.
- **`VECTOR_DISTANCE`** (exact kNN): `[SS2025 GA]`. Recommended under ~50k candidate vectors.
- **`CREATE VECTOR INDEX … WITH (METRIC=, TYPE='DiskANN', MAXDOP=)`**: DiskANN only; `[SS2025 Preview]`, needs `PREVIEW_FEATURES = ON`.
- **`VECTOR_SEARCH`** (ANN): `SELECT TOP (N) WITH APPROXIMATE … FROM VECTOR_SEARCH(TABLE=, COLUMN=, SIMILAR_TO=, METRIC=) ORDER BY distance`. `[SS2025 Preview]`. `FORCE_ANN_ONLY` hint available.
- **Latest index version** (full DML, iterative filtering, advanced quantization): `[Azure SQL DB / Fabric]` only today. SS2025 current version: read-only after build, ≥100 rows, no `TRUNCATE`.
- **In-DB AI**: `AI_GENERATE_EMBEDDINGS`, `AI_GENERATE_CHUNKS`, `CREATE EXTERNAL MODEL` (Azure OpenAI key/managed-identity, OpenAI, Ollama, local ONNX). `[SS2025 Preview]`; needs `external rest endpoint enabled` and/or `external AI runtimes enabled`.
- **Storage math**: 1024-dim float32 = 4,104 bytes; page = 8,060 bytes → 1 vector/page. 1536-dim ≈ 6 KB.
- **Hybrid/RRF**: vector + full-text (BM25) fused via Reciprocal Rank Fusion; semantic re-rank via Cohere Rerank. Full-text `[SS2025 GA]`; semantic rerank `[Azure other]`/`[Non-MS]`.
- **Monitoring**: `sys.vector_indexes` `[SS2025 GA]`; XEvents `ai_generate_embeddings_summary`, `external_rest_endpoint_summary` `[SS2025 Preview]`.
- **GitHub Copilot in SSMS 21**: `[SS2025 GA]` (What's new in SQL Server 2025 → AI).
- **Other platforms**: Cosmos DB (DiskANN/quantizedFlat, sharded DiskANN, RU model) `[Azure other]`; Azure AI Search (vector+hybrid+semantic) `[Azure other]`; pgvector / Azure DB for PostgreSQL (HNSW+IVFFlat) `[Azure other]`/`[Non-MS]`; Pinecone/Weaviate/Qdrant/Milvus `[Non-MS]`.
