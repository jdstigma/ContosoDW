{{
    config(materialized='table')
}}

select ChannelKey, ChannelName
from {{ source('raw', 'DimChannel') }}

union all

select -1, 'Unspecified'
