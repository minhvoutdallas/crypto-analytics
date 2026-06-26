
    
    

with all_values as (

    select
        side as value_field,
        count(*) as n_records

    from "neondb"."marts"."fct_trades"
    group by side

)

select *
from all_values
where value_field not in (
    'buy','sell'
)


