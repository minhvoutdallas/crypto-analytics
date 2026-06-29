# Real-Time Crypto Market Analytics Pipeline

An end-to-end, fully open-source data pipeline that ingests live crypto trades,
models them with dbt, and serves them in a live dashboard. Built to demonstrate
analytics-engineering fundamentals: layered modeling, idempotent ingestion,
incremental loads, data testing, and orchestration.

**Stack:** Python · Coinbase public API · Neon Postgres · dbt-core · GitHub Actions · Streamlit
**Cost:** $0 (all free tiers / open source)

## Architecture

```
Coinbase API ──> Python collector ──> Neon Postgres ──> dbt ──> Streamlit dashboard
 (live trades)   (GitHub Actions,      raw.trades      (staging  (live queries)
                  every 5 min)        (landing zone)   -> marts)
```

## How it works

- **Ingestion** (`collector/ingest.py`): pulls the most recent trades for several
  products and upserts them into `raw.trades`. The composite primary key
  `(product_id, trade_id)` plus `ON CONFLICT DO NOTHING` makes every run
  **idempotent** — overlapping pulls never create duplicates.
- **Orchestration** (`.github/workflows/ingest.yml`): GitHub Actions runs the
  collector on a 5-minute cron. Free and unlimited on public repos.
- **Warehouse**: Neon serverless Postgres. The `raw` schema holds untouched
  source data; dbt builds clean models into the `staging` and `marts` schemas.
- **Modeling** (dbt): `stg_trades` (typed, 1:1 with source) → marts
  `dim_products`, an **incremental** `fct_trades`, and `agg_price_1m`
  (1-minute OHLCV + VWAP candles). Source freshness checks gate on load time and
  data tests (not_null, unique, accepted_values, relationships) run on every build.
- **Dashboard** (Streamlit, Phase 3): queries Neon live so the view is always current.

## dbt models

```
source: raw.trades
   └─ stg_trades (view)                clean, typed, lowercased side
        ├─ dim_products (table)        one row per market (base/quote split)
        └─ fct_trades (incremental)    trade grain; loads only new rows
              └─ agg_price_1m (table)  1-min OHLCV + VWAP per product
```

Run the transformations (after Phase 1 data is landing):

```bash
pip install dbt-postgres
cp profiles.yml.example profiles.yml      # then set DBT_PG_* env vars (see file)
export DBT_PROFILES_DIR=.
dbt deps                 # install dbt_utils
dbt build                # run models + all data tests
dbt source freshness     # warn >15 min stale, error >60 min
dbt docs generate && dbt docs serve   # lineage graph / docs
```

## Dashboard

A Streamlit app (`dashboard/app.py`) that reads the dbt marts from Neon **live on
every page load** — collector feeds `raw`, dbt builds `marts`, the dashboard queries
`marts` directly, so the view is always current. It shows per-product 1-minute
candlesticks (with a VWAP overlay), KPI metrics, a volume chart, and recent trades.
Connection pooling and `ttl` caching keep it fast without hammering the database.

```bash
pip install -r dashboard/requirements.txt
cp .streamlit/secrets.toml.example .streamlit/secrets.toml   # paste your NEON_DSN
streamlit run dashboard/app.py                               # opens localhost:8501
```

Deployed free on Streamlit Community Cloud; the `NEON_DSN` secret is set in the app's
Settings → Secrets (never committed).

## Run locally

```bash
python -m venv venv && source venv/bin/activate   # Windows: .\venv\Scripts\Activate.ps1
pip install -r collector/requirements.txt
export NEON_DSN="postgresql://...@...neon.tech/db?sslmode=require"
python collector/ingest.py
```

## Status

- [x] Phase 1 — ingestion + warehouse (live, automated)
- [x] Phase 2 — dbt models, tests, freshness
- [x] Phase 3 — live dashboard (Streamlit, candlesticks + VWAP)
