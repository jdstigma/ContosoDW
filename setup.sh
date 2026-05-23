#!/usr/bin/env bash
# setup.sh — Build the schema then load data.
# load_data.py only runs if build_db.py succeeds.

set -e

echo "=== Building schema ==="
python build_db.py

echo ""
echo "=== Loading data ==="
python load_data.py

echo ""
echo "=== Building analytical tables ==="
sqlite3 contoso.db < analysis/build_marts.sql

echo ""
echo "=== Done ==="
