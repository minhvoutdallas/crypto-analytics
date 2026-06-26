
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  





with validation_errors as (

    select
        product_id, trade_id
    from "neondb"."marts"."fct_trades"
    group by product_id, trade_id
    having count(*) > 1

)

select *
from validation_errors



  
  
      
    ) dbt_internal_test