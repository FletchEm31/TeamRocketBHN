-- market_transactions — every comp sale ingested from any source.
-- Powers the entire market intelligence engine. card_price_metrics aggregates
-- from here nightly. Triggers and HORIZON alerts read both.

CREATE TABLE IF NOT EXISTS market_transactions (
    txn_id          BIGSERIAL PRIMARY KEY,
    card_id         INTEGER NOT NULL REFERENCES pokemon_cards(card_id) ON DELETE RESTRICT,
    source_id       TEXT NOT NULL REFERENCES data_sources(source_id) ON DELETE RESTRICT,
    grading_company TEXT NOT NULL,            -- PSA / CGC / BGS / SGC / TAG / MISC / RAW
    grade           NUMERIC(3,1) NOT NULL,    -- 1.0 .. 10.0
    label_variant   TEXT,                     -- cgc_blue_label_legacy / cgc_pristine / psa_perfect_10 / standard
    feature         TEXT,                     -- 1st Edition / Shadowless / Unlimited / Holo / etc
    sale_price      NUMERIC(12,2) NOT NULL,
    shipping        NUMERIC(8,2),
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    sale_date       DATE NOT NULL,
    listing_url     TEXT,
    seller          TEXT,                     -- eBay username / auction house
    platform        TEXT,                     -- ebay / pwcc / heritage / etc
    external_id     TEXT,                     -- the source's unique id (eBay item id, PriceCharting id)
    raw_payload     JSONB,                    -- full raw row from the source for audit
    imported_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (source_id, external_id)            -- dedupe same listing across re-pulls
);

CREATE INDEX IF NOT EXISTS idx_mtxn_card_grade ON market_transactions(card_id, grading_company, grade);
CREATE INDEX IF NOT EXISTS idx_mtxn_sale_date  ON market_transactions(sale_date DESC);
CREATE INDEX IF NOT EXISTS idx_mtxn_card_date  ON market_transactions(card_id, sale_date DESC);
