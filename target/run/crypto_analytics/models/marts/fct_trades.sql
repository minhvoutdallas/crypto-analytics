
      
        delete from "neondb"."marts"."fct_trades" as DBT_INTERNAL_DEST
        where (product_id, trade_id) in (
            select distinct product_id, trade_id
            from "fct_trades__dbt_tmp014919145236" as DBT_INTERNAL_SOURCE
        );

    

    insert into "neondb"."marts"."fct_trades" ("product_id", "trade_id", "price_usd", "size", "side", "traded_at", "ingested_at")
    (
        select "product_id", "trade_id", "price_usd", "size", "side", "traded_at", "ingested_at"
        from "fct_trades__dbt_tmp014919145236"
    )
  