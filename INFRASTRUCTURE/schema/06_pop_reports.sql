-- pop_reports — population snapshots, all graders, historical.
-- Time-series — one row per (card, grader, grade, snapshot_date).
-- Powers the pop-spike / pop-frozen triggers and the rarity tier display.

CREATE TABLE IF NOT EXISTS pop_reports (
    pop_id            BIGSERIAL PRIMARY KEY,
    card_id           INTEGER NOT NULL REFERENCES pokemon_cards(card_id) ON DELETE CASCADE,
    grading_company   TEXT NOT NULL,
    grade             NUMERIC(3,1) NOT NULL,
    label_variant     TEXT,
    pop_count         INTEGER NOT NULL,
    snapshot_date     DATE NOT NULL,
    source_id         TEXT NOT NULL REFERENCES data_sources(source_id) ON DELETE RESTRICT,
    -- Pre-computed deltas for quick trigger evaluation
    pop_change_7day   INTEGER,
    pop_change_30day  INTEGER,
    pop_change_90day  INTEGER,
    raw_payload       JSONB,
    imported_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (card_id, grading_company, grade, label_variant, snapshot_date)
);

CREATE INDEX IF NOT EXISTS idx_pop_lookup ON pop_reports(card_id, grading_company, grade);
CREATE INDEX IF NOT EXISTS idx_pop_date   ON pop_reports(snapshot_date DESC);
