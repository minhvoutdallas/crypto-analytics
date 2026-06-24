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
  source data; dbt builds clean models in `public` (Phase 2).
- **Modeling** (dbt, Phase 2): staging → marts, incremental fact table, source
  freshness checks, and data tests.
- **Dashboard** (Streamlit, Phase 3): queries Neon live so the view is always current.

## Run locally

```bash
python -m venv venv && source venv/bin/activate   # Windows: .\venv\Scripts\Activate.ps1
pip install -r collector/requirements.txt
export NEON_DSN="postgresql://...@...neon.tech/db?sslmode=require"
python collector/ingest.py
```

## Status

- [x] Phase 1 — ingestion + warehouse (live, automated)
- [ ] Phase 2 — dbt models, tests, freshness
- [ ] Phase 3 — live dashboard
