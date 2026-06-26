





with validation_errors as (

    select
        product_id, minute
    from "neondb"."marts"."agg_price_1m"
    group by product_id, minute
    having count(*) > 1

)

select *
from validation_errors


