-- indexes_sqlite.sql
-- Performance indexes for ContosoRetailDW SQLite database
--
-- Strategy:
--   1. Every FK column on every Fact table  — eliminates full scans on JOINs
--   2. High-cardinality Dimension filter columns — speeds up WHERE clauses
--   3. Composite date indexes on DimDate   — accelerates year/month slicing
--
-- Applied automatically by build_db.py after schema creation.
-- To apply to an existing database:
--   sqlite3 contoso.db < indexes_sqlite.sql

-- ============================================================
-- FACT TABLE INDEXES  (FK columns — most critical for JOINs)
-- ============================================================

-- FactSales
CREATE INDEX IF NOT EXISTS IX_FactSales_DateKey      ON FactSales (DateKey);
CREATE INDEX IF NOT EXISTS IX_FactSales_ChannelKey   ON FactSales (channelKey);
CREATE INDEX IF NOT EXISTS IX_FactSales_StoreKey     ON FactSales (StoreKey);
CREATE INDEX IF NOT EXISTS IX_FactSales_ProductKey   ON FactSales (ProductKey);
CREATE INDEX IF NOT EXISTS IX_FactSales_PromotionKey ON FactSales (PromotionKey);
CREATE INDEX IF NOT EXISTS IX_FactSales_CurrencyKey  ON FactSales (CurrencyKey);

-- FactOnlineSales
CREATE INDEX IF NOT EXISTS IX_FactOnlineSales_DateKey      ON FactOnlineSales (DateKey);
CREATE INDEX IF NOT EXISTS IX_FactOnlineSales_CustomerKey  ON FactOnlineSales (CustomerKey);
CREATE INDEX IF NOT EXISTS IX_FactOnlineSales_StoreKey     ON FactOnlineSales (StoreKey);
CREATE INDEX IF NOT EXISTS IX_FactOnlineSales_ProductKey   ON FactOnlineSales (ProductKey);
CREATE INDEX IF NOT EXISTS IX_FactOnlineSales_PromotionKey ON FactOnlineSales (PromotionKey);
CREATE INDEX IF NOT EXISTS IX_FactOnlineSales_CurrencyKey  ON FactOnlineSales (CurrencyKey);

-- FactInventory
CREATE INDEX IF NOT EXISTS IX_FactInventory_DateKey     ON FactInventory (DateKey);
CREATE INDEX IF NOT EXISTS IX_FactInventory_StoreKey    ON FactInventory (StoreKey);
CREATE INDEX IF NOT EXISTS IX_FactInventory_ProductKey  ON FactInventory (ProductKey);
CREATE INDEX IF NOT EXISTS IX_FactInventory_CurrencyKey ON FactInventory (CurrencyKey);

-- FactITMachine
CREATE INDEX IF NOT EXISTS IX_FactITMachine_Datekey    ON FactITMachine (Datekey);
CREATE INDEX IF NOT EXISTS IX_FactITMachine_MachineKey ON FactITMachine (MachineKey);

-- FactITSLA
CREATE INDEX IF NOT EXISTS IX_FactITSLA_DateKey    ON FactITSLA (DateKey);
CREATE INDEX IF NOT EXISTS IX_FactITSLA_StoreKey   ON FactITSLA (StoreKey);
CREATE INDEX IF NOT EXISTS IX_FactITSLA_MachineKey ON FactITSLA (MachineKey);
CREATE INDEX IF NOT EXISTS IX_FactITSLA_OutageKey  ON FactITSLA (OutageKey);

-- FactExchangeRate
CREATE INDEX IF NOT EXISTS IX_FactExchangeRate_CurrencyKey ON FactExchangeRate (CurrencyKey);
CREATE INDEX IF NOT EXISTS IX_FactExchangeRate_DateKey     ON FactExchangeRate (DateKey);

