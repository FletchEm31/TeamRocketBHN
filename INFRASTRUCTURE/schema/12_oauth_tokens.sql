-- oauth_tokens — single source of truth for OAuth access/refresh tokens.
-- Used by the eBay token-refresh n8n workflow (INFRASTRUCTURE/n8n/ebay-oauth-refresh.json).
-- One row per (provider, environment) pair. Updated on every refresh.

CREATE TABLE IF NOT EXISTS oauth_tokens (
    token_id        SERIAL PRIMARY KEY,
    provider        TEXT NOT NULL,             -- 'ebay' / 'pricecharting' / etc.
    environment     TEXT NOT NULL DEFAULT 'production', -- 'production' | 'sandbox'
    access_token    TEXT NOT NULL,
    refresh_token   TEXT,
    token_type      TEXT NOT NULL DEFAULT 'Bearer',
    scope           TEXT,
    expires_at      TIMESTAMPTZ NOT NULL,       -- when access_token becomes invalid
    refreshed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_refresh_status TEXT NOT NULL DEFAULT 'ok', -- ok / failed
    last_refresh_error  TEXT,
    UNIQUE (provider, environment)
);

CREATE INDEX IF NOT EXISTS idx_oauth_expires ON oauth_tokens(provider, expires_at);

-- Helper: rows expiring within 10 minutes — the refresh workflow polls for these
CREATE OR REPLACE VIEW oauth_tokens_due_refresh AS
    SELECT * FROM oauth_tokens
     WHERE expires_at < NOW() + INTERVAL '10 minutes';
