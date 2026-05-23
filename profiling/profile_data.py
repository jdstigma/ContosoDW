"""
profiling/profile_data.py
Data profiling for contoso.duckdb — SQL-based, zero memory overhead.

All stats are computed inside DuckDB (no full table loads into pandas).
Safe to run against tables with millions of rows.

Produces per-table summaries:
  - Row & column counts
  - Null count and % per column
  - Distinct value count per column
  - Min / Max / Avg for numeric columns
  - Min / Max for date-like columns
  - Top-5 most frequent values for low-cardinality columns

Output saved to: profiling/reports/profile_YYYYMMDD_HHMMSS.txt

Usage (run from repo root):
    python profiling/profile_data.py
    python profiling/profile_data.py --summary             # row/col counts only
    python profiling/profile_data.py --table DimCustomer   # single table
"""

import os
import sys
from datetime import datetime

try:
    import duckdb
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "duckdb", "-q"])
    import duckdb

REPO_ROOT   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH     = os.path.join(REPO_ROOT, "contoso.duckdb")
REPORTS_DIR = os.path.join(REPO_ROOT, "profiling", "reports")

FREQ_CARD_LIMIT = 50   # max distinct values before skipping top-N frequency
TOP_N           = 5    # number of top values to show


# ── Formatting ────────────────────────────────────────────────────────────────

W = 74

def rule(char="─"): return char * W
def section(title):  return f"\n{rule('═')}\n  {title}\n{rule('═')}"


# ── Schema introspection ──────────────────────────────────────────────────────

def get_tables(conn):
    rows = conn.execute(
        "SELECT table_name FROM information_schema.tables "
        "WHERE table_schema = 'main' ORDER BY table_name;"
    ).fetchall()
    return [r[0] for r in rows]


def get_columns(conn, table):
    """Return list of (col_name, col_type) for a table."""
    rows = conn.execute(f'DESCRIBE "{table}";').fetchall()
    # DESCRIBE returns: column_name, column_type, null, key, default, extra
    return [(r[0], r[1].upper()) for r in rows]


# ── SQL-based per-column stats ────────────────────────────────────────────────

def row_count(conn, table):
    return conn.execute(f'SELECT COUNT(*) FROM "{table}";').fetchone()[0]


def col_stats(conn, table, col, n_rows):
    """Null count, distinct count — always safe regardless of row count."""
    null_count = conn.execute(
        f'SELECT COUNT(*) FROM "{table}" WHERE "{col}" IS NULL;'
    ).fetchone()[0]

    distinct = conn.execute(
        f'SELECT COUNT(DISTINCT "{col}") FROM "{table}";'
    ).fetchone()[0]

    null_pct = f"{null_count / n_rows * 100:5.1f}%" if n_rows else "  n/a"
    return null_count, null_pct, distinct


def numeric_stats(conn, table, col):
    """Min, max, avg for a numeric column."""
    row = conn.execute(
        f'SELECT MIN("{col}"), MAX("{col}"), AVG("{col}") FROM "{table}";'
    ).fetchone()
    return row  # (min, max, avg)


def date_range(conn, table, col):
    """Min and max for a date-like column."""
    row = conn.execute(
        f'SELECT MIN("{col}"), MAX("{col}") FROM "{table}";'
    ).fetchone()
    return row  # (min, max)


def top_values(conn, table, col, n=TOP_N):
    """Top-N most frequent non-null values."""
    rows = conn.execute(
        f"""
        SELECT "{col}", COUNT(*) AS cnt
        FROM "{table}"
        WHERE "{col}" IS NOT NULL
        GROUP BY "{col}"
        ORDER BY cnt DESC
        LIMIT {n};
        """
    ).fetchall()
    return rows  # [(value, count), ...]


# ── Type helpers ──────────────────────────────────────────────────────────────

NUMERIC_TYPES = ("INT", "BIGINT", "HUGEINT", "SMALLINT", "TINYINT",
                 "FLOAT", "DOUBLE", "DECIMAL", "REAL", "NUMERIC")

DATE_TYPES = ("DATE", "TIMESTAMP", "TIME")


def is_numeric(col_type):
    return any(t in col_type for t in NUMERIC_TYPES)


def is_date(col_type):
    return any(t in col_type for t in DATE_TYPES)


def is_date_name(col_name):
    return "date" in col_name.lower() or "time" in col_name.lower()


# ── Per-table profiler ────────────────────────────────────────────────────────

