





with validation_errors as (

    select
        product_id, trade_id
    from "neondb"."marts"."fct_trades"
    group by product_id, trade_id
    having count(*) > 1

)

select *
from validation_errors


