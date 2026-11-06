# Deck changes for Day of Data Portland (November 2026)

Factual corrections applied directly to `scenic-city-aigates-precon.pptx` on 2026-11-01.
Only text was changed: no layout, color, or image changes. If the deck gets rebuilt from
`build_deck.py`, these edits need to go into its source, or the rebuild will revert them.

Facts were re-checked against Microsoft Learn on 2026-11-01. Sources are listed at the bottom.

## Visible slide text

| Slide | Was | Now | Why |
|---|---|---|---|
| 41 | Foundry, Azure OpenAI, Copilot, **Claude for Work**. | ... Copilot, **Claude Team/Enterprise**. | "Claude for Work" is an old umbrella name; the plans are Team and Enterprise. |
| 57 | Then,ask for improvements | Then ask for improvements | Typo. |
| 68 | DiskANN "Used by": SQL Server 2025, Azure SQL, Cosmos DB | SQL family, Cosmos DB, Azure PostgreSQL | Azure Database for PostgreSQL has a GA DiskANN index (`pg_diskann`). Shortened to fit the cell. |
| 71 | AI_GENERATE_EMBEDDINGS / AI_GENERATE_CHUNKS / CREATE EXTERNAL MODEL: **Preview + endpoint config** | **GA (needs an endpoint)** | These are GA in SQL Server 2025. Only vector index, VECTOR_SEARCH, and float16 need PREVIEW_FEATURES. |
| 72 | Azure SQL Database / Fabric SQL Database vectors: **Available** | **GA** | Vector index + VECTOR_SEARCH are GA there now. |
| 72 | Azure SQL Managed Instance vectors: **Available** | **GA (Always-up-to-date)** | GA on that update policy; preview on the SQL Server 2025 policy. |
| 73 | ...read-only after index creation, and you need ≥ 100 rows before building. ... is currently Azure SQL DB / Fabric only. | ...read-only after index creation, needs ≥ 100 rows before building, and requires a clustered primary key on an int column. ... are currently only in Azure SQL DB, Fabric, and Managed Instance (Always-up-to-date). | Missing requirement of the earlier index version; MI added. |
| 75 | pgvector (including Azure Database for PostgreSQL): HNSW + IVFFlat, open source, in the engine. | pgvector: HNSW + IVFFlat, open source, in the engine. Azure Database for PostgreSQL adds DiskANN (pg_diskann). | `pg_diskann` is GA. |
| 77 | Subtitle copied from slide 66 ("Microsoft's rule of thumb: exact search is fine under ~50,000 vectors...") | Exact kNN, a DiskANN index, and approximate search over Wake County violation comments. | Copy-paste error. The text box is the same color as the background, so this was invisible on screen; fix or delete it in the engine. |
| 83 | → one vector per page; big, off-row | → about one vector per page | A 4,104-byte vector fits in-row; "off-row" was wrong in the general case. |
| 84 | Build time scales with row count and parallelism, so MAXDOP is your lever in CREATE VECTOR INDEX. | Build time scales with row count and parallelism. Known issue: SQL Server 2025 ignores MAXDOP on CREATE VECTOR INDEX, so set it at the server or database level. | Documented known issue in SQL Server 2025. |
| 87 | kNN vs ANN plan choice: The optimizer picks based on query shape; the FORCE_ANN_ONLY hint overrides it. | SQL Server 2025: you choose (VECTOR_DISTANCE is exact, VECTOR_SEARCH uses the index). Azure's newer index lets the optimizer choose. | Optimizer-chosen ANN and FORCE_ANN_ONLY exist only on the latest index version, which SQL Server 2025 doesn't have. FORCE_ANN_ONLY also requires `SELECT TOP (N) WITH APPROXIMATE`. |
| 88 | Copilot in SSMS 22 or VSCode reads wait stats + plans | Copilot Agent mode in SSMS 22 or VS Code pulls waits + plans | Agent mode is GA in SSMS 22.10.2 and runs the queries itself. |
| 89 | Subtitle copied from slide 66 | Hand a slow query to an AI assistant, check its diagnosis against the waits and the plan, then prove the fix. | Copy-paste error (also invisible on screen, same as 77). |
| 90 | The VECTOR type and kNN are GA. Vector indexes, vector search, and embeddings are preview features hidden behind a flag. | The VECTOR type, kNN, and in-database embedding generation are GA. Vector indexes and vector search are still preview, behind a flag. | Embeddings are GA. |
| 90 | ...low memory requierments. ...currently in in Azure/Fabric SQL DB. | ...low memory requirements. ...currently in Azure/Fabric SQL DB. | Typos. |
| 108-123 | Footer "SLIDE 102" ... "SLIDE 117" | "SLIDE 108" ... "SLIDE 123" | Footer numbers were 6 behind the real slide numbers. The engine's numbering probably needs the same fix. |

