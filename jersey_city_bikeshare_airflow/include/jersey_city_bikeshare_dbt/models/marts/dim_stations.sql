with stations as (

    select
        start_station_id as station_id,
        start_station_name as station_name,
        start_station_latitude as station_latitude,
        start_station_longitude as station_longitude,
        started_at as observed_at
    from {{ ref('stg_citibike_trips') }}

    union all

    select
        end_station_id as station_id,
        end_station_name as station_name,
        end_station_latitude as station_latitude,
        end_station_longitude as station_longitude,
        ended_at as observed_at
    from {{ ref('stg_citibike_trips') }}

),

ranked as (

    select
        station_id,
        station_name,
        station_latitude,
        station_longitude,
        row_number() over (partition by station_id order by observed_at desc) as rn
    from stations

)

select
    station_id,
    station_name,
    station_latitude,
    station_longitude
from ranked
where rn = 1