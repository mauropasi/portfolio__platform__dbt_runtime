#!/usr/bin/env python3
import os
from collections import defaultdict
from pathlib import Path
import duckdb

def init_duckdb():
    data_dir = Path("duckdb/data")

    if not data_dir.exists() or not data_dir.is_dir():
        return

    print(f"==> [init_duckdb] Scanning '{data_dir}/' for multi-environment databases...")

    # Group files by target database: db_name -> list of (schema, table_name, file_path)
    db_tables = defaultdict(list)

    for file_path in data_dir.glob("**/*"):
        if file_path.suffix.lower() in [".csv", ".parquet"]:
            rel_parts = file_path.relative_to(data_dir).parts
            
            # Pattern 1: duckdb/data/<db>/<schema>/<table_name>.<ext>
            if len(rel_parts) >= 3:
                db_name = rel_parts[0]
                schema = rel_parts[1]
                table_name = file_path.stem
            # Pattern 2: duckdb/data/<db>/<table_name>.<ext> (defaults schema to 'raw')
            elif len(rel_parts) == 2:
                db_name = rel_parts[0]
                schema = "raw"
                table_name = file_path.stem
            # Pattern 3: duckdb/data/<table_name>.<ext> (fallback to dev / raw)
            else:
                db_name = "dev"
                schema = "raw"
                table_name = file_path.stem

            db_tables[db_name].append((schema, table_name, file_path))

    if not db_tables:
        print("==> [init_duckdb] No .csv or .parquet files found in duckdb/data/.")
        return

    # Populate each discovered database
    for db_name, tables in db_tables.items():
        db_file = f"{db_name}.duckdb"
        print(f"==> [init_duckdb] Initializing database '{db_file}' ({len(tables)} tables)...")
        con = duckdb.connect(db_file)

        for schema, table_name, file_path in tables:
            con.execute(f"CREATE SCHEMA IF NOT EXISTS {schema};")
            con.execute(f"""
                CREATE OR REPLACE VIEW {schema}.{table_name} AS 
                SELECT * FROM '{file_path}';
            """)
            print(f"    ✓ [{db_file}] {schema}.{table_name} -> {file_path}")

        con.close()

    # Ensure both dev.duckdb and prod.duckdb exist on disk to support cross-db ATTACH in 12-factor profiles
    for default_db in ["dev", "prod"]:
        default_file = f"{default_db}.duckdb"
        if not Path(default_file).exists():
            con = duckdb.connect(default_file)
            con.close()

    print("==> [init_duckdb] All environment databases successfully initialized.")

if __name__ == "__main__":
    init_duckdb()
