# =============================================================================
# SQL Server 2025 + Wake County, NC food-inspection data, with vector indexing
# enabled. The data is loaded AT BUILD TIME and baked into the image, so a
# learner only has to `docker run` the result -- the tables are already there.
#
# Build from the REPOSITORY ROOT so the data/ folder is in the build context:
#     docker build -f src/infra/docker/Dockerfile -t wakecounty-sql2025 .
#
# See src/infra/docker/README.md for full build/run instructions.
# =============================================================================

# syntax=docker/dockerfile:1
ARG MSSQL_IMAGE=mcr.microsoft.com/mssql/server:2025-latest

# -----------------------------------------------------------------------------
# Stage 1 (build): start SQL Server, load the CSVs, shut down. The raw CSVs and
# tools live only in this stage, so they never bloat the final image.
# -----------------------------------------------------------------------------
FROM ${MSSQL_IMAGE} AS build

# Default SA password meets SQL Server's policy. Override with
# --build-arg MSSQL_SA_PASSWORD=... if you want a different one (also update
# the runtime connection string accordingly).
ARG MSSQL_SA_PASSWORD=WakeCounty!2025
ENV ACCEPT_EULA=Y \
    MSSQL_PID=Developer \
    MSSQL_SA_PASSWORD=${MSSQL_SA_PASSWORD}

USER root

# Source data (paths are relative to the repo root build context).
COPY data/Food_Inspections.csv          /csv/Food_Inspections.csv
COPY data/Food_Inspection_Violations.csv /csv/Food_Inspection_Violations.csv
COPY data/Restaurants.csv                /csv/Restaurants.csv

# Table-creation + load scripts (run in filename order) and the orchestrator.
COPY src/infra/docker/sql/                /sql/
COPY src/infra/docker/build/init-build.sh /usr/local/bin/init-build.sh

RUN chmod +x /usr/local/bin/init-build.sh \
    && chmod -R a+rX /csv /sql

# SQL Server must run as the non-root 'mssql' user.
USER mssql
RUN /usr/local/bin/init-build.sh

# -----------------------------------------------------------------------------
# Stage 2 (final): a clean SQL Server image carrying only the baked database.
# -----------------------------------------------------------------------------
FROM ${MSSQL_IMAGE} AS final

# ACCEPT_EULA is still required at runtime. The SA password was set during build
# and is stored in the baked system databases (default: WakeCounty!2025).
ENV ACCEPT_EULA=Y \
    MSSQL_PID=Developer

USER root
# Bring over the populated data/log directory from the build stage.
COPY --from=build --chown=mssql:0 /var/opt/mssql /var/opt/mssql
# Reference scripts for the live vector demo (NOT executed at build/run).
COPY src/demo/block4/ /demo/

USER mssql
EXPOSE 1433
