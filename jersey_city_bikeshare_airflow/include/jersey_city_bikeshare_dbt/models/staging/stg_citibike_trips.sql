select
    bike_id,
    user_type,
    gender_code,
    birth_year,
    trip_duration_seconds,
    started_at,
    ended_at,
    start_station_id,
    start_station_name,
    start_station_latitude,
    start_station_longitude,
    end_station_id,
    end_station_name,
    end_station_latitude,
    end_station_longitude
from {{ ref('stg_citibike_trips_validated') }}
where validation_error is null