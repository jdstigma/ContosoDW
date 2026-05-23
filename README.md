# ContosoDW

A local data warehouse built on the [Microsoft Contoso Retail dataset](https://www.kaggle.com/datasets/danofer/contoso-retail-dataset), powered by **DuckDB** for fast analytical queries and Parquet export for Power BI.

---

## What's in the box

| Layer | Description |
|---|---|
| `load_data.py` | Downloads CSVs from Kaggle and loads them into `contoso.duckdb` via `read_csv_auto` |
| `analysis/build_marts.sql` | Materializes `AllSales` — FactSales + FactOnlineSales fully de-normalised across all dimensions |
| `scripts/export_for_powerbi.py` | Exports `AllSales` (and `DimDate`) to Snappy-compressed Parquet in `exports/` |
| `notebooks/` | Jupyter notebooks for data profiling and sales analysis |
| `powerbi/load_allsales.py` | Python script for connecting Power BI directly to `contoso.duckdb` |
| `profiling/profile_data.py` | SQL-based data profiler — null counts, distinct values, numeric ranges, top-N frequencies |

---

## Quick start

### Prerequisites

```bash
pip install duckdb pandas matplotlib kaggle
```

Set your Kaggle credentials (required for the data download):

```bash
export KAGGLE_API_TOKEN="your_token_here"   # Linux / macOS / Codespaces
$env:KAGGLE_API_TOKEN="your_token_here"     # Windows PowerShell
```

### Run the full pipeline

```bash
./setup.sh
```

This runs three steps in sequence, skipping any step whose output already exists:

```
[1/3] Loading data from Kaggle       ~83s    34M rows across 20 tables
[2/3] Building AllSales mart         ~5 min  16M rows, all dimensions joined
[3/3] Exporting to Parquet           ~60s    exports/AllSales.parquet
```

Use `--force` to rebuild everything from scratch:

```bash
./setup.sh --force
```

---

## Data model

### Source tables (loaded from Kaggle CSVs)

| Table | Rows | Description |
|---|---|---|
| `FactSales` | ~3.4M | In-store / catalog / reseller transactions |
| `FactOnlineSales` | ~12.6M | Online transactions |
| `FactInventory` | ~18M | Inventory snapshots |
| `DimProduct` | ~2.5K | Products with subcategory / category hierarchy |
| `DimStore` | ~306 | Store locations and attributes |
| `DimCustomer` | ~19K | Online customer demographics |
| `DimDate` | ~3.65K | Calendar and fiscal date attributes |
| `DimGeography` | ~2.2K | City / state / country / continent |
| `DimChannel` | 4 | Store, Catalog, Online, Reseller |
| `DimPromotion` | ~26 | Promotion names, types, discount % |
| `DimCurrency` | ~14 | Currency codes and names |

### AllSales mart

`AllSales` merges both fact tables and joins every dimension in a single flat table. Key columns:

| Group | Columns |
|---|---|
| Identifiers | `SaleSource`, `SaleKey`, `SalesOrderNumber` |
| Date | `CalendarYear`, `CalendarQuarter`, `CalendarMonth`, `FiscalYear`, `FiscalQuarter` |
| Channel | `ChannelName` |
| Store | `StoreName`, `StoreType`, `StoreStatus`, `StoreCity`, `StoreCountry` |
| Product | `ProductName`, `BrandName`, `ProductCategoryName`, `ProductSubcategoryName` |
| Customer | `CustomerName`, `Gender`, `YearlyIncome`, `CustomerCity`, `CustomerCountry` |
| Promotion | `PromotionName`, `PromotionType`, `DiscountPercent` |
| Measures | `SalesAmount`, `GrossProfit`, `GrossMarginPct`, `NetSalesAmount`, `TotalCost` |

---

## Power BI

### Option A — Parquet (recommended)

Run `./setup.sh` to generate `exports/AllSales.parquet`, then in Power BI:

**Get Data → Parquet → browse to `exports/AllSales.parquet`**

### Option B — Live DuckDB connection

```python
# powerbi/load_allsales.py
import duckdb, pandas as pd

DB_PATH = r"C:\path\to\ContosoDW\contoso.duckdb"
conn    = duckdb.connect(DB_PATH, read_only=True)
dataset = conn.execute("SELECT * FROM AllSales").df()
conn.close()
```

Use in Power BI via **Get Data → Python script**.

---

## Notebooks

```bash
cd notebooks
jupyter notebook
```

| Notebook | Contents |
|---|---|
| `01_profile.ipynb` | Table-level row counts, null rates, cardinality |
| `02_sales_analysis.ipynb` | Revenue by year / channel / category / country, monthly trends, top products |

---

## Profiling

```bash
# Full profile of all tables
python profiling/profile_data.py

# Summary only (row and column counts)
python profiling/profile_data.py --summary

# Single table
python profiling/profile_data.py --table DimCustomer
```

Reports are saved to `profiling/reports/`.

---

## Project structure

```
ContosoDW/
├── analysis/
│   └── build_marts.sql          # AllSales materialized mart
├── exports/                     # Parquet output (gitignored)
├── notebooks/
│   ├── 01_profile.ipynb
│   └── 02_sales_analysis.ipynb
├── powerbi/
│   └── load_allsales.py
├── profiling/
│   ├── profile_data.py
│   └── reports/                 # Generated reports (gitignored)
├── scripts/
│   └── export_for_powerbi.py
├── load_data.py                 # Kaggle → DuckDB
├── setup.sh                    # Full pipeline runner
└── contoso.duckdb              # Local database (gitignored)
```

---

## Notes

- `contoso.duckdb` is gitignored — regenerate locally with `./setup.sh`
- The Kaggle dataset is the "cleaned-contoso-dataset" variant; some columns differ from the original Microsoft T-SQL schema
- `AllSales.CustomerKey / CustomerCity / CustomerCountry` are populated only for online sales (`SaleSource = 'Online'`)
