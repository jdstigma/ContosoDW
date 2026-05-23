{{
    config(materialized='table')
}}

with merged as (

    -- In-store / catalog / reseller sales
    select
        'Store'                  as SaleSource,
        fs.SalesKey              as SaleKey,
        null                     as SalesOrderNumber,
        null::integer            as SalesOrderLineNumber,
        fs.DateKey,
        fs.channelKey            as ChannelKey,
        fs.StoreKey,
        fs.ProductKey,
        fs.PromotionKey,
        fs.CurrencyKey,
        null::integer            as CustomerKey,
        fs.SalesQuantity,
        fs.SalesAmount,
        fs.ReturnQuantity,
        fs.ReturnAmount,
        fs.DiscountQuantity,
        fs.DiscountAmount,
        fs.TotalCost,
        fs.UnitCost,
        fs.UnitPrice
    from {{ source('raw', 'FactSales') }} fs

    union all

    -- Online sales
    select
        'Online'                 as SaleSource,
        fos.OnlineSalesKey       as SaleKey,
        fos.SalesOrderNumber,
        fos.SalesOrderLineNumber,
        fos.DateKey,
        null::integer            as ChannelKey,
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
    from {{ source('raw', 'FactOnlineSales') }} fos

)

select

    -- Identifiers
    s.SaleSource,
    s.SaleKey,
    s.SalesOrderNumber,
    s.SalesOrderLineNumber,

    -- Date
    s.DateKey,
    d.CalendarYear,
    try_cast(replace(d.CalendarQuarterLabel, 'Q', '') as bigint) as CalendarQuarter,
    d.CalendarQuarterLabel,
    d.MonthNumber                                                 as CalendarMonth,
    d.CalendarMonthLabel,
    d.FiscalYear,
    try_cast(replace(d.FiscalQuarterLabel,   'Q', '') as bigint) as FiscalQuarter,

    -- Channel
    coalesce(ch.ChannelName, 'Online')  as ChannelName,

    -- Store
    s.StoreKey,
    st.StoreName,
    st.StoreType,
    st.Status                           as StoreStatus,
    st.OpenDate                         as StoreOpenDate,
    st.EmployeeCount,
    st.SellingAreaSize,

    -- Store geography
    sg.CityName                         as StoreCity,
    sg.StateProvinceName                as StoreState,
    sg.RegionCountryName                as StoreCountry,
    sg.ContinentName                    as StoreContinent,

    -- Product
    s.ProductKey,
    p.ProductName,
    p.BrandName,
    p.ColorName,
    p.ClassName,
    p.StyleName,
    p.Status                            as ProductStatus,
    pc.ProductCategoryName,
    psc.ProductSubcategoryName,

    -- Customer (online only)
    s.CustomerKey,
    case
        when c.FirstName is not null
        then c.FirstName || ' ' || c.LastName
    end                                 as CustomerName,
    c.Gender,
    c.BirthDate,
    c.YearlyIncome,
    c.Education,
    c.Occupation,
    c.NumberCarsOwned,
    c.TotalChildren,

    -- Customer geography (online only)
    cg.CityName                         as CustomerCity,
    cg.StateProvinceName                as CustomerState,
    cg.RegionCountryName                as CustomerCountry,
    cg.ContinentName                    as CustomerContinent,

    -- Promotion
    pr.PromotionName,
    pr.PromotionType,
    pr.PromotionCategory,
    pr.DiscountPercent,

    -- Currency
    cu.CurrencyName,

    -- Measures
    s.SalesQuantity,
    s.SalesAmount,
    s.ReturnQuantity,
    coalesce(s.ReturnAmount, 0)         as ReturnAmount,
    s.DiscountQuantity,
    coalesce(s.DiscountAmount, 0)       as DiscountAmount,
    s.TotalCost,
    s.UnitCost,
    s.UnitPrice,

    -- Derived measures
    s.SalesAmount - s.TotalCost                         as GrossProfit,
    case
        when s.SalesAmount > 0
        then round((s.SalesAmount - s.TotalCost) / s.SalesAmount * 100, 2)
    end                                                 as GrossMarginPct,
    s.SalesAmount - coalesce(s.ReturnAmount, 0)         as NetSalesAmount

from merged s

left join {{ source('raw', 'DimDate')               }} d    on s.DateKey        = d.Datekey
left join {{ source('raw', 'DimChannel')            }} ch   on s.ChannelKey     = ch.ChannelKey
left join {{ source('raw', 'DimStore')              }} st   on s.StoreKey       = st.StoreKey
left join {{ source('raw', 'DimGeography')          }} sg   on st.GeographyKey  = sg.GeographyKey
left join {{ source('raw', 'DimProduct')            }} p    on s.ProductKey     = p.ProductKey
left join {{ source('raw', 'DimProductSubcategory') }} psc  on p.ProductSubcategoryKey = psc.ProductSubcategoryKey
left join {{ source('raw', 'DimProductCategory')    }} pc   on psc.ProductCategoryKey  = pc.ProductCategoryKey
left join {{ source('raw', 'DimCustomer')           }} c    on s.CustomerKey    = c.CustomerKey
left join {{ source('raw', 'DimGeography')          }} cg   on c.GeographyKey   = cg.GeographyKey
left join {{ source('raw', 'DimPromotion')          }} pr   on s.PromotionKey   = pr.PromotionKey
left join {{ source('raw', 'DimCurrency')           }} cu   on s.CurrencyKey    = cu.CurrencyKey
