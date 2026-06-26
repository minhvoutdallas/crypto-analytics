-- Dimension: one row per traded market. Derived from observed products so it
-- grows automatically when the collector starts tracking a new pair.

with products as (
    select distinct product_id
    from "neondb"."staging"."stg_trades"
)

select
    product_id,
    split_part(product_id, '-', 1)      as base_currency,   -- e.g. BTC
    split_part(product_id, '-', 2)      as quote_currency,  -- e.g. USD
    replace(product_id, '-', ' / ')     as display_name     -- e.g. BTC / USD
from products