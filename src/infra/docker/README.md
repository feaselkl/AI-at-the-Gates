# SQL Server 2025 demo container — Wake County, NC food inspections

A self-contained SQL Server 2025 image with vector indexing enabled and the
Wake County food-inspection dataset already loaded. The data is loaded **at
build time** and baked into the image, so once you build it, anyone can
`docker run` it and the tables are immediately there — ideal for following along.

- Base image: `mcr.microsoft.com/mssql/server:2025-latest` (Developer edition, free)
- Database: `WakeCountyFood`, with `PREVIEW_FEATURES = ON` (enables `CREATE VECTOR INDEX` / `VECTOR_SEARCH`)
- Tables: `dbo.FoodInspection` (~77k rows), `dbo.FoodInspectionViolation` (~311k rows),
  `dbo.Restaurant` (~4.1k rows — links `HSISID` to a real restaurant name/address/location)
- Reserved (nullable) `VECTOR(1024)` columns for the live embedding demo (sized
  for the Harrier model served via Ollama — see [`../ollama/`](../ollama/)):
  `FoodInspection.DescriptionEmbedding`, `FoodInspectionViolation.ShortDescEmbedding`,
  `FoodInspectionViolation.CommentsEmbedding`

> Embeddings and the vector index are created **live in the demo**, not at build
> time (see [`../../demo/block4/`](../../demo/block4/)). The container ships the data substrate.

## Prerequisites

- Docker (Linux x86-64 host; Apple Silicon/ARM is not supported by the SQL Server image)
- ~10 GB free disk and a few minutes for the first build
- A SQL client: `sqlcmd`, SSMS 21, Azure Data Studio, or VS Code mssql extension

## Build

**First, extract the source CSVs.** The CSV files are git-ignored (large, and
regenerable), so a fresh clone only has the `.7z` archives in `data/`. Extract
them before building — the build copies the CSVs into the image:

```bash
# from the repo root: AI-at-the-Gates/
7z x data/Food_Inspections.7z -odata/
7z x data/Food_Inspection_Violations.7z -odata/
7z x data/Restaurants.7z -odata/
```

(`7z` is the p7zip CLI — `apt install p7zip-full`, `brew install p7zip`, or
`winget install 7zip.7zip`. Any tool that unzips `.7z` works.)

Then build from the **repository root** (so the `data/` folder is in the build context):

```bash
# from the repo root: AI-at-the-Gates/
docker build -f src/infra/docker/Dockerfile -t wakecounty-sql2025 .
```

The build starts SQL Server internally, runs the scripts in
[`sql/`](sql/) in order (create DB → create tables → bulk-load CSVs →
index + validate), then shuts down cleanly so the populated database is baked in.
If a load step fails or a table ends up empty, the build fails on purpose.

To use a different SA password, pass it at build time:

```bash
docker build -f src/infra/docker/Dockerfile \
  --build-arg MSSQL_SA_PASSWORD='YourStrong!Passw0rd' \
  -t wakecounty-sql2025 .
```

## Run

```bash
docker run -d --name wakecounty-sql2025 -p 1433:1433 wakecounty-sql2025
```

Connect (default credentials — classroom use, not a secret):

| Setting  | Value             |
|----------|-------------------|
| Server   | `localhost,1433`  |
| Login    | `sa`              |
| Password | `WakeCounty!2025` |
| Database | `WakeCountyFood`  |

```bash
# sqlcmd is inside the container if you don't have it locally:
docker exec -it wakecounty-sql2025 /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'WakeCounty!2025' -C -d WakeCountyFood \
  -Q "SELECT COUNT(*) AS inspections FROM dbo.FoodInspection;
      SELECT COUNT(*) AS violations  FROM dbo.FoodInspectionViolation;"
```

### Or use Docker Compose

```bash
cd src/infra/docker
docker compose up -d --build
```

## What's inside

All three tables relate on **`HSISID`** (the establishment). `HSISID` repeats in
`FoodInspection` / `FoodInspectionViolation` (many inspections/violations over
time) but is **unique in `Restaurant`**. No foreign key is enforced: `Restaurant`
is a current-restaurants snapshot covering only ~half of the inspected
establishments (the rest are closed or non-restaurant facilities), so a FK would
reject the orphans. Join on `HSISID` — **LEFT JOIN** from inspections to
`Restaurant` (some rows have no match), and add the date when you need a single
inspection. `Restaurant` gives demos real names, addresses, and lat/long, and is
**not** used for vector search. Source timestamps are UTC.

## Run the live vector demo

After the container is running, follow [`../../demo/block4/README.md`](../../demo/block4/README.md):
register an embedding model → generate embeddings → create the DiskANN index →
run vector search. These scripts are also copied to `/demo` inside the container.

## Files

```
src/infra/docker/
├── Dockerfile            # multi-stage: bake data at build, ship a clean image
├── docker-compose.yml    # convenience wrapper
├── .env.example          # default SA password
├── build/
│   └── init-build.sh     # build-time orchestrator (start → load → shutdown)
└── sql/                  # runs at build, in filename order (edit/prune freely)
    ├── 010_database.sql
    ├── 020_tables.sql
    ├── 030_load.sql
    └── 040_post_load.sql
```

Related folders:
- [`../../demo/block4/`](../../demo/block4/) — live vector demo scripts (copied to
  `/demo` in the image, but **not** run at build).
- [`../../demo/block1/`](../../demo/block1/) — Block 1 intro demos (no SQL Server).
- [`../../demo/block3/`](../../demo/block3/) — Block 3 prompt-makeover demo (online + offline).
- [`../ollama/`](../ollama/) — scripts to serve the Harrier embedding model
  locally, plus a [`tls-proxy/`](../ollama/tls-proxy/) HTTPS front end.

## Cleanup

```bash
docker rm -f wakecounty-sql2025
docker rmi wakecounty-sql2025
```

## Notes

- The data is baked into the image; no volume is needed. Removing the container
  discards anything you changed at runtime (e.g. embeddings you generate live).
  To persist runtime changes, mount a volume at `/var/opt/mssql` (see the
  commented block in `docker-compose.yml`).
- The CSVs live only in the build stage, so the final image doesn't carry the
  raw 160 MB+ of source files — just the loaded database.
