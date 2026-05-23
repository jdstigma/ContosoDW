#!/usr/bin/env bash
# setup.sh — Load data into DuckDB, build AllSales mart, export to Parquet.
#
# Smart step skipping: each step is skipped if its output already exists.
# Use --force to rebuild everything from scratch.
#
# Tracks step durations in .step_timings after each run.
# On subsequent runs, shows projected time remaining per step.

set -e

TIMINGS_FILE=".step_timings"
FORCE=false
[[ "${1:-}" == "--force" ]] && FORCE=true

# ── Helpers ───────────────────────────────────────────────────────────────────

fmt() {
    if [[ $1 -lt 60 ]]; then
        printf "%ds" "$1"
    else
        printf "%dm %ds" $(($1 / 60)) $(($1 % 60))
    fi
}

row_count() {
    python -c "
import sys
try:
    import duckdb
    conn = duckdb.connect('contoso.duckdb', read_only=True)
    n = conn.execute('SELECT COUNT(*) FROM \"${1}\"').fetchone()[0]
    conn.close()
    print(n)
except:
    print(0)
" 2>/dev/null
}

# ── Load timings from last run ────────────────────────────────────────────────

declare -A T
if [[ -f "$TIMINGS_FILE" ]]; then
    while IFS='=' read -r k v; do
        [[ -n "$k" ]] && T["$k"]=$v
    done < "$TIMINGS_FILE"
fi

# ── Steps ─────────────────────────────────────────────────────────────────────

STEP_KEYS=(load marts export)
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

# ── Row count summary ─────────────────────────────────────────────────────────

show_counts() {
    python - <<'PYEOF'
import duckdb
conn = duckdb.connect("contoso.duckdb", read_only=True)
tables = [r[0] for r in conn.execute(
    "SELECT table_name FROM information_schema.tables WHERE table_schema='main' ORDER BY table_name;"
).fetchall()]

counts = []
total = 0
for t in tables:
    n = conn.execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0]
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

skip_step() {
    local key=$1 label=$2 reason=$3
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    printf "  ─── [%d/%d] %s — skipped (%s)\n" \
        "$CURRENT_STEP" "$TOTAL_STEPS" "$label" "$reason"
}

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

    # Background timer — shows elapsed every 10s for silent steps
    (
        while true; do
            sleep 10
            elapsed=$(( $(date +%s) - t0 ))
            printf "\r  ⏱  %s elapsed..." "$(fmt $elapsed)"
        done
    ) &
    local TIMER_PID=$!

    "$@"

    kill $TIMER_PID 2>/dev/null
    wait $TIMER_PID 2>/dev/null || true
    local elapsed=$(( $(date +%s) - t0 ))

    T[$key]=$elapsed
    echo ""
    printf "  └─ done in %s\n" "$(fmt $elapsed)"
}

# ── Run ───────────────────────────────────────────────────────────────────────

TOTAL_START=$(date +%s)
echo "════════════════════════════════════════════════════════════════"
echo "  ContosoDW Setup${FORCE:+  [--force]}"
echo "════════════════════════════════════════════════════════════════"

# Step 1 — Load data
FACT_ROWS=$(row_count FactSales)
if $FORCE || [[ $FACT_ROWS -eq 0 ]]; then
    run_step load "Loading data from Kaggle" python load_data.py
    show_counts
else
    skip_step load "Loading data from Kaggle" "FactSales has ${FACT_ROWS} rows"
fi

# Step 2 — Build marts
MART_ROWS=$(row_count AllSales)
if $FORCE || [[ $MART_ROWS -eq 0 ]]; then
    run_step marts "Building AllSales mart" python -c "
import duckdb
conn = duckdb.connect('contoso.duckdb')
conn.execute(open('analysis/build_marts.sql').read())
conn.close()
"
    show_counts
else
    skip_step marts "Building AllSales mart" "AllSales has ${MART_ROWS} rows"
fi

# Step 3 — Export to Parquet
run_step export "Exporting to Parquet" python scripts/export_for_powerbi.py

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
