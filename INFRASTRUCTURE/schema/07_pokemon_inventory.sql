-- pokemon_inventory — your owned cards. Field set per Briefing v7 §9.2 exactly.

CREATE TABLE IF NOT EXISTS pokemon_inventory (
    inv_id                  BIGSERIAL PRIMARY KEY,
    card_id                 INTEGER NOT NULL REFERENCES pokemon_cards(card_id) ON DELETE RESTRICT,
    grading_company         TEXT NOT NULL,
    grade                   NUMERIC(3,1) NOT NULL,
    label_variant           TEXT,                  -- cgc_blue_label_legacy / cgc_pristine / psa_perfect_10 / sgc_pristine / standard
    cert_number             TEXT,
    feature                 TEXT,                  -- 1st Edition / Shadowless / Unlimited / Holo / Confetti Holo
    collection_flag         BOOLEAN NOT NULL DEFAULT FALSE,   -- part of a target collection — do not flip
    collection_name         TEXT,                  -- team_rocket_1st_ed / mcdonalds_2025
    cost_basis              NUMERIC(12,2) NOT NULL,            -- total acquisition + grading cost
    current_market_value    NUMERIC(12,2),                     -- updated nightly from card_price_metrics
    unrealized_pnl          NUMERIC(12,2) GENERATED ALWAYS AS (current_market_value - cost_basis) STORED,
    unrealized_pnl_pct      NUMERIC(7,2),                       -- computed nightly
    status                  TEXT NOT NULL DEFAULT 'holding',    -- holding / listed / at_grader / sold
    provenance_flag         BOOLEAN NOT NULL DEFAULT FALSE,
    provenance_name         TEXT,                  -- e.g. Chumlee Collection
    provenance_premium_pct  NUMERIC(7,2),
    photo_path              TEXT,                  -- GitHub path
    photo_naming            TEXT,                  -- [GRADER][SERIAL#]-[FEATURE][CARD NAME]-[SET][SET#]
    acquired_date           DATE,
    days_held               INTEGER GENERATED ALWAYS AS (
        CASE WHEN acquired_date IS NULL THEN NULL
             ELSE (CURRENT_DATE - acquired_date) END
    ) STORED,
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inventory_status     ON pokemon_inventory(status);
CREATE INDEX IF NOT EXISTS idx_inventory_collection ON pokemon_inventory(collection_flag, collection_name);
CREATE INDEX IF NOT EXISTS idx_inventory_card       ON pokemon_inventory(card_id, grading_company, grade);
