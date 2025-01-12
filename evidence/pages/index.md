---
title: Pipeline Demo
---

<Details title='How to edit this page'>

  This page can be found in your project at `/pages/index.md`. Make a change to the markdown file and save it to see the change take effect in your browser.
</Details>

```sql prompt_volume
  select 
      date_trunc('day', started_at) as invocation_day,
      count(*) as num_prompts,
      sum(prompt_tokens) as total_prompt_tokens
  from pipeline_demo.llm_usage
  group by 1
  order by 1 asc
```

<LineChart
    data={prompt_volume}
    title="Prompt Volume"
    x=invocation_day
    y=num_prompts
    y2=total_prompt_tokens
/>