-- data_sources — registry of every data source feeding eventhorizon.
-- Every market_transactions / pop_reports / data_import_log row carries
-- a source_id pointing here. Per Briefing v7 §7.1 (SRC-001 through SRC-014).

CREATE TABLE IF NOT EXISTS data_sources (
    source_id    TEXT PRIMARY KEY,          -- e.g. 'SRC-001'
    source_name  TEXT NOT NULL,              -- e.g. 'eBay Feed API'
    source_type  TEXT NOT NULL,              -- 'real_time' | 'historical' | 'scraper' | 'api' | 'csv'
    phase        TEXT NOT NULL DEFAULT 'phase_1',
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    cost_usd_mo  NUMERIC(10,2),              -- monthly subscription cost (e.g. 9.99 for PSA RapidAPI)
    config       JSONB,                      -- per-source config blob (endpoints, scopes, polling intervals)
    notes        TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_data_sources_active ON data_sources(is_active);

-- Seed the 14 registered sources per Briefing v7 §7.1
INSERT INTO data_sources (source_id, source_name, source_type, phase, cost_usd_mo, notes) VALUES
    ('SRC-001', 'eBay Feed API',          'real_time',  'phase_1', NULL,  'Live sold-listing stream'),
    ('SRC-002', 'eBay Browse API Sold',   'historical', 'phase_1', NULL,  '90-day sold history'),
    ('SRC-003', 'PriceCharting API',      'api',        'phase_1', NULL,  '7-year historical price data'),
    ('SRC-004', 'PriceCharting CSV',      'csv',        'phase_1', NULL,  'Bulk historical import'),
    ('SRC-005', 'PSA Auction Prices',     'scraper',    'phase_1', NULL,  'Auction comp scraper'),
    ('SRC-006', 'PSA Pop Report',         'api',        'phase_1', 9.99,  'RapidAPI psa-card-population-report'),
    ('SRC-007', 'CGC Pop Report',         'scraper',    'phase_1', NULL,  'CGC public pop report scraper'),
    ('SRC-008', 'BGS Pop Report',         'scraper',    'phase_1', NULL,  'BGS public pop report scraper'),
    ('SRC-009', 'SGC Pop Report',         'scraper',    'phase_1', NULL,  'SGC public pop report scraper'),
    ('SRC-010', 'TAG Pop Report',         'scraper',    'phase_1', NULL,  'TAG market data only'),
    ('SRC-011', '130point.com',           'scraper',    'phase_1', NULL,  'eBay sold history beyond 90 days'),
    ('SRC-012', 'PWCC Marketplace',       'scraper',    'phase_2', NULL,  'Graded auctions'),
    ('SRC-013', 'Heritage Auctions',      'scraper',    'phase_2', NULL,  'Premium comps'),
    ('SRC-014', 'TCGPlayer',              'api',        'phase_2', NULL,  'Raw price baseline')
ON CONFLICT (source_id) DO NOTHING;
