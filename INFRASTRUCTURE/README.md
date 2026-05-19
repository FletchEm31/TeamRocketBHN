# INFRASTRUCTURE

Schema files and n8n workflows for the BHN infrastructure layer. **This directory is the source of truth — the live LA hub Postgres and NJ n8n instance should match what's here.**

## Layout

```
INFRASTRUCTURE/
├── schema/                # PostgreSQL DDL — run on eventhorizon (LA hub)
│   ├── 00_extensions.sql
│   ├── 01_data_sources.sql      # source registry, seeded SRC-001..014
│   ├── 02_pokemon_cards.sql     # master card registry (needs seed)
│   ├── 03_market_transactions.sql
│   ├── 04_card_price_metrics.sql
│   ├── 05_set_index.sql
│   ├── 06_pop_reports.sql
│   ├── 07_pokemon_inventory.sql # per Briefing v7 §9.2
│   ├── 08_grading_pipeline.sql
│   ├── 09_ebay_sales.sql
│   ├── 10_deal_watchlist.sql
│   ├── 11_data_import_log.sql
│   └── 12_oauth_tokens.sql      # token storage for refresh workflow
└── n8n/
    └── ebay-oauth-refresh.json  # 90-min cron token refresh (fixes 2hr expiry)
```

**Note:** `ebay_listings` table is already deployed per most recent passoff. Not duplicated here.

## Deploy: schema

From the LA hub, with `psql` connected to eventhorizon:

```bash
cd INFRASTRUCTURE/schema
for f in $(ls *.sql | sort); do
    echo "Running $f"
    psql -d eventhorizon -f "$f"
done
```

Files are numbered for run order. `00_extensions.sql` must run first; `01_data_sources.sql` next (other tables FK to it).

Safe to re-run — every `CREATE TABLE` uses `IF NOT EXISTS` and the data_sources seed uses `ON CONFLICT DO NOTHING`.

## Deploy: eBay OAuth refresh workflow

1. **Seed the token row** in eventhorizon with your current eBay creds:

   ```sql
   INSERT INTO oauth_tokens (provider, environment, access_token, refresh_token, expires_at)
   VALUES ('ebay', 'production',
           '<CURRENT_ACCESS_TOKEN>',
           '<CURRENT_REFRESH_TOKEN>',
           NOW() + INTERVAL '90 minutes');
   ```

2. **Configure n8n credentials on the NJ node:**

   - Postgres: name = `eventhorizon`, connect to LA hub
   - HTTP Header Auth: name = `eBay client_id:client_secret (Basic)`, header `Authorization` = `Basic <base64(client_id:client_secret)>`

3. **Import the workflow:** n8n UI → Workflows → Import from File → pick `n8n/ebay-oauth-refresh.json`

4. **Activate** the workflow. It will run every 90 minutes, hitting `https://api.ebay.com/identity/v1/oauth2/token`, writing the new `access_token` + `expires_at` to `oauth_tokens`, and logging the run to `data_import_log`.

5. **Update EBAY-CARD-INGEST** to read the current token from the table instead of from a hard-coded credential:

   ```sql
   SELECT access_token FROM oauth_tokens WHERE provider = 'ebay' AND environment = 'production';
   ```

   Use the result as the `Authorization: Bearer <token>` header on the ingest API calls.

## What this unblocks

| Step | Status |
|---|---|
| 1. Deploy PostgreSQL schema to eventhorizon | ⚙️ schema files ready, you run psql |
| 2. Seed all 5 sets — all cards | TODO — needs card-list CSV → bulk load into `pokemon_cards` |
| 3–7. PriceCharting + PSA + grader workflows | TODO — schemas ready to receive data |
| 8. eBay Feed API real-time ingestion | ✅ already live (EBAY-CARD-INGEST); will become reliable once refresh workflow lands |
| 9. Nightly metrics aggregation | TODO — `card_price_metrics` table ready to be written |
| 10. Nightly pop refresh | TODO — `pop_reports` table ready |
| 11. Trigger event workflows | TODO — `deal_watchlist` table ready |
| 12. HORIZON alert dispatch | TODO — schema fields for HP%, alert_tier, trigger_type, trigger_payload all present in `deal_watchlist` |

## Env vars expected (for future workflows)

```
EBAY_CLIENT_ID=
EBAY_CLIENT_SECRET=
PRICECHARTING_API_KEY=
PSA_RAPIDAPI_KEY=
HORIZON_WEBHOOK_URL=
```
