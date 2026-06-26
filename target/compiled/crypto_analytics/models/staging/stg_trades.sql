-- Staging: clean, typed, 1:1 with the source. No business logic here.
-- Rename to clear, consistent names and normalize the side value.

with source as (
    select * from "neondb"."raw"."trades"
)

select
    product_id,
    trade_id,
    price::numeric          as price_usd,    -- quote currency is USD for our products
    size::numeric           as size,
    lower(side)             as side,         -- normalize to lowercase buy/sell
    ts::timestamptz         as traded_at,    -- event time
    ingested_at                              -- load time (used for incremental + freshness)
from source