
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select size
from "neondb"."staging"."stg_trades"
where size is null



  
  
      
    ) dbt_internal_test