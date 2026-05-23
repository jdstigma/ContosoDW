"""
build_db.py
Generates contoso.db (SQLite) from schema_sqlite.sql.

Usage (in GitHub Codespaces or locally):
    python build_db.py

No external dependencies — uses Python's built-in sqlite3 module.
"""

import sqlite3
import os
import sys

DB_PATH      = "contoso.db"
SCHEMA_PATH  = "schema_sqlite.sql"
INDEXES_PATH = "indexes_sqlite.sql"


def build_db():
    base = os.path.dirname(os.path.abspath(__file__))
    schema_path = os.path.join(base, SCHEMA_PATH)
    db_path     = os.path.join(base, DB_PATH)

    if not os.path.exists(schema_path):
        print(f"ERROR: {SCHEMA_PATH} not found.")
        sys.exit(1)

    indexes_path = os.path.join(base, INDEXES_PATH)

    if os.path.exists(db_path):
        os.remove(db_path)
        print(f"Removed existing {DB_PATH}")

    with open(schema_path, "r") as f:
        schema = f.read()

    with open(indexes_path, "r") as f:
        indexes = f.read()

    conn = sqlite3.connect(db_path)
    try:
        print("Creating tables...")
        conn.executescript(schema)
        conn.commit()
        print("Creating indexes...")
        conn.executescript(indexes)
        conn.commit()
        print(f"Created {DB_PATH} successfully.\n")
    except sqlite3.Error as e:
        conn.close()
        os.remove(db_path)
        print(f"ERROR: {e}")
        sys.exit(1)

    # Verify — list every table and its row count
    cursor = conn.cursor()
    cursor.execute(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
    )
    tables = [row[0] for row in cursor.fetchall()]

    print(f"{'Table':<35} {'Rows':>6}")
    print("-" * 43)
    for table in tables:
        cursor.execute(f"SELECT COUNT(*) FROM [{table}];")
        count = cursor.fetchone()[0]
        print(f"{table:<35} {count:>6}")

    conn.close()
    print(f"\nDone. Open with:  sqlite3 {DB_PATH}")
    print(f"Or in Python:     conn = sqlite3.connect('{DB_PATH}')")


if __name__ == "__main__":
    build_db()
