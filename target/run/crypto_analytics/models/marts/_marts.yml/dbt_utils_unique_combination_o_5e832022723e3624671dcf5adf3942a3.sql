
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  





with validation_errors as (

    select
        product_id, minute
    from "neondb"."marts"."agg_price_1m"
    group by product_id, minute
    having count(*) > 1

)

select *
from validation_errors



  
  
      
    ) dbt_internal_test