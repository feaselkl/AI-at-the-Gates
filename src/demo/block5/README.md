# RAG demo (section 4) — RAG over internal DBA runbooks

Retrieval-Augmented Generation over a small corpus of **internal DBA runbooks**
([`docs/`](docs/)), with **SQL Server 2025 as the vector store** and **Microsoft
Foundry** (Azure OpenAI) supplying the embedding + chat models. No local GPU —
the models run in Foundry; SQL Server holds the chunks/vectors and does retrieval.

Two parallel variants of the same demo (pick one, or show both):

| Variant | Where it lives | What it shows |
|---------|----------------|---------------|
| **Entirely in T-SQL** | [`tsql/`](tsql/) | Chunk (`AI_GENERATE_CHUNKS`), embed (`AI_GENERATE_EMBEDDINGS`→Foundry), retrieve (`VECTOR_DISTANCE`), and even the chat call (`sp_invoke_external_rest_endpoint`→Foundry) — all in the database. |
| **Simple Python app** | [`python/rag.py`](python/rag.py) | Python reads docs, calls Foundry for embeddings/chat, and uses SQL Server only as the vector store (retrieval via `VECTOR_DISTANCE`). |

> **Why this works cleanly:** Foundry endpoints have **publicly-trusted TLS certs**,
> so SQL Server trusts them with zero cert setup — none of the self-signed-cert
> work the local-Ollama path (Block 4) needed.
>
> **Why no DiskANN index:** the corpus is tiny (~18 chunks), far below the
> ~50k-vector line where ANN pays off — exact kNN with `VECTOR_DISTANCE` (GA) is
> the right tool here (Block 4's guidance). For a big doc set you'd add a vector index.

## Prerequisites

- The SQL Server 2025 container running (see [`../../infra/`](../../infra/)).
- A **Microsoft Foundry** resource with:
  - an **embedding** deployment (e.g. `text-embedding-3-small`, 1536 dims), and
  - a **chat** deployment (e.g. `gpt-4o-mini`), plus the resource **API key**.
- For the Python variant: `pip install pyodbc` and the **Microsoft ODBC Driver 18
  for SQL Server**. (`rag.py` otherwise uses only the standard library.)
- A SQL client (SSMS, Azure Data Studio, VS Code mssql, or `sqlcmd`) for the T-SQL variant.

## Configure

Copy `.env.example` to `.env` and fill in your Foundry endpoint, deployment names,
and key. The same values fill the `<...>` placeholders in the `tsql/` scripts.

## Run — entirely in T-SQL

```text
1. tsql/00_setup.sql       -- create DbaDocs, register the Foundry embedding model
2. tsql/01_load_docs.sql   -- load the runbook text into dbo.KbDoc
3. tsql/02_index.sql       -- AI_GENERATE_CHUNKS + AI_GENERATE_EMBEDDINGS  -> dbo.KbChunk
4. tsql/03_rag.sql         -- ask a question; edit @question and re-run
5. tsql/04_eval.sql        -- test retrieval on fixed questions with known source docs
```
(`01_load_docs.sql` is generated from `docs/*.md` by `make_load_sql.py` — re-run that
if you edit the docs.)

## Run — Python app

```bash
set -a; . ./.env; set +a            # load config
python3 python/rag.py index          # chunk + embed docs -> dbo.KbChunkPy
python3 python/rag.py ask "Users say the app is frozen and saves hang. What do I check?"
```

## Demo questions that land (semantic match across different wording)

- *"The nightly data load broke overnight and the log filled up — what happened?"*
  → retrieves the **ETL post-mortem**, explains the index-rebuild/load overlap.
- *"Users say the app is frozen and saving hangs."* → **blocking/deadlocks** runbook.
- *"How far back can we recover, and what breaks point-in-time restore?"* →
  **backup/restore** runbook (the 15-minute log cadence; broken log chain).
- *"How do I fail over to the DR site and what's the catch?"* → **AG failover** runbook
  (forced failover, possible data loss).
- Ask something **not** in the docs (e.g. "what's our Kafka retention?") → the model
  should say it doesn't know — show that grounding prevents made-up answers.

## Notes

- The two variants use **separate tables** (`dbo.KbChunk` for T-SQL, `dbo.KbChunkPy`
  for Python) in the same `DbaDocs` database, so they don't collide.
- Match `VECTOR(n)` / `EMBED_DIM` to your embedding model (1536 for
  text-embedding-3-small; 3072 for -3-large, which needs a `dimensions` parameter
  or float16).
- `.env` is git-ignored (it holds your key). `01_load_docs.sql` is safe to commit
  (placeholders only, no secrets).
