-- ebay_sales — your completed @fletchketchem sales with full P&L.
-- One row per sold order. Source of truth for realized profit and ROI.

CREATE TABLE IF NOT EXISTS ebay_sales (
    sale_id             BIGSERIAL PRIMARY KEY,
    ebay_order_id       TEXT UNIQUE,                 -- eBay's order id
    inv_id              INTEGER REFERENCES pokemon_inventory(inv_id) ON DELETE SET NULL,
    card_id             INTEGER NOT NULL REFERENCES pokemon_cards(card_id) ON DELETE RESTRICT,
    grading_company     TEXT NOT NULL,
    grade               NUMERIC(3,1) NOT NULL,
    label_variant       TEXT,
    feature             TEXT,
    -- Revenue side
    sale_price          NUMERIC(12,2) NOT NULL,
    shipping_collected  NUMERIC(8,2) NOT NULL DEFAULT 0,
    sales_tax_collected NUMERIC(8,2) NOT NULL DEFAULT 0,
    -- Costs side
    cost_basis          NUMERIC(12,2) NOT NULL,
    ebay_fee_amount     NUMERIC(8,2) NOT NULL DEFAULT 0,
    ebay_fee_pct        NUMERIC(5,2),
    shipping_cost       NUMERIC(8,2) NOT NULL DEFAULT 0,
    promoted_listing_fee NUMERIC(8,2),
    admin_cost          NUMERIC(8,2) NOT NULL DEFAULT 0,
    refund_amount       NUMERIC(12,2) NOT NULL DEFAULT 0,
    -- Computed
    gross_profit        NUMERIC(12,2) GENERATED ALWAYS AS (
        sale_price + shipping_collected - cost_basis - ebay_fee_amount
        - shipping_cost - COALESCE(promoted_listing_fee,0) - admin_cost
        - refund_amount
    ) STORED,
    roi_pct             NUMERIC(7,2),
    -- Metadata
    buyer_username      TEXT,
    sale_date           DATE NOT NULL,
    payout_date         DATE,
    status              TEXT NOT NULL DEFAULT 'sold', -- sold / refunded / cancelled / chargeback
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ebay_sales_date   ON ebay_sales(sale_date DESC);
CREATE INDEX IF NOT EXISTS idx_ebay_sales_card   ON ebay_sales(card_id, grading_company, grade);
CREATE INDEX IF NOT EXISTS idx_ebay_sales_status ON ebay_sales(status);
