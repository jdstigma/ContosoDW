"""
profiling/profile_data.py
Data profiling for contoso.db using pandas and SQLAlchemy.

Produces per-table summaries covering:
  - Row & column counts
  - Null counts and percentages per column
  - Distinct value counts per column
  - Numeric stats (min, max, mean, std)
  - Date range (min, max) for date-like columns
  - Top 5 most frequent values for low-cardinality text columns

Output saved to: profiling/reports/profile_YYYYMMDD_HHMMSS.txt

Usage (run from repo root):
    pip install pandas sqlalchemy
    python profiling/profile_data.py
    python profiling/profile_data.py --table DimCustomer   # one table only
    python profiling/profile_data.py --summary             # row/col counts only
"""

import os
import sys
from datetime import datetime

# Resolve paths relative to repo root (one level up from this script)
REPO_ROOT   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH     = os.path.join(REPO_ROOT, "contoso.db")
REPORTS_DIR = os.path.join(REPO_ROOT, "profiling", "reports")

FREQ_CARD_LIMIT = 50   # max distinct values before skipping top-N
TOP_N           = 5    # number of top values to show


# ── Package check ─────────────────────────────────────────────────────────────

def ensure_packages():
    import subprocess
    for pkg in ("pandas", "sqlalchemy"):
        try:
            __import__(pkg)
        except ImportError:
            print(f"Installing {pkg}...")
            subprocess.check_call(
                [sys.executable, "-m", "pip", "install", pkg, "-q"]
            )

ensure_packages()

import pandas as pd
from sqlalchemy import create_engine, inspect


# ── Formatting helpers ────────────────────────────────────────────────────────

def divider(char="─", width=72):
    return char * width

def section(title):
    return f"\n{divider('═')}\n  {title}\n{divider('═')}"

def is_date_col(series):
    if "date" not in series.name.lower():
        return False
    sample = series.dropna().head(20)
    try:
        pd.to_datetime(sample)
        return True
    except Exception:
        return False


# ── Per-table profiler ────────────────────────────────────────────────────────

def profile_table(engine, table_name):
    lines = []

    with engine.connect() as conn:
        df = pd.read_sql_table(table_name, conn)

    n_rows, n_cols = df.shape
    lines.append(f"\n{divider()}")
    lines.append(f"  TABLE: {table_name}   ({n_rows:,} rows  ×  {n_cols} columns)")
    lines.append(divider())

    if n_rows == 0:
        lines.append("  [empty table — no further profiling]")
        return "\n".join(lines)

    # ── Column overview ───────────────────────────────────────────────────────
    lines.append(
        f"\n  {'Column':<35} {'Type':<10} {'Nulls':>8}  {'%Null':>6}  {'Distinct':>9}"
    )
    lines.append(f"  {'─'*35} {'─'*10} {'─'*8}  {'─'*6}  {'─'*9}")

    col_details = []
    for col in df.columns:
        series   = df[col]
        dtype    = str(series.dtype)
        nulls    = int(series.isna().sum())
        distinct = int(series.nunique(dropna=True))
        pct      = f"{nulls / n_rows * 100:5.1f}%" if n_rows else "  n/a"
        lines.append(
            f"  {col:<35} {dtype:<10} {nulls:>8,}  {pct:>6}  {distinct:>9,}"
        )
        col_details.append((col, series, dtype, nulls, distinct))

    # ── Numeric statistics ────────────────────────────────────────────────────
    num_cols = df.select_dtypes(include="number").columns.tolist()
    if num_cols:
        lines.append(f"\n  {'── Numeric statistics ':-<70}")
        stats = df[num_cols].describe().T[["min", "mean", "max", "std"]].round(2)
        lines.append(
            f"\n  {'Column':<35} {'Min':>12} {'Mean':>12} {'Max':>12} {'Std':>12}"
        )
        lines.append(f"  {'─'*35} {'─'*12} {'─'*12} {'─'*12} {'─'*12}")
        for col, row in stats.iterrows():
            lines.append(
                f"  {col:<35} {row['min']:>12,.2f} {row['mean']:>12,.2f} "
                f"{row['max']:>12,.2f} {row['std']:>12,.2f}"
            )

    # ── Date ranges ───────────────────────────────────────────────────────────
    date_cols = [
        col for col, s, dtype, _, _ in col_details
        if dtype == "object" and is_date_col(s)
    ]
    if date_cols:
        lines.append(f"\n  {'── Date ranges ':-<70}")
        lines.append(f"\n  {'Column':<35} {'Min':<26} {'Max':<26}")
        lines.append(f"  {'─'*35} {'─'*26} {'─'*26}")
        for col in date_cols:
            parsed = pd.to_datetime(df[col], errors="coerce")
            lines.append(
                f"  {col:<35} {str(parsed.min()):<26} {str(parsed.max()):<26}"
            )

    # ── Top-N frequencies (low-cardinality text) ──────────────────────────────
    text_cols = [
        (col, s) for col, s, dtype, _, distinct in col_details
        if dtype == "object"
        and 1 < distinct <= FREQ_CARD_LIMIT
        and col not in date_cols
    ]
    if text_cols:
        lines.append(f"\n  {'── Top {TOP_N} values (low-cardinality columns) ':-<70}")
        for col, s in text_cols:
            top = s.value_counts().head(TOP_N)
            lines.append(f"\n  {col}:")
            for val, cnt in top.items():
                bar = "█" * min(int(cnt / n_rows * 40), 40)
                lines.append(f"    {str(val):<30} {cnt:>8,}  {bar}")

    return "\n".join(lines)


