#!/bin/bash
set -e

# If duckdb/data folder exists in the project workspace, auto-register into DuckDB
if [ -d "./duckdb/data" ]; then
    python /usr/local/bin/init_duckdb.py
fi

# Execute the command passed to the container (e.g. dbt build, bash, etc.)
exec "$@"
