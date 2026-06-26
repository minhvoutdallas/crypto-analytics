
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select price_usd
from "neondb"."staging"."stg_trades"
where price_usd is null



  
  
      
    ) dbt_internal_test