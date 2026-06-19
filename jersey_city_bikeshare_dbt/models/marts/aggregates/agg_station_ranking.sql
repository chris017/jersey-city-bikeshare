select
    s.station_name,
    sum(a.trips_started) as total_trips_started,
    sum(a.trips_ended) as total_trips_ended,
    sum(a.trips_started) + sum(a.trips_ended) as total_activity
from {{ ref('agg_trips_per_station_per_day') }} a
join {{ ref('dim_stations') }} s on a.station_id = s.station_id
group by s.station_name
order by total_activity desc