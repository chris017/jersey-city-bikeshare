{{
    config(
        materialized='incremental',
        unique_key='trip_id'
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(['bike_id', 'started_at']) }} as trip_id,
    bike_id,
    user_type,
    gender_code,
    birth_year,
    trip_duration_seconds,
    started_at,
    ended_at,
    date(started_at) as date_day,
    start_station_id,
    end_station_id
from {{ ref('stg_citibike_trips') }}

{% if is_incremental() %}

  where started_at > (select max(started_at) from {{ this }})

{% endif %}