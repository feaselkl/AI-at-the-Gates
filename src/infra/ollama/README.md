# Ollama + Harrier embedding model

Setup scripts that stand up a local [Ollama](https://ollama.com) instance serving
the **Harrier** embedding model, named `harrier`. This gives the SQL Server 2025
vector demo a local, no-API-key embedding endpoint for `AI_GENERATE_EMBEDDINGS`.

Each script does three things:

1. Install Ollama (if it isn't already installed).
2. Pull the GGUF model `hf.co/mradermacher/harrier-oss-v1-0.6b-GGUF` from Hugging Face.
3. Rename it from the long Hugging Face name to **`harrier`**.

It then runs a quick embedding smoke test and prints the embedding dimension.

## Scripts

| Platform | Script | Run it |
|----------|--------|--------|
| Windows  | `install-harrier-windows.ps1` | `powershell -ExecutionPolicy Bypass -File .\install-harrier-windows.ps1` |
| macOS    | `install-harrier-macos.sh`    | `bash install-harrier-macos.sh` |
| Linux    | `install-harrier-linux.sh`    | `bash install-harrier-linux.sh` |

Install prerequisites per platform: **Windows** uses `winget` (falls back to
downloading the installer); **macOS** uses [Homebrew](https://brew.sh); **Linux**
uses the official `https://ollama.com/install.sh` script.

## About the model

[`microsoft/harrier-oss-v1-0.6b`](https://huggingface.co/microsoft/harrier-oss-v1-0.6b)
is a multilingual **text embedding** model (feature-extraction; built on the
Qwen3 architecture; state-of-the-art on Multilingual MTEB v2 at release). The
0.6B variant produces **1024-dimensional** vectors using last-token pooling with
L2 normalization. We pull mradermacher's GGUF quantization so it runs in Ollama;
with no tag specified, Ollama selects the default quantization and stores it as
`:latest`, which the scripts then copy to `harrier`.

> **Dimension note:** Harrier-0.6b emits **1024-dim** vectors. The docker demo's
> `VECTOR` columns and external model are sized to `VECTOR(1024)` to match.

## Using it from SQL Server 2025

The demo registers Harrier with `CREATE EXTERNAL MODEL` using
`API_FORMAT = 'Ollama'`, `MODEL = 'harrier'`, and Ollama's native embeddings path
`/api/embed`. Two gotchas:

- **HTTPS only.** `CREATE EXTERNAL MODEL` accepts only HTTPS/TLS endpoints, but
  Ollama serves plain HTTP on :11434. Put a TLS reverse proxy (e.g. Caddy or
  nginx with a self-signed cert) in front of Ollama and point `LOCATION` at the
  HTTPS URL.
- **Host address from the container.** SQL Server runs in the docker container
  from [`../docker/`](../docker/); Ollama runs on your host:
  - **Docker Desktop (Windows/macOS):** `host.docker.internal`.
  - **Docker on Linux:** the bridge gateway (often `172.17.0.1`), or run the
    container with `--add-host=host.docker.internal:host-gateway`.

See [`../../demo/block4/10_create_external_model.sql`](../../demo/block4/10_create_external_model.sql)
for the ready-to-edit registration, and [`tls-proxy/`](tls-proxy/) for the HTTPS
front end that makes it reachable.

## Re-running

The scripts are idempotent enough to re-run: they skip install if Ollama is
present, re-pull (cached) the model, and re-create `harrier`. To remove the model:

```bash
ollama rm harrier
```
