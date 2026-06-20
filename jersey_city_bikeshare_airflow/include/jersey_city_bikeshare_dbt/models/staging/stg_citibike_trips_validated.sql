with source as (

    select * from {{ source('raw', 'raw_citibike_trips') }}

),

renamed as (

    select
        bikeid                      as bike_id,
        usertype                    as user_type,
        gender                      as gender_code,
        birth_year                  as birth_year,
        tripduration                as trip_duration_seconds,
        starttime                   as started_at,
        stoptime                    as ended_at,
        start_station_id,
        start_station_name,
        start_station_latitude,
        start_station_longitude,
        end_station_id,
        end_station_name,
        end_station_latitude,
        end_station_longitude
    from source

),

validated as (

    select
        *,
        case
            when trip_duration_seconds <= 0 then 'invalid_trip_duration'
            when started_at >= ended_at then 'start_after_end'
            when start_station_id is null then 'missing_start_station'
            when end_station_id is null then 'missing_end_station'
            when birth_year is not null and (birth_year < 1900 or birth_year > extract(year from current_date())) then 'invalid_birth_year'
            else null
        end as validation_error
    from renamed

)

select * from validated