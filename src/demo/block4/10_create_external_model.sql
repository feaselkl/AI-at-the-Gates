/* =============================================================================
   10_create_external_model.sql   (LIVE DEMO -- not run at build)

   Registers the Harrier embedding model (served by Ollama) so that
   AI_GENERATE_EMBEDDINGS(... USE MODEL HarrierEmbeddings) can call it.

   Set up Ollama + the "harrier" model first with the scripts in
   ../../infra/ollama/ (install-harrier-<platform>), then start the HTTPS proxy in
   ../../infra/ollama/tls-proxy/. Harrier-0.6b returns 1024-dim vectors, matching
   the VECTOR(1024) columns in 020_tables.sql.

   CREATE EXTERNAL MODEL is a SQL Server 2025 preview feature. Confirm syntax at:
   https://learn.microsoft.com/sql/t-sql/statements/create-external-model-transact-sql?view=sql-server-ver17

   -------------------------------------------------------------------------
   IMPORTANT -- two things to get right for the LOCATION:

   1) HTTPS ONLY. SQL Server only allows HTTPS/TLS endpoints for an external
      model. Ollama serves plain HTTP on :11434, so the LOCATION below points at
      the TLS reverse proxy from ../../infra/ollama/tls-proxy/ (Caddy on :8443).
      That proxy's self-signed cert must be trusted inside the SQL container --
      see its README for the one-time trust step.

   2) HOST ADDRESS. SQL Server runs inside the Docker container; the proxy is
      published on the host. From the container, reach the host via:
        - Docker Desktop (Win/macOS): host.docker.internal
        - Docker on Linux: run the SQL container with
          --add-host=host.docker.internal:host-gateway (or use the bridge IP).
   ------------------------------------------------------------------------- */

USE WakeCountyFood;
GO

-- Allow SQL Server to call external REST endpoints (needed by AI_GENERATE_EMBEDDINGS).
EXEC sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO

-- Local Ollama needs no credential. Register Harrier as an EMBEDDINGS model.
IF EXISTS (SELECT 1 FROM sys.external_models WHERE name = N'HarrierEmbeddings')
    DROP EXTERNAL MODEL HarrierEmbeddings;
GO

CREATE EXTERNAL MODEL HarrierEmbeddings
WITH (
    LOCATION   = 'https://host.docker.internal:8443/api/embed',
    API_FORMAT = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL      = 'harrier'
);
GO

-- Smoke test: should return a 1024-element JSON array.
SELECT AI_GENERATE_EMBEDDINGS(N'cold holding temperature violation' USE MODEL HarrierEmbeddings);
GO
