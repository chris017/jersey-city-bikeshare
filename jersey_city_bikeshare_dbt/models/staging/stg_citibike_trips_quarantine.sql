select *
from {{ ref('stg_citibike_trips_validated') }}
where validation_error is not null