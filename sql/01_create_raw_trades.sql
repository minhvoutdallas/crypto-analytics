-- Phase 1b — the "landing zone" for raw, untouched source data.
-- Run this once in the Neon SQL editor.

-- A schema is just a namespace. We separate layers by schema:
--   raw    = data exactly as it arrives from the source (never edited by hand)
--   public = where dbt will later build clean, modeled tables
-- This separation is a core analytics-engineering convention. dbt depends on it.
CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.trades (
    trade_id     BIGINT       NOT NULL,   -- Coinbase trade IDs are large integers
    product_id   TEXT         NOT NULL,   -- e.g. 'BTC-USD'
    price        NUMERIC      NOT NULL,   -- NUMERIC = exact decimal. NEVER use FLOAT for money.
    size         NUMERIC      NOT NULL,   -- amount of the asset traded
    side         TEXT,                    -- 'buy' or 'sell' (the taker's side)
    ts           TIMESTAMPTZ  NOT NULL,   -- EVENT time: when the trade happened (UTC, tz-aware)
    ingested_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),  -- LOAD time: when WE pulled it

    -- The primary key is the single most important design decision here.
    -- trade_id is unique *within a product*, not globally, so the key is the PAIR.
    -- This PK is what makes our pipeline idempotent: if the collector pulls the
    -- same trade twice (it will - APIs return overlapping windows), the duplicate
    -- insert is rejected instead of creating a double row.
    PRIMARY KEY (product_id, trade_id)
);

-- Quick sanity check after running:
-- SELECT count(*) FROM raw.trades;
