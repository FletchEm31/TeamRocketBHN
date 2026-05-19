-- set_index — daily snapshot of set-level performance.
-- One row per (set_code, snapshot_date) — feeds the "Set Value Swing"
-- triggers (15%/7d, 20%/30d, 30%/3mo, 50%/6mo per Briefing §8.1).

CREATE TABLE IF NOT EXISTS set_index (
    snapshot_id         BIGSERIAL PRIMARY KEY,
    set_code            TEXT NOT NULL,
    snapshot_date       DATE NOT NULL,
    -- Composite value of the set basket (sum of card values at canonical grade)
    index_value_total   NUMERIC(14,2) NOT NULL,
    -- Index broken down by grader
    index_value_psa     NUMERIC(14,2),
    index_value_cgc     NUMERIC(14,2),
    index_value_bgs     NUMERIC(14,2),
    index_value_sgc     NUMERIC(14,2),
    -- Per-window deltas vs prior snapshot (used by triggers)
    delta_7day_pct      NUMERIC(7,2),
    delta_30day_pct     NUMERIC(7,2),
    delta_3mo_pct       NUMERIC(7,2),
    delta_6mo_pct       NUMERIC(7,2),
    delta_1yr_pct       NUMERIC(7,2),
    -- High-grade share of recent sales (drives market_health triggers)
    high_grade_share    NUMERIC(5,2),  -- % of last-30d sales at grade >= 9
    raw_graded_spread   NUMERIC(7,2),  -- raw price as % below graded avg
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (set_code, snapshot_date)
);

CREATE INDEX IF NOT EXISTS idx_set_index_date ON set_index(set_code, snapshot_date DESC);
