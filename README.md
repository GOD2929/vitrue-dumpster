<div align="center">

# Vitrue Dumpster Diving

A premium, fully-optimized dumpster diving script for **FiveM** servers running **Qbox** or **QBCore** with **ox_lib** and **ox_target**.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-brightgreen.svg)](https://fivem.net)
[![Qbox](https://img.shields.io/badge/Qbox-Supported-orange.svg)](https://github.com/Qbox-project)
[![QBCore](https://img.shields.io/badge/QBCore-Supported-yellow.svg)](https://github.com/qbcore-framework)
[![ox_lib](https://img.shields.io/badge/ox_lib-Required-blue.svg)](https://github.com/overextended/ox_lib)

</div>

---

## Table of Contents

- [Features](#-features)
- [Preview](#-preview)
- [Dependencies](#%EF%B8%8F-dependencies)
- [Installation](#-installation)
- [Commands](#-commands)
- [Configuration](#%EF%B8%8F-configuration)
- [Searchable Categories](#-searchable-categories)
- [Progression System](#-progression-system)
- [Exclusive Zones](#-exclusive-zones)
- [Hazard Events](#-hazard-events)
- [Database](#-database)
- [Support](#-support)

---

## Features

### Core Mechanics
- **Progression & Level System** - Automatic database-driven reputation tracking with configurable XP per level
- **Level Restrictions** - Lock trash categories behind level gates (e.g., Dumpsters require Level 3, Suitcases require Level 5)
- **Reward Scaling** - Higher levels yield **more loot** (+3% quantity per level) and **better loot** (improved rare drop chances)
- **Cooldown System** - Configurable per-search cooldown to prevent spam

### Immersive Gameplay
- **Micro-Animations** - Unique search animations per trash type (dumpsters, bins, bags, suitcases, mailboxes)
- **Event Hazards** - Rat bites, raccoon attacks, and dirty needle pricks with visual effects
- **Protective Gear** - `hobo_gloves` item shields players from needle hazards
- **Aggressive Tramps** - NPCs may attack players who dig through their territory

### Loot & Zones
- **Multi-Tier Loot Tables** - Common and rare loot pools per category with configurable rarity thresholds
- **Exclusive Zones** - Location-based loot pools (e.g., Burgershot bins yield food ingredients, Industrial zones yield ores)
- **Custom Searchables** - Suitcases/luggage and mailboxes with unique loot and delete-on-search mechanics

### Technical
- **Auto Database Setup** - SQL table created automatically on first startup
- **Fully Configurable** - All values, loot tables, animations, and behaviors exposed in `config.lua`
- **ox_lib Integration** - Context menus for stats, notifications, progress bars, and callbacks
- **ox_target Support** - Smooth model-based interaction targeting

---

## Preview

> *Add screenshots or video links here*

---

## Dependencies

| Dependency | Purpose |
|------------|---------|
| [ox_lib](https://github.com/overextended/ox_lib) | Context menus, notifications, callbacks, progress bars |
| [ox_target](https://github.com/overextended/ox_target) | Model-based interaction targeting |
| [ox_inventory](https://github.com/overextended/ox_inventory) | Item handling |
| [oxmysql](https://github.com/overextended/oxmysql) | Database persistence |
| [qb-core](https://github.com/qbcore-framework/qb-core) **or** [qbx_core](https://github.com/Qbox-project/qbx_core) | Player data & session validation |

---

## Installation

1. **Download** this repository and place it in your `resources` folder
2. **Ensure** all dependencies are installed and started
3. **Add** to your `server.cfg`:
   ```cfg
   ensure ox_lib
   ensure ox_target
   ensure ox_inventory
   ensure oxmysql
   ensure qb-core  # or ensure qbx_core
   ensure vitrue-dumpster
   ```
4. **Restart** your server - the database table is created automatically

---

## Commands

### Player Commands

| Command | Description |
|---------|-------------|
| `/dumpsterstats` | Opens context menu showing current level, XP progress, and upcoming category unlocks |

### Admin Commands (Group: `admin`)

| Command | Description |
|---------|-------------|
| `/dumpsterlevel [id] [level]` | Set a player's dumpster progression level |
| `/dumpsterxp [id] [amount]` | Award specific XP amount to a player |

---

## Configuration

All settings are in `config.lua`. Key options:

### General
```lua
Config.DebugMode = false
Config.TrashCooldown = 5 -- Minutes before searching the same trash again
```

### Hazard Events
```lua
Config.Fails = {
    EnableFail = true,
    EnableRatEvent = true,
    EnableNeedleEvent = true,
    FailChancePercent = 7,
    DirtyNeedlesChancePercent = 1,
    RatChancePercent = 10,
    RacoonChancePercent = 5,
    -- Health loss and effect durations configurable per event
}
```

### Level Requirements
```lua
Config.LevelRequirements = {
    Enabled = true,
    beach = 1,
    bag = 1,
    garbage = 1,
    dumpster = 3,
    other = 2,
    Custom = {
        [1] = 5, -- Suitcase/Luggage
        [2] = 4, -- Mailbox
    }
}
```

### Reward Scaling
```lua
Config.LootLevelScaling = {
    enabled = true,
    extraRareChancePerLevel = 1.0,      -- +1% rare chance per level
    quantityMultiplierPerLevel = 0.03,   -- +3% item quantity per level
}
```

### XP & Levels
```lua
Config.XP = {
    XPGainedPerSearch = 5,
    levels = {
        [1] = 0,    [2] = 250,   [3] = 650,   [4] = 1200,  [5] = 1900,
        [6] = 2850,  [7] = 3900,  [8] = 5200,  [9] = 6700,  [10] = 8500,
        [11] = 10500, [12] = 12800, [13] = 15400, [14] = 18300, [15] = 21500,
    }
}
```

---

## Searchable Categories

| Category | Props | Level Req |
|----------|-------|-----------|
| **Beach Cans** | `prop_bin_beach_01a`, `prop_bin_beach_01d`, `prop_bin_delpiero`, `prop_bin_delpiero_b` | 1 |
| **Garbage Bags** | `prop_rub_binbag_01b`, `prop_rub_binbag_04`, `prop_rub_binbag_06` | 1 |
| **Garbage Cans** | `prop_bin_01a` through `prop_bin_12a` (19 variants) | 1 |
| **Dumpsters** | `prop_cs_dumpster_01a`, `prop_dumpster_01a`, etc. (8 variants) | 3 |
| **Tents / Other** | `prop_skid_tent_01`, `prop_skid_tent_01b`, `prop_skid_tent_03` | 2 |
| **Suitcases** | `prop_suitcase_*`, `prop_luggage_*` (17 variants) | 5 |
| **Mailboxes** | `prop_postbox_01a`, `prop_postbox_ss_01a` | 4 |

---

## Progression System

Players earn **5 XP** (configurable) per successful search. XP requirements scale across **15 levels**:

| Level | XP Required |
|-------|-------------|
| 1 | 0 |
| 2 | 250 |
| 3 | 650 |
| 4 | 1,200 |
| 5 | 1,900 |
| 6 | 2,850 |
| 7 | 3,900 |
| 8 | 5,200 |
| 9 | 6,700 |
| 10 | 8,500 |
| 11 | 10,500 |
| 12 | 12,800 |
| 13 | 15,400 |
| 14 | 18,300 |
| 15 | 21,500 |

**Scaling Effects:**
- **Quantity**: Each level adds +3% to item drop amounts
- **Rarity**: Each level adds +1% to rare item drop chance

---

## Exclusive Zones

Location-based loot pools with unique rewards:

| Zone | Location | Special Loot |
|------|----------|--------------|
| **Burgershot** | `-1179.7, -904.6, 13.5` | Food items (burgers, fries, drinks, ingredients) |
| **Industrial** | `722.1, -729.4, 26.1` | Ores (iron, copper, silver, gold), wood, stone, coal |
| **Grove** | `107.2, -1941.9, 20.8` | Drugs, electronics, lockpicks |
| **SuperRareSpot** | `169.5, -1224.2, 29.3` | High-tier electronics, rare drugs, hobo weapons |

---

## Hazard Events

When searching, players may encounter:

| Event | Trigger | Effect |
|-------|---------|--------|
| **Rat Bite** | Random chance | -5 HP, bite animation |
| **Raccoon Attack** | Random chance | -10 HP, attack animation |
| **Dirty Needle** | Random chance | -10 HP, 4 min dizzy effect (preventable with `hobo_gloves`) |

---

## Database

The script automatically creates a `dumpster_reputation` table on startup. No manual SQL import required.

**Table Schema:**
- `citizenid` - Player identifier
- `level` - Current progression level
- `xp` - Total XP accumulated

---

## Support

For issues, feature requests, or questions:
- Open an [Issue](https://github.com/GOD2929/vitrue-dumpster/issues)
- Pull requests welcome

---

<div align="center">

**Made with care by Virtue**

</div>
