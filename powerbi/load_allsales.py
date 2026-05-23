# Power BI Python Data Source — AllSales (DuckDB)
#
# How to use:
#   1. Power BI Desktop: Home → Get Data → Other → Python Script
#   2. Paste this script and click OK
#   3. Select the "dataset" table from the Navigator
#
# Requirements:
#   pip install duckdb
#
# Update DB_PATH if your repo is in a different location.

import duckdb
import pandas as pd

DB_PATH = r"C:\Users\jdsti\OneDrive\Desktop\Projects\ContosoDW\contoso.duckdb"

conn    = duckdb.connect(DB_PATH, read_only=True)
dataset = conn.execute("SELECT * FROM AllSales").df()
conn.close()
