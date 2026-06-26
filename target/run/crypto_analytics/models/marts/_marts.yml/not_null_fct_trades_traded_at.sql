
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select traded_at
from "neondb"."marts"."fct_trades"
where traded_at is null



  
  
      
    ) dbt_internal_test