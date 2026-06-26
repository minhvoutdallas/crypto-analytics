
  
    

  create  table "neondb"."marts"."agg_price_1m__dbt_tmp"
  
  
    as
  
  (
    -- Aggregate: 1-minute OHLCV candles per product — the headline metric for the
-- dashboard. Open/close are the first/last trade price within each minute
-- (ordered by event time, tie-broken by trade_id); high/low/volume are simple
-- aggregates. VWAP is the volume-weighted average price.

with base as (
    select
        product_id,
        date_trunc('minute', traded_at) as minute,
        trade_id,
        price_usd,
        size,
        traded_at
    from "neondb"."marts"."fct_trades"
),

ranked as (
    select
        *,
        row_number() over (
            partition by product_id, minute
            order by traded_at asc, trade_id asc
        ) as rn_first,
        row_number() over (
            partition by product_id, minute
            order by traded_at desc, trade_id desc
        ) as rn_last
    from base
)

select
    product_id,
    minute,
    max(price_usd) filter (where rn_first = 1)      as open_price,
    max(price_usd)                                  as high_price,
    min(price_usd)                                  as low_price,
    max(price_usd) filter (where rn_last = 1)       as close_price,
    sum(size)                                       as volume,
    count(*)                                        as trade_count,
    sum(price_usd * size) / nullif(sum(size), 0)    as vwap
from ranked
group by product_id, minute
  );
  