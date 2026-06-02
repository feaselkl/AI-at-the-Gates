# TLS reverse proxy for Ollama (full demo stack)

SQL Server 2025's `CREATE EXTERNAL MODEL` only accepts **HTTPS/TLS** endpoints,
but Ollama serves plain **HTTP on :11434**. This folder's
[Caddy](https://caddyserver.com) proxy terminates TLS on **:8443** and forwards
to Ollama, giving the demo a working HTTPS endpoint
(`https://host.docker.internal:8443/api/embed`).

The `docker-compose.yml` here runs the **whole stack**: the Caddy proxy **and** a
SQL Server container that already trusts the proxy's certificate (baked in by
`Dockerfile.sql-trust`). So there is **no manual cert step on stage** — one
`docker compose up -d` and the demo is ready.

```
SQL container (trusts cert) ──HTTPS:8443──▶ Caddy ──HTTP:11434──▶ Ollama (host)
```

## One-time prep (before the talk)

1. **Build the base data image** (slow, do once):
   ```bash
   docker build -f ../../docker/Dockerfile -t wakecounty-sql2025 ../../../..
   ```
2. **Install Ollama + the `harrier` model:** run `../install-harrier-<platform>`.
   That script also persists `OLLAMA_HOST=0.0.0.0:11434` (systemd override on
   Linux, `launchctl`/user env on macOS/Windows) so Ollama listens on all
   interfaces — nothing to set on stage day.
3. **Generate the cert** (CN/SAN = `host.docker.internal`):
   ```bash
   bash generate-cert.sh
   ```
   Writes `certs/ca.crt` (root CA), `certs/ollama-proxy.crt` (server leaf),
   `certs/ollama-proxy.key`, and `certs/fullchain.crt` (all git-ignored).

OpenSSL is needed for step 3 (ships with macOS/Linux/Git-for-Windows).

## Stage day

1. **Make sure Ollama is running** (the install script already configured it to
   listen on `0.0.0.0:11434`). On Linux it's the `ollama` systemd service; on
   macOS/Windows it's the Ollama app/`ollama serve`.
2. **Bring up the stack** (builds the cert-trusting SQL image on first run):
   ```bash
   docker compose up -d
   ```

That's it. SQL is on `localhost,1433` (`sa` / `WakeCounty!2025`, db
`WakeCountyFood`); the proxy is on `localhost:8443`.

> Use **either** this compose **or** the standalone `../../docker/` compose — not
> both (they share the container name and port 1433). This one adds the proxy and
> cert trust on top of the same data image.

### Optional smoke test

```bash
# proxy + Ollama reachable, trusting our self-signed cert:
curl --cacert certs/ca.crt \
  https://localhost:8443/api/embed \
  -d '{"model":"harrier","input":"hello"}'
```

A JSON response containing an `"embeddings"` array means the chain is good.

## Then register the model and run the demo

`LOCATION = 'https://host.docker.internal:8443/api/embed'` is already set in
[`../../../demo/block4/10_create_external_model.sql`](../../../demo/block4/10_create_external_model.sql).
Run that script, then `20_generate_embeddings.sql` and onward.

## How the cert trust is baked in

`Dockerfile.sql-trust` is `FROM wakecounty-sql2025` and copies the **root CA**
(`certs/ca.crt`) into **`/var/opt/mssql/security/ca-certificates/`** — the
directory SQL Server 2025 on Linux reads trusted CAs from for its *outbound* HTTPS
(`AI_GENERATE_EMBEDDINGS`). This is **not** the OS trust store; `update-ca-certificates`
/ `/etc/ssl/certs` are ignored for this. Caddy serves the leaf chain
(`certs/fullchain.crt`), which carries the `serverAuth` EKU and chains to that CA.
Because compose builds the image from this folder, the cert you generated is
picked up automatically.

> ⚠️ **Refresh the derived image after any base change.** Because this image is
> `FROM wakecounty-sql2025`, a plain `docker compose up -d` reuses the previously
> built derived image — so if you rebuilt the base (new data/schema, e.g. adding a
> table) or regenerated the cert, run **`docker compose up -d --build`** to pick up
> the new base. Symptom of forgetting: a table that exists in the base image is
> missing from the running container.

## Troubleshooting

**`AI_GENERATE_EMBEDDINGS` fails with `Msg 31608 ... HRESULT 0x80070008`
("failed to communicate with the external rest endpoint").**
The external model was created, but SQL Server couldn't reach the endpoint.
Diagnose from the outside in:

1. Containers up? `docker ps` should show `ollama-tls-proxy` and `wakecounty-sql2025`.
2. Proxy logs: `docker logs ollama-tls-proxy --tail 20`. If you see
   `dial tcp <ip>:11434: connect: connection refused`, the proxy can't reach
   Ollama — almost always because **Ollama is bound to `127.0.0.1`, not `0.0.0.0`**.
   Confirm: `ss -tlnp | grep 11434` (want `0.0.0.0:11434`).
   - Fix (systemd-managed Ollama):
     ```bash
     sudo mkdir -p /etc/systemd/system/ollama.service.d
     printf '[Service]\nEnvironment="OLLAMA_HOST=0.0.0.0:11434"\n' | \
       sudo tee /etc/systemd/system/ollama.service.d/10-ollama-host.conf
     sudo systemctl daemon-reload && sudo systemctl restart ollama
     ```
   - The `install-harrier-*` scripts do this for you; a **manual** Ollama install
     does not, so set it yourself.
3. Full chain from the host (should return an `"embeddings"` array):
   ```bash
   curl --cacert certs/fullchain.crt \
     https://localhost:8443/api/embed -d '{"model":"harrier","input":"test"}'
   ```
   If this works from the host but SQL still gets `Msg 31608`, it's the
   **certificate-trust** case below, not Ollama.

**`Msg 31608` but the host curl above succeeds → SQL doesn't trust the cert.**
This is the subtle one. SQL Server 2025 on Linux validates outbound HTTPS against
its **own** trust directory — `/var/opt/mssql/security/ca-certificates/` — **not**
the OS store (`/etc/ssl/certs`), so `update-ca-certificates` does nothing for it.
Two requirements:
- The **server leaf** cert must carry the `serverAuth` EKU and chain to a CA
  (a bare self-signed CA used as the server cert is rejected). `generate-cert.sh`
  produces a proper CA + leaf for exactly this reason.
- The **CA** (`certs/ca.crt`) must be in `/var/opt/mssql/security/ca-certificates/`
  in the SQL container. `Dockerfile.sql-trust` bakes it there; confirm with:
  ```bash
  docker exec -u root wakecounty-sql2025 ls -l /var/opt/mssql/security/ca-certificates/
  ```
  If it's missing, you're on a stale derived image — rebuild with
  `docker compose up -d --build` (see the base-change note above).

Also ensure the SQL container can resolve `host.docker.internal` (needs
`--add-host=host.docker.internal:host-gateway` on Linux — the compose sets this).

## Notes

- The cert is self-signed and for **local/classroom use only** — not for any
  internet-facing or production scenario.
- Default port is 8443; change it in `Caddyfile`, `docker-compose.yml`, and the
  `LOCATION` together if it conflicts.