def profile_table(conn, table):
    lines = []
    columns = get_columns(conn, table)
    n_rows  = row_count(conn, table)

    lines.append(f"\n{rule()}")
    lines.append(f"  TABLE: {table}   ({n_rows:,} rows  ×  {len(columns)} columns)")
    lines.append(rule())

    if n_rows == 0:
        lines.append("  [empty table — no further profiling]")
        return "\n".join(lines)

    # ── Column overview ───────────────────────────────────────────────────────
    lines.append(
        f"\n  {'Column':<35} {'DuckDB Type':<14} {'Nulls':>8}  {'%Null':>6}  {'Distinct':>9}"
    )
    lines.append(f"  {'─'*35} {'─'*14} {'─'*8}  {'─'*6}  {'─'*9}")

    num_cols  = []
    date_cols = []
    text_cols = []

    for col, ctype in columns:
        null_count, null_pct, distinct = col_stats(conn, table, col, n_rows)
        lines.append(
            f"  {col:<35} {ctype:<14} {null_count:>8,}  {null_pct:>6}  {distinct:>9,}"
        )
        if is_numeric(ctype):
            num_cols.append(col)
        elif is_date(ctype) or (is_date_name(col) and "VARCHAR" in ctype):
            date_cols.append(col)
        elif 1 < distinct <= FREQ_CARD_LIMIT:
            text_cols.append((col, distinct))

    # ── Numeric statistics ────────────────────────────────────────────────────
    if num_cols:
        lines.append(f"\n  {'── Numeric statistics ':-<{W-2}}")
        lines.append(
            f"\n  {'Column':<35} {'Min':>14} {'Avg':>14} {'Max':>14}"
        )
        lines.append(f"  {'─'*35} {'─'*14} {'─'*14} {'─'*14}")
        for col in num_cols:
            mn, mx, avg = numeric_stats(conn, table, col)
            mn  = f"{mn:,.2f}"  if mn  is not None else "NULL"
            mx  = f"{mx:,.2f}"  if mx  is not None else "NULL"
            avg = f"{avg:,.2f}" if avg is not None else "NULL"
            lines.append(f"  {col:<35} {mn:>14} {avg:>14} {mx:>14}")

    # ── Date ranges ───────────────────────────────────────────────────────────
    if date_cols:
        lines.append(f"\n  {'── Date ranges ':-<{W-2}}")
        lines.append(f"\n  {'Column':<35} {'Min':<26} {'Max':<26}")
        lines.append(f"  {'─'*35} {'─'*26} {'─'*26}")
        for col in date_cols:
            mn, mx = date_range(conn, table, col)
            lines.append(f"  {col:<35} {str(mn):<26} {str(mx):<26}")

    # ── Top-N frequencies ─────────────────────────────────────────────────────
    if text_cols:
        lines.append(f"\n  {'── Top ' + str(TOP_N) + ' values (low-cardinality columns) ':-<{W-2}}")
        for col, _ in text_cols:
            top = top_values(conn, table, col)
            if not top:
                continue
            lines.append(f"\n  {col}:")
            for val, cnt in top:
                bar = "█" * min(int(cnt / n_rows * 40), 40)
                lines.append(f"    {str(val):<30} {cnt:>8,}  {bar}")

    return "\n".join(lines)


# ── Summary table ─────────────────────────────────────────────────────────────

def summary_table(conn, tables):
    lines = [
        "",
        f"  {'Table':<35} {'Rows':>10} {'Columns':>8}",
        f"  {'─'*35} {'─'*10} {'─'*8}",
    ]
    total = 0
    for t in tables:
        cols = get_columns(conn, t)
        rows = row_count(conn, t)
        total += rows
        lines.append(f"  {t:<35} {rows:>10,} {len(cols):>8}")
    lines.append(f"  {'─'*35} {'─'*10} {'─'*8}")
    lines.append(f"  {'TOTAL':<35} {total:>10,}")
    return "\n".join(lines)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    if not os.path.exists(DB_PATH):
        print(f"ERROR: {DB_PATH} not found. Run ./setup.sh first.")
        sys.exit(1)

    conn       = duckdb.connect(DB_PATH, read_only=True)
    all_tables = get_tables(conn)

    # Parse args
    summary_only = "--summary" in sys.argv
    target_table = None
    if "--table" in sys.argv:
        idx = sys.argv.index("--table")
        if idx + 1 < len(sys.argv):
            target_table = sys.argv[idx + 1]
            if target_table not in all_tables:
                print(f"ERROR: Table '{target_table}' not found.")
                print(f"Available: {', '.join(all_tables)}")
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
    output.append(summary_table(conn, all_tables))

    if not summary_only:
        output.append(section("DETAILED COLUMN PROFILES"))
        for i, table in enumerate(tables_to_profile, 1):
            print(f"  Profiling {table} ({i}/{len(tables_to_profile)})...", end="\r", flush=True)
            output.append(profile_table(conn, table))
        print(" " * 60, end="\r")

    conn.close()

    report = "\n".join(output) + "\n"
    print(report)

    # Save to file (full runs only)
    if not target_table:
        os.makedirs(REPORTS_DIR, exist_ok=True)
        name = f"profile_{timestamp}.txt"
        path = os.path.join(REPORTS_DIR, name)
        with open(path, "w", encoding="utf-8") as f:
            f.write(report)
        print(f"Report saved to: profiling/reports/{name}")


if __name__ == "__main__":
    main()
