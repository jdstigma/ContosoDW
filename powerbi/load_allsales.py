# Power BI Python Data Source — AllSales
#
# How to use:
#   1. In Power BI Desktop: Home → Get Data → More → Other → Python Script
#   2. Paste this script and click OK
#   3. Select the "dataset" table from the Navigator
#
# Requirements on your local machine:
#   pip install pandas
#
# The db path below assumes you cloned the repo to the default location.
# Update DB_PATH if yours differs.

import sqlite3
import pandas as pd

DB_PATH = r"C:\Users\jdsti\OneDrive\Desktop\Projects\ContosoDW\contoso.db"

conn    = sqlite3.connect(DB_PATH)
dataset = pd.read_sql_query("SELECT * FROM AllSales;", conn)
conn.close()
