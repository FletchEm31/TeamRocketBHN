-- grading_pipeline — cards currently submitted to graders.
-- Tracks submission lifecycle from sent → received → graded → returned.
-- A grading_pipeline row converts to a pokemon_inventory row on return.

CREATE TABLE IF NOT EXISTS grading_pipeline (
    pipe_id           BIGSERIAL PRIMARY KEY,
    card_id           INTEGER NOT NULL REFERENCES pokemon_cards(card_id) ON DELETE RESTRICT,
    grading_company   TEXT NOT NULL,
    service_tier      TEXT,                  -- 'value' / 'standard' / 'express' / 'super_express' / 'walkthrough'
    submission_id     TEXT,                  -- grader-assigned tracking
    target_grade      NUMERIC(3,1),          -- your prediction (for tracking hit rate)
    actual_grade      NUMERIC(3,1),          -- filled when returned
    label_variant     TEXT,
    feature           TEXT,                  -- 1st Edition / Shadowless / etc.
    submission_cost   NUMERIC(8,2) NOT NULL,
    card_acquisition_cost NUMERIC(12,2),
    total_basis       NUMERIC(12,2) GENERATED ALWAYS AS (
        COALESCE(submission_cost,0) + COALESCE(card_acquisition_cost,0)
    ) STORED,
    sent_date         DATE,
    received_by_grader_date DATE,
    grade_assigned_date DATE,
    returned_date     DATE,
    status            TEXT NOT NULL DEFAULT 'sent',  -- sent / received / grading / graded / returned / lost
    cert_number       TEXT,
    photo_path        TEXT,
    notes             TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pipe_status ON grading_pipeline(status);
CREATE INDEX IF NOT EXISTS idx_pipe_card   ON grading_pipeline(card_id);
