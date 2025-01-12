with logs as (
    select * from {{ ref('stg_pipeline_demo__llm_logs') }}
)

select * replace (timestamp_seconds(cast(started_at as int)) as started_at,
                  timestamp_seconds(cast(ended_at as int)) as ended_at)
from logs