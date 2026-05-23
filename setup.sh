#!/usr/bin/env bash
# setup.sh — Build, load, materialize, and export.
#
# Tracks step durations in .step_timings after each run.
# On subsequent runs, shows projected time remaining per step.
# First run shows elapsed time only (no prior data to estimate from).

set -e

TIMINGS_FILE=".step_timings"

# ── Helpers ───────────────────────────────────────────────────────────────────

fmt() {
    # Format seconds as MM:SS
    printf "%02d:%02d" $(($1 / 60)) $(($1 % 60))
}

# ── Load timings from last run ────────────────────────────────────────────────

declare -A T
if [[ -f "$TIMINGS_FILE" ]]; then
    while IFS='=' read -r k v; do
        [[ -n "$k" ]] && T["$k"]=$v
    done < "$TIMINGS_FILE"
fi

# ── Decide which steps to run ─────────────────────────────────────────────────

STEP_KEYS=(build load marts)
python -c "import pyarrow" 2>/dev/null && STEP_KEYS+=(export)
TOTAL_STEPS=${#STEP_KEYS[@]}
CURRENT_STEP=0

# ── Remaining-time estimate from step index N onward ─────────────────────────

eta_from() {
    local from=$1 sum=0
    for i in "${!STEP_KEYS[@]}"; do
        [[ $i -ge $from ]] && sum=$((sum + ${T[${STEP_KEYS[$i]}]:-0}))
    done
    echo $sum
}

# ── Row count summary ────────────────────────────────────────────────────────

show_counts() {
    python - <<'PYEOF'
import sqlite3
conn = sqlite3.connect("contoso.db")
tables = [r[0] for r in conn.execute(
    "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
).fetchall()]

counts = []
total = 0
for t in tables:
    n = conn.execute(f"SELECT COUNT(*) FROM [{t}];").fetchone()[0]
    counts.append((t, n))
    total += n

print(f"\n  {'Table':<35} {'Rows':>12}   {'% of Total':>10}")
print(f"  {'─'*35} {'─'*12}   {'─'*10}")
for t, n in counts:
    pct = f"{n / total * 100:>9.1f}%" if total else "       n/a"
    print(f"  {t:<35} {n:>12,}   {pct}")
print(f"  {'─'*35} {'─'*12}   {'─'*10}")
print(f"  {'TOTAL':<35} {total:>12,}   {'100.0%':>10}")
conn.close()
PYEOF
}

# ── Step runner ───────────────────────────────────────────────────────────────

run_step() {
    local key=$1 label=$2
    shift 2
    CURRENT_STEP=$((CURRENT_STEP + 1))

    local remaining
    remaining=$(eta_from $((CURRENT_STEP - 1)))
    local eta=""
    [[ $remaining -gt 0 ]] && eta="  (~$(fmt $remaining) remaining)"

    echo ""
    printf "  ┌─ [%d/%d] %s%s\n" "$CURRENT_STEP" "$TOTAL_STEPS" "$label" "$eta"

    local t0
    t0=$(date +%s)
    "$@"
    local elapsed=$(( $(date +%s) - t0 ))

    T[$key]=$elapsed
    echo ""
    printf "  └─ done in %s\n" "$(fmt $elapsed)"
}

# ── Run ───────────────────────────────────────────────────────────────────────

TOTAL_START=$(date +%s)
echo "════════════════════════════════════════════════════════════════"
echo "  ContosoDW Setup"
echo "════════════════════════════════════════════════════════════════"

run_step build  "Building schema"             python build_db.py
run_step load   "Loading data from Kaggle"    python load_data.py
show_counts
run_step marts  "Building analytical tables"  bash -c "sqlite3 contoso.db < analysis/build_marts.sql"
show_counts

if python -c "import pyarrow" 2>/dev/null; then
    run_step export "Exporting to Parquet"    python scripts/export_for_powerbi.py
else
    echo ""
    echo "  [skipped] Parquet export — pyarrow not installed"
    echo "            pip install pyarrow && python scripts/export_for_powerbi.py"
fi

# ── Save timings for next run ─────────────────────────────────────────────────

{
    for k in "${!T[@]}"; do
        printf "%s=%s\n" "$k" "${T[$k]}"
    done
} > "$TIMINGS_FILE"

TOTAL=$(( $(date +%s) - TOTAL_START ))
echo ""
echo "════════════════════════════════════════════════════════════════"
printf "  All done — total time: %s\n" "$(fmt $TOTAL)"
echo "════════════════════════════════════════════════════════════════"
