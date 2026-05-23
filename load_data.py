"""
load_data.py
Downloads the Contoso retail CSV dataset from Kaggle and loads it into contoso.db.

── Setup ──────────────────────────────────────────────────────────────────────
1. Get a free Kaggle account at https://www.kaggle.com
2. Go to Account → Settings → API → Create New Token
   This downloads kaggle.json with your username and key.

3. Place credentials using ONE of these methods:

   A) File (local / Codespaces):
      Linux/Mac:  ~/.kaggle/kaggle.json
      Windows:    %USERPROFILE%\\.kaggle\\kaggle.json

   B) Environment variables (Codespaces secrets / CI):
      KAGGLE_USERNAME=your_username
      KAGGLE_KEY=your_api_key

── Usage ───────────────────────────────────────────────────────────────────────
    python load_data.py            # full load
    python load_data.py --dry-run  # show what would be loaded without inserting

── Source dataset ──────────────────────────────────────────────────────────────
    https://www.kaggle.com/datasets/bhanuthakurr/cleaned-contoso-dataset
"""

import csv
import json
import os
import sqlite3
import subprocess
import sys
import tempfile

DB_PATH      = "contoso.db"
KAGGLE_DS    = "bhanuthakurr/cleaned-contoso-dataset"
DRY_RUN      = "--dry-run" in sys.argv


# ── Helpers ──────────────────────────────────────────────────────────────────

def ensure_kaggle_package():
    """Install the kaggle package if not already present."""
    try:
        import kaggle  # noqa: F401
    except ImportError:
        print("kaggle package not found — installing...")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "kaggle", "-q"]
        )


def setup_kaggle_credentials():
    """
    Write kaggle.json from env vars if the file doesn't already exist.
    This lets Codespaces/CI pass credentials via repository secrets.
    """
    creds_dir  = os.path.expanduser("~/.kaggle")
    creds_file = os.path.join(creds_dir, "kaggle.json")

    if os.path.exists(creds_file):
        return  # already set up

    username = os.environ.get("KAGGLE_USERNAME")
    key      = os.environ.get("KAGGLE_KEY")

    if not username or not key:
        print(
            "ERROR: Kaggle credentials not found.\n"
            "  Option A — place kaggle.json at ~/.kaggle/kaggle.json\n"
            "  Option B — set KAGGLE_USERNAME and KAGGLE_KEY environment variables\n"
            "  Get your token at: https://www.kaggle.com/settings → API"
        )
        sys.exit(1)

    os.makedirs(creds_dir, exist_ok=True)
    with open(creds_file, "w") as f:
        json.dump({"username": username, "key": key}, f)
    os.chmod(creds_file, 0o600)
    print("Kaggle credentials written from environment variables.")


def download_dataset(dest_dir):
    import kaggle
    kaggle.api.authenticate()
    print(f"Downloading dataset: {KAGGLE_DS}")
    print("(This may take a moment...)\n")
    kaggle.api.dataset_download_files(KAGGLE_DS, path=dest_dir, unzip=True)


def get_db_tables(conn):
    """Return {lowercase_name: actual_name} for all tables in the db."""
    rows = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
    ).fetchall()
    return {row[0].lower(): row[0] for row in rows}


def get_db_columns(conn, table_name):
    """Return {lowercase_col: actual_col} for all columns in a table."""
    rows = conn.execute(f"PRAGMA table_info([{table_name}]);").fetchall()
    return {row[1].lower(): row[1] for row in rows}


def load_csv_into_table(conn, table_name, csv_path):
    """
    Insert all rows from a CSV file into a SQLite table.
    Column matching is case-insensitive.
    Returns the number of rows inserted.
    """
    with open(csv_path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        rows   = list(reader)

    if not rows:
        return 0

    db_cols    = get_db_columns(conn, table_name)
    csv_heads  = list(rows[0].keys())

    # Map CSV header → DB column name (case-insensitive)
    col_map = {h: db_cols[h.lower()] for h in csv_heads if h.lower() in db_cols}

    if not col_map:
        print(f"  WARNING  {table_name}: no matching columns — skipping")
        return 0

    db_col_list  = list(col_map.values())
    placeholders = ", ".join(["?"] * len(db_col_list))
    col_str      = ", ".join(f"[{c}]" for c in db_col_list)
    sql          = (
        f"INSERT OR IGNORE INTO [{table_name}] ({col_str}) VALUES ({placeholders})"
    )

    values = [
        [row.get(csv_h) or None for csv_h in col_map]
        for row in rows
    ]

    conn.executemany(sql, values)
    return len(rows)


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    if not os.path.exists(DB_PATH):
        print(f"ERROR: {DB_PATH} not found. Run build_db.py first.")
        sys.exit(1)

    ensure_kaggle_package()
    setup_kaggle_credentials()

    with tempfile.TemporaryDirectory() as tmpdir:
        download_dataset(tmpdir)

        csv_files = sorted(
            f for f in os.listdir(tmpdir) if f.lower().endswith(".csv")
        )

        if not csv_files:
            print("No CSV files found in the downloaded dataset.")
            sys.exit(1)

        print(f"Found {len(csv_files)} CSV file(s).\n")

        if DRY_RUN:
            print("DRY RUN — no data will be written.\n")

        conn = sqlite3.connect(DB_PATH)
        conn.execute("PRAGMA foreign_keys = OFF")   # skip FK checks during bulk load
        conn.execute("PRAGMA journal_mode = WAL")   # faster writes
        conn.execute("PRAGMA synchronous  = NORMAL")

        db_tables = get_db_tables(conn)

        loaded  = 0
        skipped = []

        print(f"{'Table':<35} {'Rows':>10}")
        print("─" * 47)

        for csv_file in csv_files:
            table_key = os.path.splitext(csv_file)[0].lower()

            if table_key not in db_tables:
                skipped.append(csv_file)
                continue

            table_name = db_tables[table_key]
            csv_path   = os.path.join(tmpdir, csv_file)

            if DRY_RUN:
                with open(csv_path, newline="", encoding="utf-8-sig") as f:
                    count = sum(1 for _ in f) - 1  # subtract header
                print(f"{table_name:<35} {count:>10,}  (dry run)")
            else:
                count = load_csv_into_table(conn, table_name, csv_path)
                print(f"{table_name:<35} {count:>10,}")

            loaded += 1

        if not DRY_RUN:
            conn.execute("PRAGMA foreign_keys = ON")
            conn.commit()

        conn.close()

        print("─" * 47)
        print(f"\n{loaded} table(s) loaded into {DB_PATH}")

        if skipped:
            print(f"\nSkipped (no matching table in schema):")
            for s in skipped:
                print(f"  {s}")


if __name__ == "__main__":
    main()
