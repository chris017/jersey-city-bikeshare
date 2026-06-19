select
    user_type,
    extract(hour from started_at) as hour_of_day,
    extract(dayofweek from started_at) as day_of_week,
    case
        when extract(dayofweek from started_at) in (0, 6) then true
        else false
    end as is_weekend,
    count(*) as trip_count,
    avg(trip_duration_seconds) as avg_duration_seconds
from {{ ref('fct_trips') }}
group by user_type, hour_of_day, day_of_week, is_weekend
order by user_type, day_of_week, hour_of_day