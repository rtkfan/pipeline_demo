-- boilerplate macro to use custom schemas for prod and shove all dev activity
-- into a sandbox schema.

-- see:
-- https://docs.getdbt.com/docs/building-a-dbt-project/building-models/using-custom-schemas

{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ generate_schema_name_for_env(custom_schema_name, node) }}
{%- endmacro %}