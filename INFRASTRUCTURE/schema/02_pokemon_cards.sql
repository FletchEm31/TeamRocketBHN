-- pokemon_cards — master card registry. All cards, all sets, all variants.
-- One row per (set, card_number, feature) combination. Seed with ~600 cards
-- across the 5 vintage sets in active buying criteria (Base / Jungle /
-- Fossil / Team Rocket / Gym Challenge) plus McDonald's 2025 holds.

CREATE TABLE IF NOT EXISTS pokemon_cards (
    card_id        SERIAL PRIMARY KEY,
    set_code       TEXT NOT NULL,            -- 'base' | 'jungle' | 'fossil' | 'team_rocket' | 'gym_heroes' | 'gym_challenge' | 'mcdonalds_2025'
    set_name       TEXT NOT NULL,            -- display name e.g. 'Team Rocket'
    card_number    TEXT NOT NULL,            -- '42/82'
    card_name      TEXT NOT NULL,            -- 'Dark Persian'
    pokemon_name   TEXT,                     -- 'Persian' (for sprite lookup)
    dex_number     INTEGER,                  -- 53
    rarity         TEXT,                     -- 'common' | 'uncommon' | 'rare' | 'holo' | 'rare_holo'
    card_type      TEXT,                     -- 'pokemon' | 'trainer' | 'energy'
    is_holo        BOOLEAN DEFAULT FALSE,
    artist         TEXT,
    sprite_key     TEXT,                     -- key into pokemon_card_map.json sprite map
    photo_path     TEXT,                     -- GitHub path: [GRADER][SERIAL#]-[FEATURE][CARD NAME]-[SET][SET#]
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (set_code, card_number)
);

CREATE INDEX IF NOT EXISTS idx_cards_set ON pokemon_cards(set_code);
CREATE INDEX IF NOT EXISTS idx_cards_name ON pokemon_cards(card_name);
CREATE INDEX IF NOT EXISTS idx_cards_dex ON pokemon_cards(dex_number);
