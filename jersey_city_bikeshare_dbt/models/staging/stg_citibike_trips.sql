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

)

select * from renamed