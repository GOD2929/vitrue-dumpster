#  Dumpster Diving Script

A premium, optimized dumpster diving and searching script designed for FiveM servers running **Qbox** or **QBCore** alongside **ox_lib** and **ox_target**.

---

## 🌟 Features

- **Progression & Level System**:
  - Automatically creates and manages a dedicated `dumpster_reputation` table in the database.
  - Custom XP requirements per level (configurable).
  - Rewards players with +5 XP (configurable) for successful searches.
- **Level Restrictions**:
  - Enforces dumpster requirements: search specific trash categories only after reaching the required level (e.g. Dumpsters require Level 3, Suitcases require Level 5).
- **Reward Scaling (Better & More)**:
  - **More Rewards**: Item quantities multiply by `+3%` (configurable) per level, meaning higher levels yield greater amounts of loot.
  - **Better Rewards**: Rarity thresholds decrease per level, boosting the chances of finding rare items as players level up.
- **Micro-Animations & Event Hazards**:
  - Fail events with unique animations: get bit by a rat/raccoon or pricked by a dirty needle (dizzy camera/movement effect).
  - protective `hobo_gloves` item checks that shield players from hazards.
- **Exclusive Zones**:
  - Higher tier or exclusive loot pools in predefined spots (e.g. Burgershot bins yield food ingredients).
- **Aggressive Tramps**:
  - Tramps/Peds may attack players who try to steal trash from their territory.
- **Interactive UI**:
  - Beautiful `ox_lib` context menus for checking stats and unlocks.

---

## 🛠️ Dependencies

- **ox_lib** (Context menu, notifications, callbacks)
- **ox_target** (Model interaction)
- **ox_inventory** (Item handler)
- **progressbar** (Progress circle/bar)
- **oxmysql** (Database persistence)
- **qb-core** or **qbx_core** (Player data & session validation)

---

## 📋 Commands

### Player Commands
- `/dumpsterstats` - Opens the context menu to view current Dumpster Level, XP progress, and upcoming category level unlocks.

### Admin Commands (Group: `admin`)
- `/dumpsterlevel [id] [level]` - Directly sets a player's dumpster progression level.
- `/dumpsterxp [id] [amount]` - Awards a specific amount of dumpster XP to a player.

---

## ⚙️ Configuration (`config.lua`)

Customize progression scaling and level unlocks:

```lua
-- Database Table Name
Config.DatabaseTable = 'dumpster_reputation'

-- Level Unlocks per Category
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

-- Reward Scaling Factor
Config.LootLevelScaling = {
    enabled = true,
    extraRareChancePerLevel = 1.0, -- Adds 1% rare item chance per level
    quantityMultiplierPerLevel = 0.03, -- +3% item counts per level
}
```

---

## 💾 Database Setup

The script automatically initializes and sets up the SQL database table when it starts. No manual import is required!
