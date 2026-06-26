{#
  By default dbt prefixes custom schemas with the target schema
  (e.g. target "public" + "marts" -> "public_marts"). We override that so a
  model configured with +schema: marts lands in a schema literally named "marts".
  This gives us clean, predictable layers: `staging` and `marts`.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
