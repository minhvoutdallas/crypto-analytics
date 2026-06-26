



select
    1
from "neondb"."marts"."agg_price_1m"

where not(high_price >= low_price)

