with trips_start as (

    select
        date_day,
        start_station_id as station_id,
        count(*) as trips_started
    from {{ ref('fct_trips') }}
    group by date_day, start_station_id

),

trips_end as (

    select
        date_day,
        end_station_id as station_id,
        count(*) as trips_ended
    from {{ ref('fct_trips') }}
    group by date_day, end_station_id

)

select
    coalesce(s.date_day, e.date_day) as date_day,
    coalesce(s.station_id, e.station_id) as station_id,
    coalesce(s.trips_started, 0) as trips_started,
    coalesce(e.trips_ended, 0) as trips_ended
from trips_start s
full outer join trips_end e
    on s.date_day = e.date_day
    and s.station_id = e.station_id