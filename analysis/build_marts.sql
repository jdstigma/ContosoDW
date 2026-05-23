-- analysis/build_marts.sql
-- Materializes analytical tables into contoso.db.
-- Run after build_db.py + load_data.py, or via setup.sh.
--
--   sqlite3 contoso.db < analysis/build_marts.sql

-- ============================================================
-- AllSales
-- FactSales + FactOnlineSales merged and fully de-normalised.
-- Ready for direct import into Power BI / Excel / notebooks.
-- ============================================================

DROP TABLE IF EXISTS AllSales;

CREATE TABLE AllSales AS

WITH merged AS (

    -- In-store / catalog / reseller sales (FactSales)
    SELECT
        'Store'                  AS SaleSource,
        fs.SalesKey              AS SaleKey,
        NULL                     AS SalesOrderNumber,
        NULL                     AS SalesOrderLineNumber,
        fs.DateKey,
        fs.channelKey            AS ChannelKey,
        fs.StoreKey,
        fs.ProductKey,
        fs.PromotionKey,
        fs.CurrencyKey,
        NULL                     AS CustomerKey,
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

    -- Online sales (FactOnlineSales)
    SELECT
        'Online'                 AS SaleSource,
        fos.OnlineSalesKey       AS SaleKey,
        fos.SalesOrderNumber,
        fos.SalesOrderLineNumber,
        fos.DateKey,
        NULL                     AS ChannelKey,
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

    -- ── Identifiers ───────────────────────────────────────────
    s.SaleSource,
    s.SaleKey,
    s.SalesOrderNumber,
    s.SalesOrderLineNumber,

    -- ── Date ──────────────────────────────────────────────────
    s.DateKey,
    d.CalendarYear,
    d.CalendarQuarter,
    d.CalendarQuarterLabel,
    d.CalendarMonth,
    d.CalendarMonthLabel,
    d.FiscalYear,
    d.FiscalQuarter,

    -- ── Channel ───────────────────────────────────────────────
    COALESCE(ch.ChannelName, 'Online')  AS ChannelName,

    -- ── Store ─────────────────────────────────────────────────
    s.StoreKey,
    st.StoreName,
    st.StoreType,
    st.Status                           AS StoreStatus,
    st.OpenDate                         AS StoreOpenDate,
    st.EmployeeCount,
    st.SellingAreaSize,

    -- ── Store geography ───────────────────────────────────────
    sg.CityName                         AS StoreCity,
    sg.StateProvinceName                AS StoreState,
    sg.RegionCountryName                AS StoreCountry,
    sg.ContinentName                    AS StoreContinent,

    -- ── Product ───────────────────────────────────────────────
    s.ProductKey,
    p.ProductName,
    p.BrandName,
    p.ColorName,
    p.ClassName,
    p.StyleName,
    p.Status                            AS ProductStatus,
    pc.ProductCategoryName,
    psc.ProductSubcategoryName,

    -- ── Customer (online sales only, NULL for store) ──────────
    s.CustomerKey,
    CASE
        WHEN c.FirstName IS NOT NULL
        THEN c.FirstName || ' ' || c.LastName
    END                                 AS CustomerName,
    c.CustomerType,
    c.Gender,
    c.BirthDate,
    c.YearlyIncome,
    c.Education,
    c.Occupation,
    c.NumberCarsOwned,
    c.TotalChildren,

    -- ── Customer geography (online only) ──────────────────────
    cg.CityName                         AS CustomerCity,
    cg.StateProvinceName                AS CustomerState,
    cg.RegionCountryName                AS CustomerCountry,
    cg.ContinentName                    AS CustomerContinent,

    -- ── Promotion ─────────────────────────────────────────────
    pr.PromotionName,
    pr.PromotionType,
    pr.PromotionCategory,
    pr.DiscountPercent,

    -- ── Currency ──────────────────────────────────────────────
    cu.CurrencyLabel,
    cu.CurrencyName,

    -- ── Measures ──────────────────────────────────────────────
    s.SalesQuantity,
    s.SalesAmount,
    s.ReturnQuantity,
    COALESCE(s.ReturnAmount, 0)         AS ReturnAmount,
    s.DiscountQuantity,
    COALESCE(s.DiscountAmount, 0)       AS DiscountAmount,
    s.TotalCost,
    s.UnitCost,
    s.UnitPrice,

    -- ── Derived measures ──────────────────────────────────────
    s.SalesAmount - s.TotalCost         AS GrossProfit,
    CASE
        WHEN s.SalesAmount > 0
        THEN ROUND((s.SalesAmount - s.TotalCost) / s.SalesAmount * 100, 2)
    END                                 AS GrossMarginPct,
    s.SalesAmount
        - COALESCE(s.ReturnAmount, 0)   AS NetSalesAmount

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

-- Index the most common Power BI filter columns
CREATE INDEX IF NOT EXISTS IX_AllSales_CalendarYear    ON AllSales (CalendarYear);
CREATE INDEX IF NOT EXISTS IX_AllSales_ChannelName     ON AllSales (ChannelName);
CREATE INDEX IF NOT EXISTS IX_AllSales_StoreCountry    ON AllSales (StoreCountry);
CREATE INDEX IF NOT EXISTS IX_AllSales_ProductCategory ON AllSales (ProductCategoryName);
CREATE INDEX IF NOT EXISTS IX_AllSales_SaleSource      ON AllSales (SaleSource);

SELECT
    COUNT(*)                        AS TotalRows,
    SUM(CASE WHEN SaleSource = 'Store'  THEN 1 END) AS StoreRows,
    SUM(CASE WHEN SaleSource = 'Online' THEN 1 END) AS OnlineRows
FROM AllSales;
