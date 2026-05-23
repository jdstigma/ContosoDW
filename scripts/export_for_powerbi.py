"""
scripts/export_for_powerbi.py
Exports tables from contoso.duckdb to Parquet files for Power BI.

DuckDB writes Parquet natively — no pyarrow chunking needed.
Output lands in exports/ (gitignored).

Usage:
    python scripts/export_for_powerbi.py
    python scripts/export_for_powerbi.py --table AllSales
"""

import os
import subprocess
import sys
import time

try:
    import duckdb
except ImportError:
    print("Installing duckdb...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "duckdb", "-q"])
    import duckdb

REPO_ROOT   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH     = os.path.join(REPO_ROOT, "contoso.duckdb")
EXPORTS_DIR = os.path.join(REPO_ROOT, "exports")

DEFAULT_TABLES = ["AllSales", "DimDate"]


def export_table(conn, table, out_dir):
    out_path = os.path.join(out_dir, f"{table}.parquet").replace("\\", "/")
    t0 = time.time()
    conn.execute(f"""
        COPY (SELECT * FROM "{table}")
        TO '{out_path}'
        (FORMAT PARQUET, COMPRESSION SNAPPY)
    """)
    elapsed = time.time() - t0
    n       = conn.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
    size_mb = os.path.getsize(out_path) / 1_048_576
    print(f"  {table:<33} {n:>12,}   {elapsed:>5.1f}s   {size_mb:>6.1f} MB")


def main():
    if not os.path.exists(DB_PATH):
        print(f"ERROR: {DB_PATH} not found. Run ./setup.sh first.")
        sys.exit(1)

    if "--table" in sys.argv:
        idx    = sys.argv.index("--table")
        tables = [sys.argv[idx + 1]] if idx + 1 < len(sys.argv) else DEFAULT_TABLES
    else:
        tables = DEFAULT_TABLES

    os.makedirs(EXPORTS_DIR, exist_ok=True)
    conn = duckdb.connect(DB_PATH)

    print(f"\n  {'Table':<33} {'Rows':>12}   {'Time':>7}   {'Size':>7}")
    print(f"  {'─'*33} {'─'*12}   {'─'*7}   {'─'*7}")

    for table in tables:
        export_table(conn, table, EXPORTS_DIR)

    conn.close()
    print(f"\nParquet files saved to exports/")
    print(f"Import into Power BI: Get Data → Parquet")


if __name__ == "__main__":
    main()
