-- deal_watchlist — active deal alert queue.
-- A row exists per outstanding HORIZON alert; updated as alert lifecycle
-- progresses (fired → seen → acted_on → resolved). The Pokemon: Blackhole
-- battle cutscene pulls from here when alert_tier in (1, 2).

CREATE TABLE IF NOT EXISTS deal_watchlist (
    alert_id           BIGSERIAL PRIMARY KEY,
    listing_id         BIGINT,                    -- FK to ebay_listings.id (table exists already; FK added when convenient)
    card_id            INTEGER REFERENCES pokemon_cards(card_id) ON DELETE SET NULL,
    grading_company    TEXT NOT NULL,
    grade              NUMERIC(3,1) NOT NULL,
    label_variant      TEXT,
    seller_username    TEXT,
    listed_price       NUMERIC(12,2) NOT NULL,
    market_avg_used    NUMERIC(12,2),             -- snapshot at alert fire time
    hp_percent         NUMERIC(5,2),              -- listed / market * 100
    alert_tier         INTEGER NOT NULL,          -- 1 / 2 / 3
    trigger_type       TEXT NOT NULL,             -- recase_arbitrage / sgc_undervalue / set_swing / pop_spike / etc.
    trigger_payload    JSONB,                     -- full CARD_DATA-shaped object pushed to HORIZON / Blackhole
    fired_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    seen_at            TIMESTAMPTZ,
    acted_on_at        TIMESTAMPTZ,
    action_taken       TEXT,                      -- bought / offered / watched / passed / ran
    resolved_at        TIMESTAMPTZ,
    resolution         TEXT,                      -- won / lost / expired / dismissed
    notes              TEXT
);

CREATE INDEX IF NOT EXISTS idx_watchlist_open       ON deal_watchlist(resolved_at) WHERE resolved_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_watchlist_tier_time  ON deal_watchlist(alert_tier, fired_at DESC);
CREATE INDEX IF NOT EXISTS idx_watchlist_card       ON deal_watchlist(card_id);
