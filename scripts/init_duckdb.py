#!/usr/bin/env python3
import os
from pathlib import Path
import duckdb

def init_duckdb():
    db_path = os.getenv("DBT_DUCKDB_PATH", "dev.duckdb")
    data_dir = Path("duckdb/data")

    if not data_dir.exists() or not data_dir.is_dir():
        return

    print(f"==> [init_duckdb] Initializing database at '{db_path}' from '{data_dir}/'...")
    con = duckdb.connect(db_path)

    registered_count = 0
    # Recursively find all CSV and Parquet files inside duckdb/data/
    for file_path in data_dir.glob("**/*"):
        if file_path.suffix.lower() in [".csv", ".parquet"]:
            # If the file is inside a subfolder (e.g. duckdb/data/raw/users.csv),
            # the subfolder name becomes the schema ('raw').
            # If directly in duckdb/data/, default to schema 'raw'.
            schema = file_path.parent.name if file_path.parent != data_dir else "raw"
            table_name = file_path.stem

            con.execute(f"CREATE SCHEMA IF NOT EXISTS {schema};")
            
            # Register file as a view directly pointing to the disk path
            con.execute(f"""
                CREATE OR REPLACE VIEW {schema}.{table_name} AS 
                SELECT * FROM '{file_path}';
            """)
            print(f"    ✓ Registered: {schema}.{table_name} -> {file_path}")
            registered_count += 1

    con.close()
    if registered_count > 0:
        print(f"==> [init_duckdb] Successfully registered {registered_count} table(s) in DuckDB.")
    else:
        print("==> [init_duckdb] No .csv or .parquet files found to register.")

if __name__ == "__main__":
    init_duckdb()
