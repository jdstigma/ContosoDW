{{
    config(materialized='table')
}}

select
    p.ProductKey,
    p.ProductName,
    p.BrandName,
    p.ColorName,
    p.ClassName,
    p.StyleName,
    p.Status                        as ProductStatus,
    p.UnitCost,
    p.UnitPrice,
    psc.ProductSubcategoryKey,
    psc.ProductSubcategoryName,
    pc.ProductCategoryKey,
    pc.ProductCategoryName

from {{ source('raw', 'DimProduct') }}            p
left join {{ source('raw', 'DimProductSubcategory') }} psc
    on p.ProductSubcategoryKey = psc.ProductSubcategoryKey
left join {{ source('raw', 'DimProductCategory') }}    pc
    on psc.ProductCategoryKey  = pc.ProductCategoryKey
