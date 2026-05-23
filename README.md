# ContosoDW

A SQLite port of the Microsoft **Contoso Retail Data Warehouse** — a classic star-schema DW sample covering sales, inventory, customers, products, stores, and IT operations across multiple channels and geographies.

Built for local development and GitHub Codespaces. No SQL Server required.

---

## Data Source

**Dataset:** [Cleaned Contoso Dataset](https://www.kaggle.com/datasets/bhanuthakurr/cleaned-contoso-dataset) via Kaggle  
**Original:** Microsoft AdventureWorks / ContosoRetailDW sample  
**Tables:** 27 (14 dimension, 8 fact, 5 supporting)  
**Rows:** ~4.7 million across all tables

---

## Schema Overview

### Dimension Tables
| Table | Description |
|---|---|
| DimAccount | Chart of accounts for financial reporting |
| DimChannel | Sales channels (store, online, catalog, reseller) |
| DimCurrency | Currencies with labels and descriptions |
| DimCustomer | Customer demographics and geography |
| DimDate | Full calendar and fiscal date spine |
| DimEmployee | Employee records with department and sales flags |
| DimEntity | Business entities for strategy planning |
| DimGeography | Country, region, continent hierarchy |
| DimMachine | IT machines assigned to stores |
| DimOutage | IT outage type classifications |
| DimProduct | Product details, cost, price, color, weight |
| DimProductCategory | Top-level product category |
| DimProductSubcategory | Mid-level product subcategory |
| DimPromotion | Promotion types, discounts, and date ranges |
| DimSalesTerritory | Sales territory hierarchy |
| DimScenario | Budget/actual/forecast scenario labels |
| DimStore | Store details, size, open/close dates |

### Fact Tables
| Table | Description |
|---|---|
| FactExchangeRate | Daily currency exchange rates |
| FactInventory | Daily inventory on-hand by store and product |
| FactITMachine | Machine cost and downtime metrics |
| FactITSLA | IT service level agreement tracking |
| FactOnlineSales | Online channel transactions |
| FactSales | In-store sales transactions |
| FactSalesQuota | Sales quota targets by store/channel/product |
| FactStrategyPlan | Strategic plan financials by entity and account |

---

## Project Structure

```
ContosoDW/
├── schema_sqlite.sql       # SQLite schema (converted from T-SQL)
├── indexes_sqlite.sql      # 47 performance indexes (FK + filter columns)
├── build_db.py             # Creates contoso.db from schema + indexes
├── load_data.py            # Downloads CSVs from Kaggle and loads all tables
├── setup.sh                # Runs build_db.py then load_data.py sequentially
├── contosodbo.sql          # Original T-SQL source schema (reference only)
├── profiling/
│   ├── profile_data.py     # SQL-based data profiler (zero memory overhead)
│   └── reports/            # Timestamped profile reports (.gitignored)
└── .github/workflows/
    └── build_db.yml        # CI: validates schema builds cleanly on push
```

> `contoso.db` is excluded from git — it is built locally via `setup.sh`.

---

## Setup

### Requirements
- Python 3.x (no external dependencies for schema build)
- A Kaggle account with an API token (for data loading)

### Quickstart

```bash
# Clone and open in Codespaces or locally
git clone https://github.com/jdstigma/ContosoDW.git
cd ContosoDW

# Set your Kaggle token
export KAGGLE_API_TOKEN=your_token_here

# Build schema and load all data (~4.7M rows)
chmod +x setup.sh
./setup.sh
```

### Kaggle Token
Generate a token at [kaggle.com/settings](https://www.kaggle.com/settings) → API → Create New Token.  
Export it before running `setup.sh`:
```bash
export KAGGLE_API_TOKEN=KGAT_xxxxxxxxxxxx
```

---

## Data Profiling

Generates per-table column stats (nulls, distinct counts, min/max/avg, date ranges, top-5 frequencies) using SQL aggregations only — safe on large Fact tables.

```bash
python profiling/profile_data.py                  # full profile, saves report
python profiling/profile_data.py --summary        # row/column counts only
python profiling/profile_data.py --table FactSales  # single table
```

Reports are saved to `profiling/reports/profile_YYYYMMDD_HHMMSS.txt`.

---

## Roadmap

- [ ] SQL analysis queries (sales trends, customer segments, quota vs actuals)
- [ ] Jupyter notebooks with visualizations
- [ ] dbt transformation models (staging → marts)
