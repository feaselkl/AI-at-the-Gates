#!/usr/bin/env bash
# =============================================================================
# install-harrier-linux.sh
# Sets up a local Ollama embedding endpoint for the SQL Server 2025 vector demo.
#
#   1. Installs Ollama (if not already installed).
#   2. Pulls the Harrier embedding model GGUF from Hugging Face.
#   3. Renames it to the short name "harrier".
#   4. Persists OLLAMA_HOST=0.0.0.0:11434 (systemd override) so the TLS proxy
#      container can reach Ollama on the host -- no stage-day step to forget.
#
# Harrier (microsoft/harrier-oss-v1-0.6b) is a multilingual *embedding* model
# (feature-extraction, sentence-transformers, SOTA on MTEB v2 at release). The
# 0.6B variant returns 1024-dimensional vectors -- so use VECTOR(1024) on the
# SQL Server side. The GGUF build used here is mradermacher's quantization.
# =============================================================================
set -euo pipefail

# --- Configuration (change MODEL_REPO to use a different model) ---------------
MODEL_REPO="hf.co/mradermacher/harrier-oss-v1-0.6b-GGUF"   # Ollama pulls GGUF straight from Hugging Face
TARGET_NAME="harrier"
OLLAMA_HOST="${OLLAMA_HOST:-http://127.0.0.1:11434}"

# --- 1. Install Ollama if missing --------------------------------------------
if command -v ollama >/dev/null 2>&1; then
    echo "==> Ollama already installed: $(ollama --version 2>/dev/null | head -1)"
else
    echo "==> Installing Ollama (official Linux install script)..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

# --- 2. Make sure the Ollama server is running -------------------------------
ensure_server() {
    if curl -fsS "${OLLAMA_HOST}/api/version" >/dev/null 2>&1; then return 0; fi
    echo "==> Starting Ollama server..."
    if command -v systemctl >/dev/null 2>&1 \
       && systemctl list-unit-files 2>/dev/null | grep -q '^ollama\.service'; then
        sudo systemctl start ollama 2>/dev/null || true
    fi
    if ! curl -fsS "${OLLAMA_HOST}/api/version" >/dev/null 2>&1; then
        ollama serve >/tmp/ollama-serve.log 2>&1 &
    fi
    for _ in $(seq 1 30); do
        curl -fsS "${OLLAMA_HOST}/api/version" >/dev/null 2>&1 && return 0
        sleep 1
    done
    echo "ERROR: Ollama server did not become ready at ${OLLAMA_HOST}" >&2
    exit 1
}
ensure_server
echo "==> Ollama server is up at ${OLLAMA_HOST}"

# --- 3. Pull the model (no tag => Ollama picks the default quant, tagged :latest)
echo "==> Pulling ${MODEL_REPO} (downloads the GGUF from Hugging Face)..."
ollama pull "${MODEL_REPO}"

# --- 4. Rename to "harrier" (Ollama has no rename: copy, then remove original)
SRC="$(ollama list | awk 'NR>1 {print $1}' | grep -i 'harrier-oss-v1-0.6b-GGUF' | head -1)"
if [ -z "${SRC}" ]; then
    echo "ERROR: could not find the pulled model in 'ollama list'." >&2
    exit 1
fi
echo "==> Renaming '${SRC}' -> '${TARGET_NAME}'"
ollama cp "${SRC}" "${TARGET_NAME}"
ollama rm "${SRC}"

# --- 5. Verify it embeds, and report the dimension ---------------------------
echo "==> Model details:"
ollama show "${TARGET_NAME}" || true
if curl -fsS "${OLLAMA_HOST}/api/embed" \
        -d "{\"model\":\"${TARGET_NAME}\",\"input\":\"cold holding temperature violation\"}" \
        2>/dev/null | grep -q '"embeddings"'; then
    echo "==> Embedding smoke test: OK"
else
    echo "==> WARNING: embedding smoke test did not return embeddings; check 'ollama show ${TARGET_NAME}'." >&2
fi
DIM="$(ollama show "${TARGET_NAME}" 2>/dev/null | grep -i 'embedding length' | awk '{print $NF}')"

# --- 6. Make Ollama listen on all interfaces (0.0.0.0) so the TLS proxy can
#        reach it from its container. Persisted via a systemd drop-in.
BIND_ADDR="0.0.0.0:11434"
if command -v systemctl >/dev/null 2>&1 \
   && systemctl list-unit-files 2>/dev/null | grep -q '^ollama\.service'; then
    echo "==> Persisting OLLAMA_HOST=${BIND_ADDR} via systemd override..."
    sudo mkdir -p /etc/systemd/system/ollama.service.d
    printf '[Service]\nEnvironment="OLLAMA_HOST=%s"\n' "${BIND_ADDR}" \
        | sudo tee /etc/systemd/system/ollama.service.d/10-ollama-host.conf >/dev/null
    sudo systemctl daemon-reload
    sudo systemctl restart ollama
    echo "==> Ollama service restarted; now listening on ${BIND_ADDR}."
else
    echo "==> No systemd ollama.service found; restarting a background server on ${BIND_ADDR}..."
    pkill -f 'ollama serve' 2>/dev/null || true
    sleep 1
    OLLAMA_HOST="${BIND_ADDR}" nohup ollama serve >/tmp/ollama-serve.log 2>&1 &
    echo "    To persist across reboots, add 'export OLLAMA_HOST=${BIND_ADDR}' to your shell profile."
fi

echo "==> Done. '${TARGET_NAME}' is ready (embedding length ${DIM:-1024}); Ollama listening on ${BIND_ADDR}."
echo "    Use VECTOR(${DIM:-1024}) in SQL Server to match this model."
