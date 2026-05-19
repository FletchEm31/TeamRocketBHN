-- data_import_log — auditable record of every import run from every source.
-- One row per workflow execution. Used to detect stale ingest, debug source
-- failures, and verify HORIZON has fresh data.

CREATE TABLE IF NOT EXISTS data_import_log (
    log_id             BIGSERIAL PRIMARY KEY,
    source_id          TEXT NOT NULL REFERENCES data_sources(source_id) ON DELETE RESTRICT,
    workflow_name      TEXT NOT NULL,             -- 'EBAY-CARD-INGEST' / 'PRICECHARTING-NIGHTLY' / etc.
    run_started_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    run_finished_at    TIMESTAMPTZ,
    status             TEXT NOT NULL DEFAULT 'running',   -- running / success / partial / failed
    rows_fetched       INTEGER NOT NULL DEFAULT 0,
    rows_inserted      INTEGER NOT NULL DEFAULT 0,
    rows_updated       INTEGER NOT NULL DEFAULT 0,
    rows_skipped       INTEGER NOT NULL DEFAULT 0,
    rows_error         INTEGER NOT NULL DEFAULT 0,
    error_message      TEXT,
    request_payload    JSONB,
    response_summary   JSONB,
    n8n_execution_id   TEXT
);

CREATE INDEX IF NOT EXISTS idx_import_log_source_time ON data_import_log(source_id, run_started_at DESC);
CREATE INDEX IF NOT EXISTS idx_import_log_status      ON data_import_log(status, run_started_at DESC) WHERE status IN ('failed', 'partial');
