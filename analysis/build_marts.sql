-- analysis/build_marts.sql
-- Materializes AllSales into contoso.duckdb.
-- Run after load_data.py, or via setup.sh.
--
--   duckdb contoso.duckdb < analysis/build_marts.sql

-- ============================================================
-- AllSales
-- FactSales + FactOnlineSales merged and fully de-normalised.
-- ============================================================

DROP TABLE IF EXISTS AllSales;

CREATE TABLE AllSales AS

WITH merged AS (

    -- In-store / catalog / reseller sales
    SELECT
        'Store'                  AS SaleSource,
        fs.SalesKey              AS SaleKey,
        NULL                     AS SalesOrderNumber,
        NULL::INTEGER            AS SalesOrderLineNumber,
        fs.DateKey,
        COALESCE(fs.channelKey, -1)::INTEGER AS ChannelKey,
        fs.StoreKey,
        fs.ProductKey,
        fs.PromotionKey,
        fs.CurrencyKey,
        NULL::INTEGER            AS CustomerKey,
        fs.SalesQuantity,
        fs.SalesAmount,
        fs.ReturnQuantity,
        fs.ReturnAmount,
        fs.DiscountQuantity,
        fs.DiscountAmount,
        fs.TotalCost,
        fs.UnitCost,
        fs.UnitPrice
    FROM FactSales fs

    UNION ALL

    -- Online sales
    SELECT
        'Online'                 AS SaleSource,
        fos.OnlineSalesKey       AS SaleKey,
        fos.SalesOrderNumber,
        fos.SalesOrderLineNumber,
        fos.DateKey,
        -1::INTEGER              AS ChannelKey,
        fos.StoreKey,
        fos.ProductKey,
        fos.PromotionKey,
        fos.CurrencyKey,
        fos.CustomerKey,
        fos.SalesQuantity,
        fos.SalesAmount,
        fos.ReturnQuantity,
        fos.ReturnAmount,
        fos.DiscountQuantity,
        fos.DiscountAmount,
        fos.TotalCost,
        fos.UnitCost,
        fos.UnitPrice
    FROM FactOnlineSales fos

)

SELECT

    -- Identifiers
    s.SaleSource,
    s.SaleKey,
    s.SalesOrderNumber,
    s.SalesOrderLineNumber,

    -- Date
    s.DateKey,
    d.CalendarYear,
    TRY_CAST(REPLACE(d.CalendarQuarterLabel, 'Q', '') AS BIGINT) AS CalendarQuarter,
    d.CalendarQuarterLabel,
    d.MonthNumber                                                 AS CalendarMonth,
    d.CalendarMonthLabel,
    d.FiscalYear,
    TRY_CAST(REPLACE(d.FiscalQuarterLabel,   'Q', '') AS BIGINT) AS FiscalQuarter,

    -- Channel
    s.ChannelKey,
    COALESCE(ch.ChannelName, 'Online')  AS ChannelName,

    -- Store
    s.StoreKey,
    st.StoreName,
    st.StoreType,
    st.Status                           AS StoreStatus,
    st.OpenDate                         AS StoreOpenDate,
    st.EmployeeCount,
    st.SellingAreaSize,

    -- Store geography
    sg.CityName                         AS StoreCity,
    sg.StateProvinceName                AS StoreState,
    sg.RegionCountryName                AS StoreCountry,
    sg.ContinentName                    AS StoreContinent,

    -- Product
    s.ProductKey,
    p.ProductName,
    p.BrandName,
    p.ColorName,
    p.ClassName,
    p.StyleName,
    p.Status                            AS ProductStatus,
    pc.ProductCategoryName,
    psc.ProductSubcategoryName,

    -- Customer (online only)
    s.CustomerKey,
    CASE
        WHEN c.FirstName IS NOT NULL
        THEN c.FirstName || ' ' || c.LastName
    END                                 AS CustomerName,
    c.Gender,
    c.BirthDate,
    c.YearlyIncome,
    c.Education,
    c.Occupation,
    c.NumberCarsOwned,
    c.TotalChildren,

    -- Customer geography (online only)
    cg.CityName                         AS CustomerCity,
    cg.StateProvinceName                AS CustomerState,
    cg.RegionCountryName                AS CustomerCountry,
    cg.ContinentName                    AS CustomerContinent,

    -- Promotion
    s.PromotionKey,
    pr.PromotionName,
    pr.PromotionType,
    pr.PromotionCategory,
    pr.DiscountPercent,

    -- Currency
    s.CurrencyKey,
    cu.CurrencyName,

    -- Measures
    s.SalesQuantity,
    s.SalesAmount,
    s.ReturnQuantity,
    COALESCE(s.ReturnAmount, 0)         AS ReturnAmount,
    s.DiscountQuantity,
    COALESCE(s.DiscountAmount, 0)       AS DiscountAmount,
    s.TotalCost,
    s.UnitCost,
    s.UnitPrice,

    -- Derived measures
    s.SalesAmount - s.TotalCost                         AS GrossProfit,
    CASE
        WHEN s.SalesAmount > 0
        THEN ROUND((s.SalesAmount - s.TotalCost) / s.SalesAmount * 100, 2)
    END                                                 AS GrossMarginPct,
    s.SalesAmount - COALESCE(s.ReturnAmount, 0)         AS NetSalesAmount

