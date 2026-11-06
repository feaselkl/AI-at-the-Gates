# Live vector demo scripts (reference)

These scripts are **not** run during the Docker build. They are the live-demo
path: generate embeddings into the `VECTOR` columns the container already has,
build a DiskANN vector index, and run vector search.

They are copied into the image at `/demo` for convenience, but you'll typically
run them from SSMS / Azure Data Studio / `sqlcmd` against the running container.

## Prerequisites

- The container is running (see [`../../infra/docker/README.md`](../../infra/docker/README.md)).
- `PREVIEW_FEATURES = ON` — already baked into the `WakeCountyFood` database.
- An **embedding endpoint**. These scripts use the **Harrier** model served by
  **Ollama** (set it up with `../../infra/ollama/install-harrier-<platform>`), which
  produces 1024-dim vectors — matching the `VECTOR(1024)` columns.
  - **HTTPS caveat:** `CREATE EXTERNAL MODEL` only accepts HTTPS/TLS endpoints,
    but Ollama serves plain HTTP on :11434. Use the TLS reverse proxy in
    [`../../infra/ollama/tls-proxy/`](../../infra/ollama/tls-proxy/) and point
    `LOCATION` at it. See the header of `10_create_external_model.sql`.
  - Azure OpenAI / OpenAI also work (change `API_FORMAT`/`LOCATION`/`MODEL` and
    set the column dimension to match). A local ONNX model via SQL Server
    Machine Learning Services is **Windows-host only**, not available in this
    Linux container.

  If you have no endpoint in the room, you can still demo exact **kNN**
  (`VECTOR_DISTANCE`) on any rows you manage to embed; the approximate index is
  the part that needs ≥100 embedded rows.

## Order

1. `10_create_external_model.sql` — register the Harrier/Ollama embedding model (one-time).
2. `20_generate_embeddings.sql` — populate the `VECTOR` columns (a subset, by default).
3. `30_create_vector_index.sql` — build the DiskANN index(es).
4. `40_vector_search.sql` — exact kNN and approximate (ANN) vector search.
5. `50_recall_check.sql` — measure the index: recall@10 against exact search over a
   sample of rows (no endpoint needed), plus one typed question with both lists side by side.

Two agent demos live alongside these: [`perf-triage/`](perf-triage/) (Claude Code fixes a slow
query) and [`ssms-agent/`](ssms-agent/) (SSMS Agent mode before and after a `CONSTITUTION.md`).

## Version notes (SQL Server 2025, ver17)

- `VECTOR` data type, `VECTOR_DISTANCE` (kNN), `CREATE EXTERNAL MODEL`, and
  `AI_GENERATE_EMBEDDINGS` are **GA**. They don't need `PREVIEW_FEATURES`.
- `CREATE VECTOR INDEX` and `VECTOR_SEARCH` are **preview** (the preview gate is
  already enabled here).
- SQL Server 2025 ships the *earlier* vector index version. On SQL Server 2025,
  `VECTOR_SEARCH` uses the `TOP_N =` parameter. Microsoft has deprecated `TOP_N`
  in favor of `SELECT TOP (N) WITH APPROXIMATE`, but that form (and the
  `FORCE_ANN_ONLY` hint) only works with the latest index version, which is
  currently in **Azure SQL Database, SQL database in Fabric, and Azure SQL
  Managed Instance (Always-up-to-date policy)**. Both are shown in
  `40_vector_search.sql`.
- With the earlier index version, the table is **read-only after a vector index
  is created**. So: embed first, index last; to add more embeddings later, drop
  the index, embed, then recreate it. The table also needs a **clustered primary
  key on an int column** (all three tables here use `OBJECTID INT`).
- Known issue: SQL Server 2025 ignores `MAXDOP` on `CREATE VECTOR INDEX` and
  `VECTOR_SEARCH`. Set server- or database-level MAXDOP instead.

Syntax here matches Microsoft Learn for SQL Server 2025 as of November 2026, but
vector indexes are still preview features. Confirm against the docs before delivery day:
<https://learn.microsoft.com/sql/sql-server/ai/vectors?view=sql-server-ver17>
