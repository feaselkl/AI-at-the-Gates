#!/usr/bin/env bash
# =============================================================================
# generate-cert.sh
# Creates a local TLS certificate chain for the Ollama HTTPS proxy that
# SQL Server 2025 will ACCEPT.
#
# Why a CA + leaf (not a single self-signed cert): SQL Server's outbound HTTPS
# client (WinHTTP) is strict. It rejects a bare self-signed CA certificate used
# as a server cert. It requires a proper *server* certificate -- CA:FALSE, with
# the `serverAuth` Extended Key Usage -- that chains to a trusted CA. So we make:
#   - ca.crt / ca.key            : a local root CA (the trust anchor; baked into
#                                  the SQL container by Dockerfile.sql-trust)
#   - ollama-proxy.crt / .key    : the server leaf (SAN + serverAuth EKU)
#   - fullchain.crt              : leaf + CA, served by Caddy
#
# The leaf/CA name (CN/SAN) must match the hostname SQL uses to reach the proxy
# -- by default "host.docker.internal".
#
#   bash generate-cert.sh                      # CN = host.docker.internal
#   bash generate-cert.sh my-proxy-hostname    # custom CN
#
# Requires OpenSSL 1.1.1+ (ships with macOS, Linux, and Git for Windows).
# =============================================================================
set -euo pipefail

CN="${1:-host.docker.internal}"
DIR="$(cd "$(dirname "$0")" && pwd)/certs"
mkdir -p "$DIR"

# --- 1. Root CA (trust anchor) ----------------------------------------------
openssl req -x509 -newkey rsa:2048 -nodes -days 825 -sha256 \
    -keyout "$DIR/ca.key" -out "$DIR/ca.crt" \
    -subj "/CN=Ollama Demo Local CA" \
    -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
    -addext "keyUsage=critical,keyCertSign,cRLSign"

# --- 2. Server leaf: key + CSR -----------------------------------------------
openssl req -newkey rsa:2048 -nodes \
    -keyout "$DIR/ollama-proxy.key" -out "$DIR/ollama-proxy.csr" \
    -subj "/CN=${CN}"

# --- 3. Sign the leaf with the CA (SAN + serverAuth EKU; NOT a CA) ------------
cat > "$DIR/leaf.ext" <<EXT
subjectAltName = DNS:${CN},DNS:localhost,IP:127.0.0.1
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
EXT
openssl x509 -req -in "$DIR/ollama-proxy.csr" \
    -CA "$DIR/ca.crt" -CAkey "$DIR/ca.key" -CAcreateserial \
    -days 825 -sha256 -extfile "$DIR/leaf.ext" \
    -out "$DIR/ollama-proxy.crt"

# --- 4. Full chain for Caddy (leaf + CA) ------------------------------------
cat "$DIR/ollama-proxy.crt" "$DIR/ca.crt" > "$DIR/fullchain.crt"

# --- cleanup intermediates ---------------------------------------------------
rm -f "$DIR/ollama-proxy.csr" "$DIR/leaf.ext" "$DIR/ca.srl"
chmod 644 "$DIR/ca.crt" "$DIR/ollama-proxy.crt" "$DIR/fullchain.crt"

echo "Wrote in $DIR:"
echo "  ca.crt          - root CA (trusted by the SQL container; Dockerfile.sql-trust bakes it)"
echo "  ollama-proxy.crt- server leaf (SAN=${CN}; serverAuth EKU)"
echo "  ollama-proxy.key- server private key (Caddy)"
echo "  fullchain.crt   - leaf + CA (served by Caddy)"
