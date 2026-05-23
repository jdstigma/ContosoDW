"""
load_data.py
Downloads the Contoso retail CSV dataset from Kaggle and loads into contoso.duckdb.

DuckDB's read_csv_auto loads each table in seconds using vectorised execution —
no schema definition required, no row-by-row inserts.

Usage:
    python load_data.py
    python load_data.py --dry-run

Kaggle credentials (any one of):
    export KAGGLE_API_TOKEN=KGAT_...
    echo YOUR_TOKEN > ~/.kaggle/access_token
"""

import json
import os
import subprocess
import sys
import tempfile
import time

DB_PATH   = "contoso.duckdb"
KAGGLE_DS = "bhanuthakurr/cleaned-contoso-dataset"
DRY_RUN   = "--dry-run" in sys.argv


# ── Dependencies ──────────────────────────────────────────────────────────────

def ensure_packages():
    for pkg in ["duckdb", "kaggle"]:
        try:
            __import__(pkg)
        except ImportError:
            print(f"Installing {pkg}...")
            subprocess.check_call(
                [sys.executable, "-m", "pip", "install", pkg, "-q"]
            )


# ── Kaggle credentials ────────────────────────────────────────────────────────

def setup_kaggle_credentials():
    creds_dir         = os.path.expanduser("~/.kaggle")
    access_token_file = os.path.join(creds_dir, "access_token")
    kaggle_json_file  = os.path.join(creds_dir, "kaggle.json")
    os.makedirs(creds_dir, exist_ok=True)

    api_token = os.environ.get("KAGGLE_API_TOKEN")
    if api_token:
        with open(access_token_file, "w") as f:
            f.write(api_token.strip())
        os.chmod(access_token_file, 0o600)
        print("Kaggle credentials set from KAGGLE_API_TOKEN.")
        return

    if os.path.exists(access_token_file) or os.path.exists(kaggle_json_file):
        print("Kaggle credentials found.")
        return

    username = os.environ.get("KAGGLE_USERNAME")
    key      = os.environ.get("KAGGLE_KEY")
    if username and key:
        with open(kaggle_json_file, "w") as f:
            json.dump({"username": username, "key": key}, f)
        os.chmod(kaggle_json_file, 0o600)
        print("Kaggle credentials written from env vars.")
        return

    print(
        "ERROR: Kaggle credentials not found.\n"
        "  export KAGGLE_API_TOKEN=your_token\n"
        "  Get your token at: https://www.kaggle.com/settings → API"
    )
    sys.exit(1)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    ensure_packages()
    import duckdb
    import kaggle

    setup_kaggle_credentials()

    with tempfile.TemporaryDirectory() as tmpdir:

        # Download CSVs
        kaggle.api.authenticate()
        print(f"Downloading: {KAGGLE_DS}\n")
        kaggle.api.dataset_download_files(KAGGLE_DS, path=tmpdir, unzip=True)

        csv_files = sorted(
            f for f in os.listdir(tmpdir) if f.lower().endswith(".csv")
        )

        if not csv_files:
            print("No CSV files found.")
            sys.exit(1)

        print(f"Found {len(csv_files)} CSV file(s).\n")

        if DRY_RUN:
            for f in csv_files:
                print(f"  {f}")
            return

        conn = duckdb.connect(DB_PATH)

        print(f"  {'Table':<33} {'Rows':>12}   {'Time':>7}")
        print(f"  {'─'*33} {'─'*12}   {'─'*7}")

        total_rows = 0

        for csv_file in csv_files:
            table = os.path.splitext(csv_file)[0]
            # DuckDB requires forward slashes in paths
            path  = os.path.join(tmpdir, csv_file).replace("\\", "/")

            t0 = time.time()
            conn.execute(f"""
                CREATE OR REPLACE TABLE "{table}" AS
                SELECT * FROM read_csv_auto(
                    '{path}',
                    header       = true,
                    ignore_errors = true
                )
            """)
            elapsed = time.time() - t0

            n = conn.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
            total_rows += n
            print(f"  {table:<33} {n:>12,}   {elapsed:>5.1f}s")

        print(f"  {'─'*33} {'─'*12}")
        print(f"  {'TOTAL':<33} {total_rows:>12,}")

        conn.close()
        print(f"\nDatabase: {DB_PATH}")


if __name__ == "__main__":
    main()
