with date_spine as (

    select distinct
        date(started_at) as date_day
    from {{ ref('stg_citibike_trips') }}

)

select
    date_day,
    extract(year from date_day) as year,
    extract(month from date_day) as month,
    extract(day from date_day) as day,
    extract(dayofweek from date_day) as day_of_week,
    case
        when extract(dayofweek from date_day) in (0, 6) then true
        else false
    end as is_weekend
from date_spine