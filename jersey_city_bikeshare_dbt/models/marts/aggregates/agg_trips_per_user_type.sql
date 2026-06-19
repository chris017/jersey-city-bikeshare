select
    date_day,
    user_type,
    count(*) as trip_count,
    avg(trip_duration_seconds) as avg_duration_seconds,
    min(trip_duration_seconds) as min_duration_seconds,
    max(trip_duration_seconds) as max_duration_seconds
from {{ ref('fct_trips') }}
group by date_day, user_type