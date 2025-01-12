with logs as (
    select * from {{ source('pipeline_demo','raw_llm_logs') }}
)

select
  created as log_created_at,
  model,
  stream as is_stream,
  max_tokens,
  temperature,
  type,
  metrics.start as started_at,
  metrics.end as ended_at,
  metrics.tokens as total_tokens,
  metrics.prompt_tokens,
  metrics.completion_tokens,
  metrics.time_to_first_token
from logs