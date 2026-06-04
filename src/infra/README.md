# Demo environment — full setup

This is the single entry point for standing up the whole "AI at the Gates" demo
environment. The detailed per-component docs are linked throughout.

## Architecture

One compose ([`ollama/tls-proxy/docker-compose.yml`](ollama/tls-proxy/docker-compose.yml))
runs the **two containers**: SQL Server (trusting the proxy cert) and the Caddy
HTTPS proxy. **Ollama runs on the host**, not in a container (installed by a
script). The diagram is as follows:

```
            host machine
 ┌──────────────────────────────────────────────────────────────┐
 │  Ollama  (host process, listening on 0.0.0.0:11434)           │
 │    • harrier      — embeddings, 1024-dim   (Block 4 + Block 1) │
 │    • llama3.2:1b  — small chat model       (Block 1 + 3)       │
 │        ▲ http (11434)                                          │
 │        │                                                       │
 │   ─────┴─────────── docker compose (ollama/tls-proxy) ──────── │
 │   ┌──────────────────┐        ┌───────────────────────────┐   │
 │   │ Caddy TLS proxy  │  https │ SQL Server 2025           │   │
 │   │ container :8443  │◀───────│ container :1433           │   │
 │   │ (TLS → Ollama)   │        │ (trusts proxy cert)       │   │
 │   └──────────────────┘        │ DB: WakeCountyFood        │   │
 │                               └───────────────────────────┘   │
 └──────────────────────────────────────────────────────────────┘
   Browser tools (TF Playground / tokenizer / Embedding Projector) have no host deps
```

Why the proxy at all? SQL Server 2025's `CREATE EXTERNAL MODEL` only accepts
**HTTPS** endpoints, but Ollama serves plain HTTP. To deal with this, Caddy puts TLS in front of it. See [`ollama/tls-proxy/`](ollama/tls-proxy/).

## Prerequisites (install once)

| Tool | For | Notes |
|------|-----|-------|
| Docker | everything | Linux x86-64 or Docker Desktop (the SQL image needs x86-64) |
| 7-Zip CLI (`7z`) | extracting `data/*.7z` | `apt install p7zip-full` / `brew install p7zip` / `winget install 7zip.7zip` |
| Python 3 | Block 1 scripts | no additional libraries required |
| A SQL client | Block 4 | SSMS 22, VS Code with mssql extension, or `sqlcmd` |
| OpenSSL | the TLS cert | ships with macOS/Linux/Git-for-Windows |
| VS Code + Claude Code + internet | Block 3 **online** variant only | optional |

## One-time prep (run from the repo root, in order)

```bash
# 1. Extract the source CSVs (git-ignored; only the .7z archives are committed)
7z x data/Food_Inspections.7z           -odata/
7z x data/Food_Inspection_Violations.7z -odata/
7z x data/Restaurants.7z                -odata/

# 2. Build the base SQL data image (slow ~once; bakes the data in)
docker build -f src/infra/docker/Dockerfile -t wakecounty-sql2025 .

# 3. Install Ollama + the harrier model, and persist OLLAMA_HOST=0.0.0.0
#    (pick your platform)
bash src/infra/ollama/install-harrier-linux.sh      # or -macos.sh
#    Windows:  powershell -ExecutionPolicy Bypass -File src\infra\ollama\install-harrier-windows.ps1
#
#    IMPORTANT: if you install Ollama yourself instead of using this script, you
#    MUST set OLLAMA_HOST=0.0.0.0:11434 so the proxy container can reach it.
#    Otherwise AI_GENERATE_EMBEDDINGS fails with "Msg 31608 ... 0x80070008".
#    See ollama/tls-proxy/README.md -> Troubleshooting.

# 4. Pull the small chat model (Block 1 temperature demo; Block 3 online optional)
ollama pull llama3.2:1b

# 5. Generate the TLS cert for the proxy
( cd src/infra/ollama/tls-proxy && bash generate-cert.sh )

# 6. (Block 1 only) Generate the Embedding Projector files (Ollama must be running)
python3 src/demo/block1/embed_violations.py
```

Steps 2 and 5 are what the stage-day compose depends on (it builds a cert-trusting
SQL image `FROM wakecounty-sql2025` and mounts the cert into Caddy).

## Start the environment (stage day)

```bash
# 1. Make sure Ollama is running — the install script set it to listen on
#    0.0.0.0:11434 (systemd service on Linux; the app on macOS/Windows).

# 2. Bring up SQL + the TLS proxy (builds the cert-trusting SQL image on first run)
cd src/infra/ollama/tls-proxy
docker compose up -d
```

Connect: **`localhost,1433`**, login **`sa`**, password **`WakeCounty!2025`**,
database **`WakeCountyFood`**.

> ⚠️ **Rebuilt the base image (data or schema changed)? Use `--build`:**
> `docker compose up -d --build`. The proxy compose builds a *derived* image
> (`FROM wakecounty-sql2025`) that adds cert trust; a plain `docker compose up`
> reuses that cached derived image and you'll get **stale data** (e.g., a missing
> table) even though the base image is current. `--build` re-pulls the new base.

> **Just the database, no AI?** Use the standalone compose instead —
> `cd src/infra/docker && docker compose up -d`. Don't run both: they share the
> container name and port 1433.

## Run each block's demo

| Block | What to run | Needs the SQL container? | Guide |
|-------|-------------|--------------------------|-------|
| **1** | Browser tools; `python3 src/demo/block1/temperature_demo.py`; load `src/demo/block1/{vectors,metadata}.tsv` into [projector.tensorflow.org](https://projector.tensorflow.org) | No (uses host Ollama only) | [`../demo/block1/`](../demo/block1/) |
| **3** | The prompt makeover (online via Claude Code, or offline) | Optional — to run queries live | [`../demo/block3/`](../demo/block3/) |
| **4** | In a SQL client, run `src/demo/block4/10 → 40` in order (register model → embed → index → search) | Yes | [`../demo/block4/`](../demo/block4/) |

## Smoke test (verify the wiring)

```bash
# Proxy + Ollama reachable over HTTPS (trusting our self-signed cert):
curl --cacert src/infra/ollama/tls-proxy/certs/ca.crt \
  https://localhost:8443/api/embed -d '{"model":"harrier","input":"test"}'

# SQL data present:
docker exec wakecounty-sql2025 /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'WakeCounty!2025' -C -d WakeCountyFood \
  -Q "SELECT COUNT(*) AS restaurants FROM dbo.Restaurant;"
```

## Teardown

```bash
cd src/infra/ollama/tls-proxy && docker compose down
# optional: free the models / stop Ollama
ollama rm harrier llama3.2:1b
```

## Component docs

- [`docker/`](docker/) - the SQL Server 2025 image (data baked in at build).
- [`ollama/`](ollama/) - install Ollama + the Harrier embedding model.
- [`ollama/tls-proxy/`](ollama/tls-proxy/) - HTTPS proxy + the full-stack compose.
- [`../demo/`](../demo/) - per-block demo assets (`block1`, `block3`, `block4`).
