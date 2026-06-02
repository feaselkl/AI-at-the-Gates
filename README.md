# AI at the Gates — The DBA's Guide to Surviving in an LLM World

A full-day, pre-conference workshop for SQL Server database professionals, built
around SQL Server 2025's vector features and a running dataset of Wake County, NC
food inspections.

## Repository map

| Path | What's there |
|------|--------------|
| [`outlines/`](outlines/) | Per-block slide outlines (`Block1.md`, `Block3.md`, `Block4.md`, …) |
| [`src/infra/`](src/infra/) | **The demo environment** — SQL Server 2025 container, Ollama, TLS proxy |
| [`src/demo/`](src/demo/) | Per-block demo assets (`block1`, `block3`, `block4`) |
| [`data/`](data/) | Source data as `.7z` archives (CSVs are git-ignored — extract before building) |

## Setting up the demo environment

👉 **Start here: [`src/infra/README.md`](src/infra/README.md)** — the single,
ordered guide to prerequisites, one-time prep (extract data → build image →
install Ollama → make cert), starting the stack (`docker compose up -d`), and
running each block's demo.
