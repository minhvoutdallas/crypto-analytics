
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from "neondb"."marts"."agg_price_1m"

where not(high_price >= low_price)


  
  
      
    ) dbt_internal_test