-- FactStrategyPlan
CREATE INDEX IF NOT EXISTS IX_FactStrategyPlan_Datekey            ON FactStrategyPlan (Datekey);
CREATE INDEX IF NOT EXISTS IX_FactStrategyPlan_EntityKey          ON FactStrategyPlan (EntityKey);
CREATE INDEX IF NOT EXISTS IX_FactStrategyPlan_ScenarioKey        ON FactStrategyPlan (ScenarioKey);
CREATE INDEX IF NOT EXISTS IX_FactStrategyPlan_AccountKey         ON FactStrategyPlan (AccountKey);
CREATE INDEX IF NOT EXISTS IX_FactStrategyPlan_CurrencyKey        ON FactStrategyPlan (CurrencyKey);
CREATE INDEX IF NOT EXISTS IX_FactStrategyPlan_ProductCategoryKey ON FactStrategyPlan (ProductCategoryKey);

-- FactSalesQuota
CREATE INDEX IF NOT EXISTS IX_FactSalesQuota_DateKey     ON FactSalesQuota (DateKey);
CREATE INDEX IF NOT EXISTS IX_FactSalesQuota_ChannelKey  ON FactSalesQuota (ChannelKey);
CREATE INDEX IF NOT EXISTS IX_FactSalesQuota_StoreKey    ON FactSalesQuota (StoreKey);
CREATE INDEX IF NOT EXISTS IX_FactSalesQuota_ProductKey  ON FactSalesQuota (ProductKey);
CREATE INDEX IF NOT EXISTS IX_FactSalesQuota_CurrencyKey ON FactSalesQuota (CurrencyKey);
CREATE INDEX IF NOT EXISTS IX_FactSalesQuota_ScenarioKey ON FactSalesQuota (ScenarioKey);

-- ============================================================
-- DIMENSION TABLE INDEXES  (filter & lookup columns)
-- ============================================================

-- DimDate — time slicing is the most common DW filter pattern
CREATE INDEX IF NOT EXISTS IX_DimDate_CalendarYear      ON DimDate (CalendarYear);
CREATE INDEX IF NOT EXISTS IX_DimDate_FiscalYear        ON DimDate (FiscalYear);
CREATE INDEX IF NOT EXISTS IX_DimDate_CalendarYearMonth ON DimDate (CalendarYear, CalendarMonth);
CREATE INDEX IF NOT EXISTS IX_DimDate_CalendarQuarter   ON DimDate (CalendarYear, CalendarQuarter);

-- DimProduct
CREATE INDEX IF NOT EXISTS IX_DimProduct_ProductSubcategoryKey ON DimProduct (ProductSubcategoryKey);
CREATE INDEX IF NOT EXISTS IX_DimProduct_Status                ON DimProduct (Status);
CREATE INDEX IF NOT EXISTS IX_DimProduct_ColorName             ON DimProduct (ColorName);

-- DimProductSubcategory
CREATE INDEX IF NOT EXISTS IX_DimProductSubcategory_ProductCategoryKey ON DimProductSubcategory (ProductCategoryKey);

-- DimCustomer
CREATE INDEX IF NOT EXISTS IX_DimCustomer_GeographyKey  ON DimCustomer (GeographyKey);
CREATE INDEX IF NOT EXISTS IX_DimCustomer_CustomerType  ON DimCustomer (CustomerType);

-- DimStore
CREATE INDEX IF NOT EXISTS IX_DimStore_GeographyKey ON DimStore (GeographyKey);
CREATE INDEX IF NOT EXISTS IX_DimStore_Status       ON DimStore (Status);

-- DimEmployee
CREATE INDEX IF NOT EXISTS IX_DimEmployee_SalesPersonFlag ON DimEmployee (SalesPersonFlag);
CREATE INDEX IF NOT EXISTS IX_DimEmployee_DepartmentName  ON DimEmployee (DepartmentName);

-- DimGeography
CREATE INDEX IF NOT EXISTS IX_DimGeography_RegionCountryName ON DimGeography (RegionCountryName);
CREATE INDEX IF NOT EXISTS IX_DimGeography_ContinentName     ON DimGeography (ContinentName);

-- DimMachine
CREATE INDEX IF NOT EXISTS IX_DimMachine_StoreKey ON DimMachine (StoreKey);
