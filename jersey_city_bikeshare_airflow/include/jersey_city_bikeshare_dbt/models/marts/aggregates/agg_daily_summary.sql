select
    date_day,
    count(*) as total_trips,
    count(distinct bike_id) as unique_bikes_used,
    count(distinct start_station_id) as unique_start_stations,
    avg(trip_duration_seconds) as avg_trip_duration_seconds,
    sum(trip_duration_seconds) as total_riding_time_seconds
from {{ ref('fct_trips') }}
group by date_day