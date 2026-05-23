"""
load_data.py
Downloads the Contoso retail CSV dataset from Kaggle and loads it into contoso.db.

── Setup ──────────────────────────────────────────────────────────────────────
1. Get a free Kaggle account at https://www.kaggle.com
2. Go to Account → Settings → API → Create New Token
   Kaggle will show a popup with your token (starts with KGAT_...).

3. Place credentials using ONE of these methods:

   A) File (local / Codespaces terminal):
      mkdir -p ~/.kaggle && echo YOUR_TOKEN > ~/.kaggle/access_token && chmod 600 ~/.kaggle/access_token

   B) Environment variable:
      export KAGGLE_API_TOKEN=YOUR_TOKEN

   C) Codespaces / GitHub Actions secret:
      Add KAGGLE_API_TOKEN as a repository secret under Settings → Secrets

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
    Resolve Kaggle credentials, supporting both the new single-token format
    (KGAT_... via KAGGLE_API_TOKEN env var or ~/.kaggle/access_token)
    and the legacy username+key format (kaggle.json / KAGGLE_USERNAME+KAGGLE_KEY).
    """
    creds_dir = os.path.expanduser("~/.kaggle")
    os.makedirs(creds_dir, exist_ok=True)

    access_token_file = os.path.join(creds_dir, "access_token")
    kaggle_json_file  = os.path.join(creds_dir, "kaggle.json")

    # ── New format: single KAGGLE_API_TOKEN ──────────────────────────────────
    api_token = os.environ.get("KAGGLE_API_TOKEN")
    if api_token:
        # Write to access_token file so the kaggle package picks it up
        with open(access_token_file, "w") as f:
            f.write(api_token.strip())
        os.chmod(access_token_file, 0o600)
        print("Kaggle credentials set from KAGGLE_API_TOKEN.")
        return

    if os.path.exists(access_token_file):
        print("Kaggle access_token file found.")
        return

    # ── Legacy format: username + key ────────────────────────────────────────
    if os.path.exists(kaggle_json_file):
        print("Kaggle kaggle.json file found.")
        return

    username = os.environ.get("KAGGLE_USERNAME")
    key      = os.environ.get("KAGGLE_KEY")
    if username and key:
        with open(kaggle_json_file, "w") as f:
            json.dump({"username": username, "key": key}, f)
        os.chmod(kaggle_json_file, 0o600)
        print("Kaggle credentials written from KAGGLE_USERNAME / KAGGLE_KEY.")
        return

    # ── Nothing found ────────────────────────────────────────────────────────
    print(
        "ERROR: Kaggle credentials not found.\n\n"
        "  Option A — save your token to a file:\n"
        "    mkdir -p ~/.kaggle\n"
        "    echo YOUR_KGAT_TOKEN > ~/.kaggle/access_token\n"
        "    chmod 600 ~/.kaggle/access_token\n\n"
        "  Option B — set an environment variable:\n"
        "    export KAGGLE_API_TOKEN=YOUR_KGAT_TOKEN\n\n"
        "  Get your token at: https://www.kaggle.com/settings → API"
    )
    sys.exit(1)


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


CHUNK_SIZE = 5_000  # rows per batch — keeps memory low for large Fact tables


def load_csv_into_table(conn, table_name, csv_path):
    """
    Stream a CSV file in chunks and insert into SQLite.
    Never loads the whole file into memory — safe for multi-million-row tables.
    Returns the total number of rows inserted.
    """
    with open(csv_path, newline="", encoding="utf-8-sig") as f:
        reader    = csv.DictReader(f)
        first_row = next(reader, None)

        if first_row is None:
            return 0

        # Build column mapping from CSV headers → DB column names (case-insensitive)
        db_cols  = get_db_columns(conn, table_name)
        col_map  = {
            h: db_cols[h.lower()]
            for h in first_row.keys()
            if h.lower() in db_cols
        }

        if not col_map:
            print(f"  WARNING  {table_name}: no matching columns — skipping")
            return 0

        db_col_list  = list(col_map.values())
        placeholders = ", ".join(["?"] * len(db_col_list))
        col_str      = ", ".join(f"[{c}]" for c in db_col_list)
        sql          = (
            f"INSERT OR IGNORE INTO [{table_name}] ({col_str}) VALUES ({placeholders})"
        )

        def row_to_values(row):
            return [row.get(h) or None for h in col_map]

        total = 0
        chunk = [row_to_values(first_row)]

        for row in reader:
            chunk.append(row_to_values(row))

            if len(chunk) >= CHUNK_SIZE:
                conn.executemany(sql, chunk)
                conn.commit()
                total += len(chunk)
                chunk  = []
                # Overwrite the current line with live progress
                print(f"  {table_name}: {total:>10,} rows...", end="\r", flush=True)

        # Insert any remaining rows
        if chunk:
            conn.executemany(sql, chunk)
            conn.commit()
            total += len(chunk)

    return total


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
                existing = conn.execute(
                    f"SELECT COUNT(*) FROM [{table_name}];"
                ).fetchone()[0]
                if existing > 0:
                    print(f"{table_name:<35} {existing:>10,}  (already loaded — skipped)")
                else:
                    count = load_csv_into_table(conn, table_name, csv_path)
                    print(f"{table_name:<35} {count:>10,}          ")

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
