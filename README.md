# TEAM ROCKET BHN — POKEMON BLACKHOLE
### Where the game meets the markets.

> **Pokemon: Blackhole** is a GBA-style Pokemon FireRed/LeafGreen battle interface  
> built on top of real Pokemon card market intelligence.  
> Part of the **Team Rocket BHN — Pokemon Market — Blackhole Network** operation.

---

## What Is This

When HORIZON detects a card deal alert, it triggers a full Pokemon battle cutscene.

- The **seller** becomes your **rival trainer**
- The **card being listed** becomes the **Pokemon**
- The **HP bar** is the deal quality — listed price as % of market value
- The **Pokemon's level** is the **card grade** (Lv9.5, Lv10, Lv8)
- The **trainer's badge** is the **grading company** (PSA=red, CGC=blue, BGS=gold, SGC=black)
- **Catching the Pokemon** = **buying the card**

Someone who played FireRed should see this screen and think *"wait, is that actually Pokemon?"*  
Then they read `DARK PERSIAN 42/82 — CGC 9.5 — Lv9.5` and realize what it actually is.  
**That moment of recognition is the entire product.**

---

## The HP Bar System

The HP bar IS the deal intelligence. Full HP = listed at market price. Depleted HP = deal.

| HP % | Color | Status | What It Means |
|------|-------|--------|---------------|
| 85–100% | Green | Full health | At market. No urgency. |
| 60–84% | Green | Healthy | Slight discount. Watch it. |
| 40–59% | Yellow | Weakened | Good offer territory. |
| 20–39% | Orange | Danger | Tier 1 Strong Buy. Act soon. |
| 1–19% | Red flashing | Critical | Distressed sale. Catch it NOW. |

---

## Trainer Class System

Every grading company has a trainer class. The badge appears on the rival trainer's chest.

| Grading Company | Trainer Class | Badge Color | Pre-Battle Line |
|----------------|---------------|-------------|-----------------|
| PSA | PSA TRAINER | Red | *"My card has the red label. The most trusted name in the hobby."* |
| CGC | CGC TRAINER | Blue | *"CGC certified. Blue label. Gem Mint. This won't last long."* |
| BGS | BECKETT MASTER | Gold | *"Subgrades don't lie. Are you even qualified to catch this?"* |
| SGC | SGC COLLECTOR | Dark Gray | *"SGC grades harder than you know. Worth more than the market thinks."* |
| TAG | TAG SPECIALIST | Purple | *"AI graded. 1000 point scale. Can your system handle it?"* |

---

## Audio Tiers

Battle music escalates with deal quality — exactly like the game.

| Alert Tier | Battle Music | Victory Music |
|------------|-------------|---------------|
| Tier 3 Watch | Trainer Battle | Trainer Victory |
| Tier 2 Buy | Trainer Battle | Trainer Victory |
| Tier 1 Strong Buy | **Gym Leader Battle** | **Gym Leader Victory** |
| Tier 1 Critical | **Gym Leader Battle** | **Gym Leader Victory** |

> Audio is **OFF by default**. Toggle with the ♪ button.

---

## The World Mapping

| Pokemon World | Real World (Team Rocket BHN) |
|---------------|------------------------------|
| Wild Pokemon appears | eBay listing detected by HORIZON |
| Trainer battle | You vs the eBay seller |
| Pokemon level | Card grade |
| Type badge | Grading company |
| HP bar | Listed price as % of market value |
| Catch it | Buy the card |
| Run away | Dismiss the alert |
| Rival trainer | The eBay seller |
| Your trainer | Team Rocket BHN / @fletchketchem |
| Pokédex | Collection tracker — TR 1st Ed + McDonald's 2025 |
| PC Box | Grading pipeline |
| Pokéball rows | Inventory counts per grade |
| Professor Oak | HORIZON AI agent |
| Pokédollars | Real P&L in USD |

---

## Repository Structure

```
TEAM ROCKET BHN - POKEMON BLACKHOLE/
├── battle/
│   └── index.html              ← Phase 1 — battle screen UI
├── dashboard/                  ← Phase 3 — inventory, pokédex, PC Box
├── assets/
│   ├── sprites/
│   │   ├── pokemon/
│   │   │   ├── frlg_pokemon_sheet.png
│   │   │   └── frlg_pokemon_sheet_gen2.png
│   │   └── trainers/
│   │       ├── frlg_trainers.png
│   │       └── frlg_player_sprites.png
│   └── audio/
│       ├── rival_appears.mp3
│       ├── battle_trainer.mp3
│       ├── victory_trainer.mp3
│       ├── battle_gym_leader.mp3
│       └── victory_gym_leader.mp3
├── data/
│   └── pokemon_card_map.json   ← maps card names to Pokemon sprites
└── DOCS/
    ├── TeamRocketBHN_PokemonMarket_Briefing_v7.docx
    └── PokemonBlackhole_ClaudeCode_Brief_Phase1.docx
```

---

## Build Phases

| Phase | Focus | Status |
|-------|-------|--------|
| **Phase 1 — UI** | Battle screen. Static hardcoded data. Nail the look and feel. | 🔄 In Progress |
| **Phase 2 — Logic** | Wire real mechanics. HP driven by price inputs. Dynamic everything. | ⏳ Pending |
| **Phase 3 — Live Data** | Connect to eventhorizon DB + eBay API. Real sellers, real prices. | ⏳ Pending |

---

## Part of Team Rocket BHN

This repo is part of the larger **Team Rocket BHN — Pokemon Market — Blackhole Network** operation.

| Layer | Name |
|-------|------|
| Network | Blackhole Network (BHN) |
| Division | Team Rocket BHN |
| App | Pokemon: Blackhole |
| eBay Store | @fletchketchem |
| Database | eventhorizon (PostgreSQL) |
| AI Agent | HORIZON |

---

*Nothing escapes the Blackhole.*
