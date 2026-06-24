"""
Phase 1c - the collector.
Pulls recent trades from Coinbase's public API and lands them in raw.trades.
Run locally with NEON_DSN set; later GitHub Actions runs the exact same script.
"""
import os
import sys
import requests
import psycopg2
from psycopg2.extras import execute_values

# Which markets to track. Start small; add more later.
PRODUCTS = ["BTC-USD", "ETH-USD", "SOL-USD"]

# Read the DB connection string from an environment variable.
# We NEVER hard-code credentials in the script - that way the same file is safe
# to push to a public GitHub repo. Locally it comes from your shell/.env;
# in CI it comes from a GitHub secret.
DSN = os.environ.get("NEON_DSN")
if not DSN:
    sys.exit("ERROR: set the NEON_DSN environment variable first.")


def fetch(product: str) -> list[tuple]:
    """Get the most recent trades for one product and shape them into rows."""
    url = f"https://api.exchange.coinbase.com/products/{product}/trades"
    resp = requests.get(
        url,
        params={"limit": 100},                 # up to 100 most-recent trades
        headers={"User-Agent": "minh-portfolio"},  # Coinbase rejects requests with no UA
        timeout=15,
    )
    resp.raise_for_status()  # turn any 4xx/5xx into an exception instead of silent bad data
    rows = []
    for t in resp.json():
        # price and size arrive as STRINGS ("6225.32000000") - cast to float.
        # We keep trade_id as int. ts stays as the ISO string; Postgres parses it
        # into TIMESTAMPTZ on insert.
        rows.append((
            int(t["trade_id"]),
            product,
            float(t["price"]),
            float(t["size"]),
            t["side"],
            t["time"],
        ))
    return rows


def main():
    # Gather rows for every product into one batch.
    all_rows = [row for product in PRODUCTS for row in fetch(product)]

    # One connection, one transaction. `with` auto-commits on success / rolls back on error.
    with psycopg2.connect(DSN) as conn, conn.cursor() as cur:
        execute_values(
            cur,
            """
            INSERT INTO raw.trades
                (trade_id, product_id, price, size, side, ts)
            VALUES %s
            ON CONFLICT (product_id, trade_id) DO NOTHING
            """,
            all_rows,
        )
        # rowcount = how many rows were ACTUALLY inserted (new trades),
        # not how many we tried. Duplicates skipped by ON CONFLICT don't count.
        inserted = cur.rowcount

    print(f"Fetched {len(all_rows)} trades, inserted {inserted} new rows.")


if __name__ == "__main__":
    main()
