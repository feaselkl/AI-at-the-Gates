#!/usr/bin/env bash
# =============================================================================
# install-harrier-macos.sh
# Sets up a local Ollama embedding endpoint for the SQL Server 2025 vector demo.
#
#   1. Installs Ollama (if not already installed) -- via Homebrew.
#   2. Pulls the Harrier embedding model GGUF from Hugging Face.
#   3. Renames it to the short name "harrier".
#   4. Persists OLLAMA_HOST=0.0.0.0:11434 (launchctl env) so the TLS proxy
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
elif command -v brew >/dev/null 2>&1; then
    echo "==> Installing Ollama with Homebrew..."
    brew install ollama
else
    echo "ERROR: Ollama is not installed and Homebrew was not found." >&2
    echo "       Install Homebrew (https://brew.sh) and re-run, or download the" >&2
    echo "       Ollama app from https://ollama.com/download and run this script again." >&2
    exit 1
fi

# --- 2. Make sure the Ollama server is running -------------------------------
ensure_server() {
    if curl -fsS "${OLLAMA_HOST}/api/version" >/dev/null 2>&1; then return 0; fi
    echo "==> Starting Ollama server..."
    ollama serve >/tmp/ollama-serve.log 2>&1 &
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
#        reach it from its container.
BIND_ADDR="0.0.0.0:11434"
echo "==> Persisting OLLAMA_HOST=${BIND_ADDR} (launchctl, for the login session/app)..."
launchctl setenv OLLAMA_HOST "${BIND_ADDR}" 2>/dev/null || true
echo "    To persist across reboots, also add 'export OLLAMA_HOST=${BIND_ADDR}' to your shell profile."
echo "==> Restarting the Ollama server on ${BIND_ADDR}..."
pkill -f 'ollama serve' 2>/dev/null || true
sleep 1
OLLAMA_HOST="${BIND_ADDR}" nohup ollama serve >/tmp/ollama-serve.log 2>&1 &

echo "==> Done. '${TARGET_NAME}' is ready (embedding length ${DIM:-1024}); Ollama listening on ${BIND_ADDR}."
echo "    Use VECTOR(${DIM:-1024}) in SQL Server to match this model."
