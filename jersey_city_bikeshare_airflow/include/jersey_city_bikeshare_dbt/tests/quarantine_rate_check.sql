with counts as (

    select
        (select count(*) from {{ ref('stg_citibike_trips') }}) as valid_count,
        (select count(*) from {{ ref('stg_citibike_trips_quarantine') }}) as quarantine_count

)

select *
from counts
where quarantine_count > (valid_count + quarantine_count) * 0.05
