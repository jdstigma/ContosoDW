"""
scripts/export_for_powerbi.py
Exports tables from contoso.db to Parquet files for import into Power BI.

Reads in chunks — safe on Codespaces with limited RAM.
Output lands in exports/ (gitignored).

Dependencies:
    pip install pyarrow

Usage:
    python scripts/export_for_powerbi.py               # export all default tables
    python scripts/export_for_powerbi.py --table AllSales
"""

import os
import sqlite3
import sys
from datetime import datetime

try:
    import pyarrow as pa
    import pyarrow.parquet as pq
except ImportError:
    print("ERROR: pyarrow not installed.\nRun: pip install pyarrow")
    sys.exit(1)

REPO_ROOT   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH     = os.path.join(REPO_ROOT, "contoso.db")
EXPORTS_DIR = os.path.join(REPO_ROOT, "exports")
CHUNK_SIZE  = 50_000

# Tables exported by default — add more as needed
DEFAULT_TABLES = [
    "AllSales",
    "DimDate",
]


def export_table(conn, table, out_dir, chunk_size=CHUNK_SIZE):
    out_path = os.path.join(out_dir, f"{table}.parquet")

    # Fetch column names
    cursor = conn.execute(f"SELECT * FROM [{table}] LIMIT 0;")
    col_names = [d[0] for d in cursor.description]

    writer = None
    offset = 0
    total  = 0

    while True:
        rows = conn.execute(
            f"SELECT * FROM [{table}] LIMIT {chunk_size} OFFSET {offset};"
        ).fetchall()
        if not rows:
            break

        # Build columnar dict for pyarrow
        columns = {col: [row[i] for row in rows] for i, col in enumerate(col_names)}
        batch   = pa.Table.from_pydict(columns)

        if writer is None:
            writer = pq.ParquetWriter(out_path, batch.schema, compression="snappy")
        writer.write_table(batch)

        offset += len(rows)
        total  += len(rows)
        print(f"  {table}: {total:>10,} rows...", end="\r", flush=True)

        if len(rows) < chunk_size:
            break

    if writer:
        writer.close()

    size_mb = os.path.getsize(out_path) / 1_048_576
    print(f"  {table}: {total:>10,} rows → {table}.parquet  ({size_mb:.1f} MB)")
    return total


def main():
    if not os.path.exists(DB_PATH):
        print(f"ERROR: {DB_PATH} not found. Run ./setup.sh first.")
        sys.exit(1)

    # Check AllSales exists
    conn = sqlite3.connect(DB_PATH)
    tables_in_db = [
        r[0] for r in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
        ).fetchall()
    ]

    # Parse --table flag
    if "--table" in sys.argv:
        idx = sys.argv.index("--table")
        tables = [sys.argv[idx + 1]] if idx + 1 < len(sys.argv) else DEFAULT_TABLES
    else:
        tables = DEFAULT_TABLES

    missing = [t for t in tables if t not in tables_in_db]
    if missing:
        print(f"ERROR: Table(s) not found in db: {', '.join(missing)}")
        print(f"       Run ./setup.sh to build AllSales first.")
        sys.exit(1)

    os.makedirs(EXPORTS_DIR, exist_ok=True)
    print(f"Exporting to exports/  [{datetime.now().strftime('%H:%M:%S')}]\n")

    for table in tables:
        export_table(conn, table, EXPORTS_DIR)

    conn.close()
    print(f"\nDone. Download the files from exports/ and import into Power BI:")
    for t in tables:
        print(f"  exports/{t}.parquet")


if __name__ == "__main__":
    main()
