---
title: Pipeline Demo
---

Below are some simple visualizations based on a sample dataset of 1,000 LLM prompts. Insights here are pretty simplistic, but that's mostly because we're making visualizations in the absence of business context.

<Details title='Why Evidence?'>

  We chose <a href="https://evidence.dev" target="_blank">Evidence</a> as our data visualization tool here, to choose something where the reader could see how this could be extended to a broader platform (instead of one-shot analyses like Python notebooks), but also remain self-contained (as opposed to requiring users of this demo to sign up for Looker or Mode or something, or to have every user of this demo hitting my personal Google Looker Studio account).
</Details>

## Overall Prompt Volume

```sql prompt_volume
  select 
      date_trunc('day', started_at) as invocation_day,
      count(*) as num_prompts,
      sum(prompt_tokens) as total_prompt_tokens
  from pipeline_demo.llm_usage
  group by 1
  order by 1 asc
```

With the exception of a couple of days (the 11th and the 13th), prompt volume looks pretty tightly correlated with token count.

<LineChart
    data={prompt_volume}
    title="Prompt Volume"
    x=invocation_day
    y=num_prompts
    y2=total_prompt_tokens
/>

## Prompts by a few different slices
```sql prompts_by_model
  select 
        date_trunc('day', started_at) as invocation_day,
        model,
        count(*) as num_prompts
  from pipeline_demo.llm_usage
  group by 1,2
  order by 1 asc
```

What happened on the 16th?  Looks like an older model was run for some reason.

<BarChart
    data={prompts_by_model}
    title="Prompts by Model"
    x=invocation_day
    y=num_prompts
    series=model
/>

```sql prompts_by_type
  select 
        date_trunc('day', started_at) as invocation_day,
        type,
        count(*) as num_prompts
  from pipeline_demo.llm_usage
  group by 1,2
  order by 1 asc
```

Most generation requests seem to be for a JSON schema, with a consistent minority of requests coming in for text.

<BarChart
    data={prompts_by_type}
    title="Prompts by Type"
    x=invocation_day
    y=num_prompts
    series=type
/>

## Prompts by Temperature
```sql prompts_by_temperature
  select
    temperature,
    '' as x_label,
    count(*) as num_prompts
  from pipeline_demo.llm_usage
  group by 1,2
  order by 1 desc
```

Seems like a temperature of 0.8 is the most popular setting.

<BarChart
    data={prompts_by_temperature}
    title="Prompts by Temperature"
    y=num_prompts
    x=x_label
    series=temperature
    swapXY=true
    type=stacked100
/>

## Latency (Time to first token)

```sql latency
  select time_to_first_token
  from pipeline_demo.llm_usage
```

The vast majority of prompts have a first token returned in less than a couple of seconds.

<Histogram
    title="Histogram: Latency"
    data={latency}
    x=time_to_first_token
/>