## Speaker notes

| Slide | Change |
|---|---|
| 3 | "Resident of Durham, NC" corrected to Raleigh, matching the slide. |
| 18 | Added: reasoning models (GPT-5 series in Azure OpenAI) don't accept temperature or top_p; the dials still apply to ordinary chat models like the llama3.2 demo model. |
| 41 | Added a note explaining the Claude plan rename. |
| 68 | Added: Azure PostgreSQL `pg_diskann` is GA. |
| 70 | MAXDOP is accepted but ignored on SQL Server 2025 (known issue). |
| 71 | Corrected the "all preview-gated" claim: embeddings, chunks, and external models are GA. |
| 72 | Added the GA status for Azure SQL DB, Fabric, and MI (Always-up-to-date). |
| 73 | Added: the int clustered PK requirement; `ALLOW_STALE_VECTOR_INDEX` exists in Azure SQL DB / Fabric only, not SQL Server 2025. |
| 77 | Replaced copied notes with a pointer to the `src/demo/block4/10`-`40` scripts. |
| 82 | `[SS2025 Preview]` changed to `[SS2025 GA]`; local ONNX is still preview and Windows-only. |
| 84 | MAXDOP known issue. |
| 85 | The XEvents are GA; added `sys.dm_db_vector_indexes` (latest index version only). |
| 86 | External models are GA; added DR limits (no replication to subscribers, no partitioning, no DacPac; BACPAC works from DacFx 170.5.96). |
| 87 | FORCE_ANN_ONLY and optimizer choice are latest-version-only. |
| 88 | Copilot in SSMS GA in 22.4.1, Agent mode GA in 22.10.2, CONSTITUTION.md `agentExecuteAsUser` since 22.7. |
| 89 | Replaced copied notes with a pointer to `src/demo/block4/perf-triage/`. |

## Metadata

Cleared the core-properties description field, which read "generated using python-pptx".

## Not changed (for Kevin and Jonathan to decide)

- RAG slides 101-106 still carry "Jonathan-drafted ... KF to revise" notes.
- Structural and wording changes (de-AI pass, duplication, Block 4 arc) are a separate round.

## Sources (Microsoft Learn, checked 2026-11-01)

- Opt in for preview features FAQ (sql-server-ver17): AI_GENERATE_EMBEDDINGS and CREATE EXTERNAL MODEL are GA.
- CREATE VECTOR INDEX and VECTOR_SEARCH (sql-server-ver17): version differences, int PK requirement, TOP_N deprecation, FORCE_ANN_ONLY, limitations.
- SQL Server 2025 known issues: MAXDOP ignored for vector indexes.
- ALTER DATABASE SCOPED CONFIGURATION: ALLOW_STALE_VECTOR_INDEX not available in SQL Server 2025.
- SSMS 22 release notes: Copilot GA (22.4.1), Agent mode preview (22.7), Agent mode GA (22.10.2).
- Azure Database for PostgreSQL: pg_diskann extension.
- Azure OpenAI chat completions how-to: reasoning models don't support temperature or top_p.
