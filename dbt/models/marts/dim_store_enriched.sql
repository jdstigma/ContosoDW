{{
    config(materialized='table')
}}

select
    st.StoreKey,
    st.StoreName,
    st.StoreType,
    st.Status                       as StoreStatus,
    st.OpenDate                     as StoreOpenDate,
    st.CloseDate                    as StoreCloseDate,
    st.EmployeeCount,
    st.SellingAreaSize,
    g.CityName                      as StoreCity,
    g.StateProvinceName             as StoreState,
    g.RegionCountryName             as StoreCountry,
    g.ContinentName                 as StoreContinent

from {{ source('raw', 'DimStore') }}     st
left join {{ source('raw', 'DimGeography') }} g
    on st.GeographyKey = g.GeographyKey