FROM merged s

LEFT JOIN DimDate               d    ON s.DateKey        = d.Datekey
LEFT JOIN DimChannel            ch   ON s.ChannelKey      = ch.ChannelKey
LEFT JOIN DimStore              st   ON s.StoreKey        = st.StoreKey
LEFT JOIN DimGeography          sg   ON st.GeographyKey   = sg.GeographyKey
LEFT JOIN DimProduct            p    ON s.ProductKey      = p.ProductKey
LEFT JOIN DimProductSubcategory psc  ON p.ProductSubcategoryKey = psc.ProductSubcategoryKey
LEFT JOIN DimProductCategory    pc   ON psc.ProductCategoryKey  = pc.ProductCategoryKey
LEFT JOIN DimCustomer           c    ON s.CustomerKey     = c.CustomerKey
LEFT JOIN DimGeography          cg   ON c.GeographyKey    = cg.GeographyKey
LEFT JOIN DimPromotion          pr   ON s.PromotionKey    = pr.PromotionKey
LEFT JOIN DimCurrency           cu   ON s.CurrencyKey     = cu.CurrencyKey;

-- ============================================================
-- DimChannelEnriched
-- DimChannel with an extra row (ChannelKey = -1) to capture
-- online sales that have no channel key in the source data.
-- ============================================================

DROP TABLE IF EXISTS DimChannelEnriched;

CREATE TABLE DimChannelEnriched AS
SELECT ChannelKey, ChannelName FROM DimChannel
UNION ALL
SELECT -1, 'Unspecified';

-- ============================================================
-- DimProductEnriched
-- DimProduct with subcategory and category names pre-joined.
-- ============================================================

DROP TABLE IF EXISTS DimProductEnriched;

CREATE TABLE DimProductEnriched AS
SELECT
    p.ProductKey,
    p.ProductName,
    p.BrandName,
    p.ColorName,
    p.ClassName,
    p.StyleName,
    p.Status                        AS ProductStatus,
    p.UnitCost,
    p.UnitPrice,
    psc.ProductSubcategoryKey,
    psc.ProductSubcategoryName,
    pc.ProductCategoryKey,
    pc.ProductCategoryName
FROM DimProduct            p
LEFT JOIN DimProductSubcategory psc ON p.ProductSubcategoryKey  = psc.ProductSubcategoryKey
LEFT JOIN DimProductCategory    pc  ON psc.ProductCategoryKey   = pc.ProductCategoryKey;

-- ============================================================
-- DimStoreEnriched
-- DimStore with geography columns pre-joined.
-- ============================================================

DROP TABLE IF EXISTS DimStoreEnriched;

CREATE TABLE DimStoreEnriched AS
SELECT
    st.StoreKey,
    st.StoreName,
    st.StoreType,
    st.Status                       AS StoreStatus,
    st.OpenDate                     AS StoreOpenDate,
    st.CloseDate                    AS StoreCloseDate,
    st.EmployeeCount,
    st.SellingAreaSize,
    g.CityName                      AS StoreCity,
    g.StateProvinceName             AS StoreState,
    g.RegionCountryName             AS StoreCountry,
    g.ContinentName                 AS StoreContinent
FROM DimStore       st
LEFT JOIN DimGeography g ON st.GeographyKey = g.GeographyKey;

-- ============================================================
-- DimCustomerEnriched
-- DimCustomer with geography columns pre-joined.
-- ============================================================

DROP TABLE IF EXISTS DimCustomerEnriched;

CREATE TABLE DimCustomerEnriched AS
SELECT
    c.CustomerKey,
    c.FirstName || ' ' || c.LastName AS CustomerName,
    c.Gender,
    c.BirthDate,
    c.MaritalStatus,
    c.YearlyIncome,
    c.Education,
    c.Occupation,
    c.NumberCarsOwned,
    c.TotalChildren,
    c.NumberChildrenAtHome,
    c.HouseOwnerFlag,
    g.CityName                      AS CustomerCity,
    g.StateProvinceName             AS CustomerState,
    g.RegionCountryName             AS CustomerCountry,
    g.ContinentName                 AS CustomerContinent
FROM DimCustomer    c
LEFT JOIN DimGeography g ON c.GeographyKey = g.GeographyKey;

-- Verification
SELECT
    COUNT(*)                                        AS TotalRows,
    SUM(CASE WHEN SaleSource = 'Store'  THEN 1 END) AS StoreRows,
    SUM(CASE WHEN SaleSource = 'Online' THEN 1 END) AS OnlineRows
FROM AllSales;

SELECT 'DimProductEnriched'  AS Mart, COUNT(*) AS Rows FROM DimProductEnriched
UNION ALL
SELECT 'DimStoreEnriched',          COUNT(*) FROM DimStoreEnriched
UNION ALL
SELECT 'DimCustomerEnriched',       COUNT(*) FROM DimCustomerEnriched;
