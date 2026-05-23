{{
    config(materialized='table')
}}

select
    c.CustomerKey,
    c.FirstName || ' ' || c.LastName as CustomerName,
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
    g.CityName                      as CustomerCity,
    g.StateProvinceName             as CustomerState,
    g.RegionCountryName             as CustomerCountry,
    g.ContinentName                 as CustomerContinent

from {{ source('raw', 'DimCustomer') }}  c
left join {{ source('raw', 'DimGeography') }} g
    on c.GeographyKey = g.GeographyKey
