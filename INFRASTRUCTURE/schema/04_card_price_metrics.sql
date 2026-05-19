-- card_price_metrics — pre-computed nightly aggregates per (card, grader, grade).
-- Read-path table for triggers + the Pokemon: Blackhole battle UI HP%.
-- Refreshed by the "Nightly metrics aggregation" n8n workflow (build step 9).

CREATE TABLE IF NOT EXISTS card_price_metrics (
    metric_id          BIGSERIAL PRIMARY KEY,
    card_id            INTEGER NOT NULL REFERENCES pokemon_cards(card_id) ON DELETE CASCADE,
    grading_company    TEXT NOT NULL,
    grade              NUMERIC(3,1) NOT NULL,
    label_variant      TEXT,
    -- Windowed averages
    avg_7day           NUMERIC(12,2),
    avg_30day          NUMERIC(12,2),
    avg_90day          NUMERIC(12,2),
    avg_6mo            NUMERIC(12,2),
    avg_1yr            NUMERIC(12,2),
    avg_7yr            NUMERIC(12,2),
    -- Highs / lows
    ath                NUMERIC(12,2),
    ath_date           DATE,
    atl                NUMERIC(12,2),
    atl_date           DATE,
    -- Recent sale signals
    last_sale_price    NUMERIC(12,2),
    last_sale_date     DATE,
    sales_count_30day  INTEGER NOT NULL DEFAULT 0,
    sales_count_90day  INTEGER NOT NULL DEFAULT 0,
    days_to_sell_avg   INTEGER,
    -- Liquidity / appreciation %
    set_appr_1m_pct    NUMERIC(7,2),
    set_appr_3m_pct    NUMERIC(7,2),
    set_appr_6m_pct    NUMERIC(7,2),
    set_appr_12m_pct   NUMERIC(7,2),
    card_appr_1m_pct   NUMERIC(7,2),
    card_appr_3m_pct   NUMERIC(7,2),
    card_appr_6m_pct   NUMERIC(7,2),
    card_appr_12m_pct  NUMERIC(7,2),
    -- Confidence (per project_pricing_confidence memory)
    confidence_state   TEXT,  -- UNCHARTED | THIN | LOW | AVERAGE | HIGH | IDEAL
    refreshed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (card_id, grading_company, grade, label_variant)
);

CREATE INDEX IF NOT EXISTS idx_metrics_lookup ON card_price_metrics(card_id, grading_company, grade);
