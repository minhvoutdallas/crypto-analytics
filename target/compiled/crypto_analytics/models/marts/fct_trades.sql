-- Fact: the grain is one trade. Incremental so each run only transforms NEW
-- trades instead of rebuilding the full history every time.
--
-- delete+insert with a composite unique_key makes re-runs safe: if a trade ever
-- reappears in the incoming slice, its old row is replaced rather than doubled.



select
    product_id,
    trade_id,
    price_usd,
    size,
    side,
    traded_at,
    ingested_at
from "neondb"."staging"."stg_trades"


    -- Only pull rows loaded after the newest row we already have.
    -- coalesce handles the very first incremental run (table exists but is empty).
    where ingested_at > (select coalesce(max(ingested_at), '2000-01-01'::timestamptz) from "neondb"."marts"."fct_trades")