# ── Summary table ─────────────────────────────────────────────────────────────

def summary_table(engine, tables):
    lines = [
        "",
        f"  {'Table':<35} {'Rows':>10} {'Columns':>8}",
        f"  {'─'*35} {'─'*10} {'─'*8}",
    ]
    total_rows = 0
    with engine.connect() as conn:
        for t in tables:
            df         = pd.read_sql_table(t, conn)
            rows, cols = df.shape
            total_rows += rows
            lines.append(f"  {t:<35} {rows:>10,} {cols:>8}")
    lines.append(f"  {'─'*35} {'─'*10} {'─'*8}")
    lines.append(f"  {'TOTAL':<35} {total_rows:>10,}")
    return "\n".join(lines)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    if not os.path.exists(DB_PATH):
        print(f"ERROR: {DB_PATH} not found. Run build_db.py first.")
        sys.exit(1)

    engine      = create_engine(f"sqlite:///{DB_PATH}")
    inspector   = inspect(engine)
    all_tables  = sorted(inspector.get_table_names())

    # Parse args
    summary_only = "--summary" in sys.argv
    target_table = None
    if "--table" in sys.argv:
        idx = sys.argv.index("--table")
        if idx + 1 < len(sys.argv):
            target_table = sys.argv[idx + 1]
            if target_table not in all_tables:
                print(f"ERROR: Table '{target_table}' not found.")
                print(f"Available tables: {', '.join(all_tables)}")
                sys.exit(1)

    tables_to_profile = [target_table] if target_table else all_tables
    timestamp         = datetime.now().strftime("%Y%m%d_%H%M%S")

    # Build report
    output = []
    output.append(section(
        f"ContosoRetailDW — Data Profile Report\n"
        f"  Generated : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
        f"  Database  : {DB_PATH}\n"
        f"  Tables    : {len(all_tables)}"
    ))

    output.append(section("SUMMARY — Row & Column Counts"))
    output.append(summary_table(engine, all_tables))

    if not summary_only:
        output.append(section("DETAILED COLUMN PROFILES"))
        for i, table in enumerate(tables_to_profile, 1):
            print(f"  Profiling {table} ({i}/{len(tables_to_profile)})...", end="\r")
            output.append(profile_table(engine, table))
        print(" " * 60, end="\r")

    report = "\n".join(output) + "\n"

    # Print to console
    print(report)

    # Save report to profiling/reports/
    if not target_table:
        report_name = f"profile_{timestamp}.txt"
    else:
        report_name = f"profile_{target_table}_{timestamp}.txt"

    os.makedirs(REPORTS_DIR, exist_ok=True)
    report_path = os.path.join(REPORTS_DIR, report_name)
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(report)
    print(f"Report saved to: profiling/reports/{report_name}")


if __name__ == "__main__":
    main()
