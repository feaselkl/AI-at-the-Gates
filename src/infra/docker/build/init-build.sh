#!/usr/bin/env bash
# =============================================================================
# init-build.sh
# Runs DURING the Docker build (not at container runtime). It starts SQL Server
# in the background, waits for it to accept connections, runs every script in
# /sql in filename order, then shuts the server down cleanly so the populated
# database files are baked into the image layer.
#
# Learners never run this directly -- it is invoked by the Dockerfile.
# =============================================================================
set -euo pipefail

SQLCMD=/opt/mssql-tools18/bin/sqlcmd
PASSWORD="${MSSQL_SA_PASSWORD:?MSSQL_SA_PASSWORD must be set during build}"

echo "==> Starting SQL Server for the build-time data load..."
/opt/mssql/bin/sqlservr &
SQLSERVR_PID=$!

# Wait (up to ~3 min) for the instance to accept connections.
echo "==> Waiting for SQL Server to accept connections..."
READY=0
for i in $(seq 1 90); do
    if "$SQLCMD" -S localhost -U sa -P "$PASSWORD" -C -l 2 -Q "SELECT 1;" >/dev/null 2>&1; then
        READY=1
        echo "==> SQL Server is accepting connections (after ~$((i * 2))s)."
        break
    fi
    sleep 2
done
if [ "$READY" -ne 1 ]; then
    echo "ERROR: SQL Server did not become ready in time." >&2
    exit 1
fi

# Run each script in order. -b => abort (non-zero exit) on the first SQL error,
# which fails the Docker build; -e => echo the statements for a readable log.
shopt -s nullglob
for script in /sql/*.sql; do
    echo "==> Running ${script}"
    "$SQLCMD" -S localhost -U sa -P "$PASSWORD" -C -b -e -i "$script"
done

echo "==> Shutting SQL Server down cleanly so the data is consistent in the image..."
"$SQLCMD" -S localhost -U sa -P "$PASSWORD" -C -Q "SHUTDOWN WITH NOWAIT;" || true
wait "$SQLSERVR_PID" 2>/dev/null || true

echo "==> Build-time load complete."
