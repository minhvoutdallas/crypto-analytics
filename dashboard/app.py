"""
Phase 3 — the live dashboard.

A Streamlit app that reads the dbt marts straight from Neon on every load, so the
view is always current. The app does almost NO logic itself: the collector landed
the data (Phase 1), dbt modeled it into clean OHLCV candles (Phase 2), and this
file just connects, queries, and draws.

Run locally:   streamlit run dashboard/app.py
"""

import pandas as pd
import plotly.graph_objects as go
import sqlalchemy as sa
import streamlit as st

# ---------------------------------------------------------------------------
# Page setup — must be the first Streamlit call.
# ---------------------------------------------------------------------------
st.set_page_config(
    page_title="Real-Time Crypto Analytics",
    page_icon="📈",
    layout="wide",
)

# How long (seconds) to cache query results before re-fetching from Neon.
# This number is effectively "how live" the dashboard is.
REFRESH_TTL = 60


# ---------------------------------------------------------------------------
# Database connection.
# @st.cache_resource builds the SQLAlchemy engine ONCE and reuses it across
# re-runs, instead of opening a new connection every interaction.
# The DSN comes from st.secrets (.streamlit/secrets.toml locally, or the
# Streamlit Cloud secrets UI when deployed) — never hard-coded.
# ---------------------------------------------------------------------------
@st.cache_resource
def get_engine() -> sa.Engine:
    return sa.create_engine(st.secrets["NEON_DSN"], pool_pre_ping=True)


# ---------------------------------------------------------------------------
# Data loaders.
# @st.cache_data(ttl=...) caches the returned DataFrame for REFRESH_TTL seconds.
# So clicking around is instant, but the data still refreshes every minute.
# ---------------------------------------------------------------------------
@st.cache_data(ttl=REFRESH_TTL)
def load_products() -> list[str]:
    q = "select product_id from marts.dim_products order by product_id"
    return pd.read_sql(q, get_engine())["product_id"].tolist()


@st.cache_data(ttl=REFRESH_TTL)
def load_candles(product_id: str, limit: int = 300) -> pd.DataFrame:
    # Pull the most recent `limit` one-minute candles for this product,
    # then sort ascending so the chart reads left-to-right in time.
    q = sa.text(
        """
        select minute, open_price, high_price, low_price, close_price, volume, vwap
        from marts.agg_price_1m
        where product_id = :pid
        order by minute desc
        limit :lim
        """
    )
    df = pd.read_sql(q, get_engine(), params={"pid": product_id, "lim": limit})
    return df.sort_values("minute").reset_index(drop=True)


@st.cache_data(ttl=REFRESH_TTL)
def load_recent_trades(product_id: str, limit: int = 50) -> pd.DataFrame:
    q = sa.text(
        """
        select traded_at, price_usd, size, side
        from marts.fct_trades
        where product_id = :pid
        order by traded_at desc
        limit :lim
        """
    )
    return pd.read_sql(q, get_engine(), params={"pid": product_id, "lim": limit})


# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------
st.title("📈 Real-Time Crypto Market Analytics")
st.caption(
    "Live trades from Coinbase → Neon Postgres → dbt marts → this dashboard. "
    "Data refreshes every minute."
)

# Sidebar: pick a product, and a manual refresh button.
products = load_products()
if not products:
    st.warning("No data yet — make sure the collector has run and `dbt build` has built the marts.")
    st.stop()

with st.sidebar:
    st.header("Controls")
    product = st.selectbox("Market", products)
    if st.button("🔄 Refresh now"):
        st.cache_data.clear()   # drop cached results so the next read hits Neon
        st.rerun()              # re-run the script top-to-bottom

candles = load_candles(product)

if candles.empty:
    st.warning(f"No candles for {product} yet.")
    st.stop()

# --- KPI metrics row ---
latest = candles.iloc[-1]
first = candles.iloc[0]
change_pct = (latest.close_price - first.open_price) / first.open_price * 100

c1, c2, c3, c4 = st.columns(4)
c1.metric("Last price", f"${latest.close_price:,.2f}", f"{change_pct:+.2f}% (window)")
c2.metric("High (window)", f"${candles.high_price.max():,.2f}")
c3.metric("Low (window)", f"${candles.low_price.min():,.2f}")
c4.metric("Volume (window)", f"{candles.volume.sum():,.2f}")

# --- Candlestick chart (+ VWAP overlay) ---
fig = go.Figure()
fig.add_trace(
    go.Candlestick(
        x=candles.minute,
        open=candles.open_price,
        high=candles.high_price,
        low=candles.low_price,
        close=candles.close_price,
        name=product,
    )
)
fig.add_trace(
    go.Scatter(
        x=candles.minute,
        y=candles.vwap,
        mode="lines",
        line=dict(width=1.2),
        name="VWAP",
    )
)
fig.update_layout(
    height=460,
    margin=dict(l=0, r=0, t=30, b=0),
    xaxis_rangeslider_visible=False,
    title=f"{product} — 1-minute candles",
)
st.plotly_chart(fig, use_container_width=True)

# --- Volume + recent trades, side by side ---
left, right = st.columns([2, 1])
with left:
    st.subheader("Volume")
    st.bar_chart(candles.set_index("minute")["volume"], height=200)
with right:
    st.subheader("Recent trades")
    st.dataframe(
        load_recent_trades(product),
        use_container_width=True,
        height=220,
        hide_index=True,
    )

st.caption(f"Showing {len(candles)} most-recent 1-minute candles · cached up to {REFRESH_TTL}s.")
