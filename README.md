# AI at the Gates — The DBA's Guide to Surviving in an LLM World

A full-day, pre-conference workshop for SQL Server database professionals, built
around SQL Server 2025's vector features and a running dataset of Wake County, NC
food inspections.

## Repository map

| Path | What's there |
|------|--------------|
| [`slides/`](slides/) | The workshop deck (`scenic-city-aigates-precon.pptx`) and the Portland 2026 rebuild documents (start with [`slides/README.md`](slides/README.md)) |
| [`src/infra/`](src/infra/) | **The demo environment** — SQL Server 2025 container, Ollama, TLS proxy |
| [`src/demo/`](src/demo/) | Per-block demo assets (`block1`, `block3`, `block4`, `block5`) |
| [`data/`](data/) | Source data as `.7z` archives (CSVs are git-ignored — extract before building) |

The demo folders keep their original block names. From the Portland 2026 delivery on, the deck
runs in a different order (see `slides/portland-rebuild-design.md`):

| Deck section | Demos |
|---|---|
| 1. How these models work | `src/demo/block1/` (temperature) |
| 2. Vectors without fear | `src/demo/block1/` (Embedding Projector, Wake County embeddings) |
| 3. Vectors in SQL Server | `src/demo/block4/` scripts `10` to `50` |
| 4. RAG | `src/demo/block5/` |
| 5. Agents: the good and the bad | `src/demo/block3/` (prompt makeover), `src/demo/block4/perf-triage/`, `src/demo/block4/ssms-agent/` |

## Setting up the demo environment

👉 **Start here: [`src/infra/README.md`](src/infra/README.md)** — the single,
ordered guide to prerequisites, one-time prep (extract data → build image →
install Ollama → make cert), starting the stack (`docker compose up -d`), and
running each block's demo.
