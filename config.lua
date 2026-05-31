Config = {}

Config.DebugMode = false
Config.TrashCooldown = 5 -- The time in MINUTES a player must wait before searching the same trash again.

Config.Fails = {
    EnableFail = true,
    EnableRatEvent = true,
    EnableNeedleEvent = true,
    FailChancePercent = 7,
    DirtyNeedlesChancePercent = 1,
    DirtyNeedlesEffectTime = 240, -- seconds
    RatChancePercent = 10,
    DirtyNeedlesHealthLoss = 10,
    HealthLoss = 0,
    RatHealthLoss = 5,
}

-- Hostile Ped Settings
Config.AggressivePedsAttack = true
Config.AggressivePedDistance = 25 -- Meters
Config.AggressivePeds = {
    'a_m_m_tramp_01',
    'a_m_m_trampbeac_01',
    'A_M_M_Hillbilly_02',
    'A_M_M_RurMeth_01',
    'A_M_M_Salton_01',
    'A_M_M_Salton_02',
    'A_M_M_Salton_03',
    'A_M_M_Salton_04',
    'a_f_m_skidrow_01',
    'a_f_m_trampbeac_01',
    'a_f_o_salton_01',
    'a_f_y_hippie_01',
    'a_f_y_rurmeth_01',
    'a_m_m_skidrow_01',
    'a_m_o_tramp_01',
    'a_m_o_beach_01',
    'a_m_o_salton_01',
    'a_m_o_soucent_02',
    'a_m_o_soucent_03',
    'a_m_y_methhead_01',
    'a_m_y_salton_01',
}

Config.AggressivePedWeapons = {
    ChanceThresholds = {
        Rare = 80,
        Uncommon = 65,
        Common = 20,
    },
    Weapons = {
        Rare = { name = "WEAPON_PISTOL", ammo = 12 },
        Uncommon = { name = "WEAPON_KNIFE", ammo = 0 },
        Common = { name = "WEAPON_BOTTLE", ammo = 0 }
    },
    GiveHoboWeapon = {
        enabled = true,
        chance = 20,
        weapons = {
            "WEAPON_HOBO_PIPE",
            "WEAPON_HOBO_PLANK",
            "WEAPON_HOBO_OLDMACHETE",
            "WEAPON_HOBO_STICK",
            "WEAPON_HOBO_REBAR"
        }
    }
}

-- Rewards Selection
Config.RandomSelection = {
    itemCountMin = 2,
    itemCountMax = 4,
}

-- Loot Tables
Config.BeachCanItems = {
    {name = "water_bottle", min = 1, max = 2, rarity = 40},
    {name = "condom", min = 1, max = 3, rarity = 55},
    {name = "tosti", min = 1, max = 2, rarity = 45},
    {name = "twerks_candy", min = 1, max = 5, rarity = 35},
    {name = "coffee", min = 1, max = 1, rarity = 30},
    {name = "iron", min = 1, max = 3, rarity = 50},
    {name = "steel", min = 1, max = 2, rarity = 60},
    {name = "copper", min = 1, max = 3, rarity = 50},
    {name = "plastic", min = 1, max = 5, rarity = 75},
    {name = "aluminum", min = 1, max = 4, rarity = 55},
    {name = "metalscrap", min = 1, max = 5, rarity = 35},
    {name = "rubber", min = 1, max = 3, rarity = 60},
    {name = "drug_grinder", min = 1, max = 1, rarity = 70},
    {name = "small_resealable_bag", min = 5, max = 10, rarity = 65},
    {name = "ls_plain_jane_seed", min = 1, max = 3, rarity = 75},
    {name = "ls_rolling_paper", min = 5, max = 10, rarity = 55},
    {name = "cryptostick", min = 1, max = 1, rarity = 85},
    {name = "lighter", min = 1, max = 1, rarity = 75},
}

Config.BeachCanItemsRare = {
    {name = "lockpick", min = 1, max = 2, rarity = 60},
    {name = "advancedlockpick", min = 1, max = 1, rarity = 75},
    {name = "crack_baggy", min = 1, max = 3, rarity = 65},
    {name = "methylamine", min = 1, max = 2, rarity = 70},
    {name = "ls_banana_kush_seed", min = 1, max = 2, rarity = 80},
    {name = "drug_scales", min = 1, max = 1, rarity = 50},
    {name = "samsungphone", min = 1, max = 1, rarity = 50},
    {name = "iphone", min = 1, max = 1, rarity = 55},
    {name = "cryptostick", min = 1, max = 1, rarity = 80},
    {name = "laptop2", min = 1, max = 1, rarity = 85},
    {name = "aluminumoxide", min = 1, max = 3, rarity = 55},
    {name = "ironoxide", min = 1, max = 2, rarity = 60},
    {name = "clonedcard", min = 1, max = 1, rarity = 75},
}
Config.BeachCanItemsRareChance = 4

Config.DumpsterItems = {
    {name = "water_bottle", min = 1, max = 2, rarity = 40},
    {name = "condom", min = 1, max = 3, rarity = 55},
    {name = "tosti", min = 1, max = 2, rarity = 45},
    {name = "twerks_candy", min = 1, max = 5, rarity = 35},
    {name = "coffee", min = 1, max = 1, rarity = 30},
    {name = "b_chain_pendant", min = 1, max = 2, rarity = 60},
    {name = "iron", min = 1, max = 3, rarity = 45},
    {name = "ironore", min = 1, max = 3, rarity = 50},
    {name = "steel", min = 1, max = 2, rarity = 55},
    {name = "copper", min = 1, max = 3, rarity = 45},
    {name = "copperore", min = 1, max = 3, rarity = 50},
    {name = "plastic", min = 1, max = 5, rarity = 35},
    {name = "aluminum", min = 1, max = 4, rarity = 50},
    {name = "metalscrap", min = 1, max = 5, rarity = 25},
    {name = "rubber", min = 1, max = 3, rarity = 40},
    {name = "stone", min = 2, max = 10, rarity = 35},
    {name = "coal", min = 1, max = 6, rarity = 55},
    {name = "drug_grinder", min = 1, max = 1, rarity = 70},
    {name = "small_resealable_bag", min = 5, max = 10, rarity = 65},
    {name = "ls_plain_jane_seed", min = 1, max = 3, rarity = 75},
    {name = "ls_rolling_paper", min = 5, max = 10, rarity = 55},
    {name = "cryptostick", min = 1, max = 1, rarity = 85},
    {name = "lighter", min = 1, max = 1, rarity = 75},
    {name = "money", min = 10, max = 60, rarity = 70},
}

Config.DumpsterItemsRare = {
    {name = "lockpick", min = 1, max = 2, rarity = 55},
    {name = "advancedlockpick", min = 1, max = 1, rarity = 75},
    {name = "b_chain_pendant", min = 1, max = 2, rarity = 60},
    {name = "crack_baggy", min = 1, max = 3, rarity = 65},
    {name = "methylamine", min = 1, max = 2, rarity = 70},
    {name = "ls_banana_kush_seed", min = 1, max = 2, rarity = 80},
    {name = "drug_scales", min = 1, max = 1, rarity = 50},
    {name = "samsungphone", min = 1, max = 1, rarity = 50},
    {name = "iphone", min = 1, max = 1, rarity = 55},
    {name = "cryptostick", min = 1, max = 1, rarity = 80},
    {name = "laptop2", min = 1, max = 1, rarity = 85},
    {name = "ar_pendrive_a", min = 1, max = 1, rarity = 80},
    {name = "aluminumoxide", min = 1, max = 3, rarity = 55},
    {name = "ironoxide", min = 1, max = 2, rarity = 60},
    {name = "silverore", min = 1, max = 3, rarity = 80},
    {name = "goldore", min = 1, max = 2, rarity = 88},
    {name = "uncut_ruby", min = 1, max = 1, rarity = 92},
    {name = "uncut_sapphire", min = 1, max = 1, rarity = 94},
    {name = "uncut_emerald", min = 1, max = 1, rarity = 95},
    {name = "uncut_diamond", min = 1, max = 1, rarity = 97},
    {name = "clonedcard", min = 1, max = 1, rarity = 90},
    {name = "WEAPON_HOBO_PIPE", min = 1, max = 1, rarity = 70},
    {name = "WEAPON_HOBO_PLANK", min = 1, max = 1, rarity = 75},
    {name = "WEAPON_HOBO_OLDMACHETE", min = 1, max = 1, rarity = 80},
    {name = "WEAPON_HOBO_TOILET", min = 1, max = 1, rarity = 85},
    {name = "WEAPON_HOBO_REBAR", min = 1, max = 1, rarity = 90},
}
Config.DumpsterItemsRareChance = 12

Config.GarbageCanItems = {
    {name = "water_bottle", min = 1, max = 2, rarity = 40},
    {name = "condom", min = 1, max = 3, rarity = 55},
    {name = "tosti", min = 1, max = 2, rarity = 45},
    {name = "twerks_candy", min = 1, max = 5, rarity = 35},
    {name = "coffee", min = 1, max = 1, rarity = 30},
    {name = "iron", min = 1, max = 3, rarity = 50},
    {name = "steel", min = 1, max = 2, rarity = 60},
    {name = "copper", min = 1, max = 3, rarity = 50},
    {name = "plastic", min = 1, max = 5, rarity = 75},
    {name = "aluminum", min = 1, max = 4, rarity = 55},
    {name = "metalscrap", min = 1, max = 5, rarity = 35},
    {name = "rubber", min = 1, max = 3, rarity = 60},
    {name = "drug_grinder", min = 1, max = 1, rarity = 70},
    {name = "small_resealable_bag", min = 5, max = 10, rarity = 65},
    {name = "ls_plain_jane_seed", min = 1, max = 3, rarity = 75},
    {name = "ls_rolling_paper", min = 5, max = 10, rarity = 55},
    {name = "cryptostick", min = 1, max = 1, rarity = 85},
    {name = "lighter", min = 1, max = 1, rarity = 75},
}

Config.GarbageCanItemsRare = {
    {name = "lockpick", min = 1, max = 2, rarity = 60},
    {name = "advancedlockpick", min = 1, max = 1, rarity = 75},
    {name = "crack_baggy", min = 1, max = 3, rarity = 65},
    {name = "methylamine", min = 1, max = 2, rarity = 70},
    {name = "ls_banana_kush_seed", min = 1, max = 2, rarity = 80},
    {name = "drug_scales", min = 1, max = 1, rarity = 50},
    {name = "samsungphone", min = 1, max = 1, rarity = 50},
    {name = "iphone", min = 1, max = 1, rarity = 55},
    {name = "cryptostick", min = 1, max = 1, rarity = 80},
    {name = "laptop2", min = 1, max = 1, rarity = 85},
    {name = "aluminumoxide", min = 1, max = 3, rarity = 55},
    {name = "ironoxide", min = 1, max = 2, rarity = 60},
    {name = "clonedcard", min = 1, max = 1, rarity = 75},
    {name = "WEAPON_HOBO_PIPE", min = 1, max = 1, rarity = 90},
    {name = "WEAPON_HOBO_SPONGE", min = 1, max = 1, rarity = 95},
}
Config.GarbageCanItemsRareChance = 6

Config.OtherSearchablesItems = {
    {name = "water_bottle", min = 1, max = 2, rarity = 40},
    {name = "condom", min = 1, max = 3, rarity = 55},
    {name = "tosti", min = 1, max = 2, rarity = 45},
    {name = "twerks_candy", min = 1, max = 5, rarity = 35},
    {name = "coffee", min = 1, max = 1, rarity = 30},
    {name = "iron", min = 1, max = 3, rarity = 50},
    {name = "steel", min = 1, max = 2, rarity = 60},
    {name = "copper", min = 1, max = 3, rarity = 50},
    {name = "plastic", min = 1, max = 5, rarity = 75},
    {name = "aluminum", min = 1, max = 4, rarity = 55},
    {name = "metalscrap", min = 1, max = 5, rarity = 35},
    {name = "rubber", min = 1, max = 3, rarity = 60},
    {name = "drug_grinder", min = 1, max = 1, rarity = 70},
    {name = "small_resealable_bag", min = 5, max = 10, rarity = 65},
    {name = "ls_plain_jane_seed", min = 1, max = 3, rarity = 75},
    {name = "ls_rolling_paper", min = 5, max = 10, rarity = 55},
    {name = "cryptostick", min = 1, max = 1, rarity = 85},
    {name = "lighter", min = 1, max = 1, rarity = 75},
}

Config.OtherSearchablesItemsRare = {
    {name = "lockpick", min = 1, max = 2, rarity = 60},
    {name = "advancedlockpick", min = 1, max = 1, rarity = 75},
    {name = "crack_baggy", min = 1, max = 3, rarity = 65},
    {name = "methylamine", min = 1, max = 2, rarity = 70},
    {name = "ls_banana_kush_seed", min = 1, max = 2, rarity = 80},
    {name = "drug_scales", min = 1, max = 1, rarity = 50},
    {name = "samsungphone", min = 1, max = 1, rarity = 50},
    {name = "iphone", min = 1, max = 1, rarity = 55},
    {name = "cryptostick", min = 1, max = 1, rarity = 80},
    {name = "laptop2", min = 1, max = 1, rarity = 85},
    {name = "aluminumoxide", min = 1, max = 3, rarity = 55},
    {name = "ironoxide", min = 1, max = 2, rarity = 60},
    {name = "clonedcard", min = 1, max = 1, rarity = 75},
    {name = "WEAPON_HOBO_PLANK", min = 1, max = 1, rarity = 90},
    {name = "WEAPON_HOBO_OLDMACHETE", min = 1, max = 1, rarity = 95},
    {name = "WEAPON_HOBO_MOP", min = 1, max = 1, rarity = 98},
}
Config.OtherSearchablesItemsRareChance = 3

Config.GarbageBagsItems = {
    {name = "water_bottle", min = 1, max = 2, rarity = 40},
    {name = "condom", min = 1, max = 3, rarity = 55},
    {name = "tosti", min = 1, max = 2, rarity = 45},
    {name = "twerks_candy", min = 1, max = 5, rarity = 35},
    {name = "coffee", min = 1, max = 1, rarity = 30},
    {name = "iron", min = 1, max = 3, rarity = 50},
    {name = "steel", min = 1, max = 2, rarity = 60},
    {name = "copper", min = 1, max = 3, rarity = 50},
    {name = "plastic", min = 1, max = 5, rarity = 75},
    {name = "aluminum", min = 1, max = 4, rarity = 55},
    {name = "metalscrap", min = 1, max = 5, rarity = 35},
    {name = "rubber", min = 1, max = 3, rarity = 60},
    {name = "drug_grinder", min = 1, max = 1, rarity = 70},
    {name = "small_resealable_bag", min = 5, max = 10, rarity = 65},
    {name = "ls_plain_jane_seed", min = 1, max = 3, rarity = 75},
    {name = "ls_rolling_paper", min = 5, max = 10, rarity = 55},
    {name = "cryptostick", min = 1, max = 1, rarity = 85},
    {name = "lighter", min = 1, max = 1, rarity = 75},
}

Config.GarbageBagsItemsRare = {
    {name = "lockpick", min = 1, max = 2, rarity = 60},
    {name = "advancedlockpick", min = 1, max = 1, rarity = 75},
    {name = "crack_baggy", min = 1, max = 3, rarity = 65},
    {name = "methylamine", min = 1, max = 2, rarity = 70},
    {name = "ls_banana_kush_seed", min = 1, max = 2, rarity = 80},
    {name = "drug_scales", min = 1, max = 1, rarity = 50},
    {name = "samsungphone", min = 1, max = 1, rarity = 50},
    {name = "iphone", min = 1, max = 1, rarity = 55},
    {name = "cryptostick", min = 1, max = 1, rarity = 80},
    {name = "laptop2", min = 1, max = 1, rarity = 85},
    {name = "aluminumoxide", min = 1, max = 3, rarity = 55},
    {name = "ironoxide", min = 1, max = 2, rarity = 60},
    {name = "clonedcard", min = 1, max = 1, rarity = 75},
    {name = "WEAPON_HOBO_PLANK", min = 1, max = 1, rarity = 90},
    {name = "WEAPON_HOBO_SHARD", min = 1, max = 1, rarity = 95},
}
Config.GarbageBagsItemsRareChance = 8

-- Exclusive Item Zones
Config.ExclusiveItemZones = {
    {
        name = "Burgershot",
        coords = vector3(-1179.7351, -904.6566, 13.5210),
        radius = 5.0,
        chance = 75,
        items = {
            {name = "bs_burger", min = 1, max = 1},
            {name = "bs_fries", min = 1, max = 1},
            {name = "bs_drink", min = 1, max = 1},
            {name = "lettuce", min = 1, max = 1},
            {name = "tomato", min = 1, max = 1},
            {name = "potato", min = 1, max = 1},
            {name = "water_bottle", min = 1, max = 2, rarity = 40},
            {name = "condom", min = 1, max = 3, rarity = 55},
            {name = "tosti", min = 1, max = 2, rarity = 45},
            {name = "twerks_candy", min = 1, max = 5, rarity = 35},
            {name = "coffee", min = 1, max = 1, rarity = 30},
            {name = "iron", min = 1, max = 3, rarity = 50},
            {name = "steel", min = 1, max = 2, rarity = 60},
            {name = "copper", min = 1, max = 3, rarity = 50},
            {name = "plastic", min = 1, max = 5, rarity = 75},
            {name = "aluminum", min = 1, max = 4, rarity = 55},
            {name = "metalscrap", min = 1, max = 5, rarity = 35},
            {name = "rubber", min = 1, max = 3, rarity = 60},
        },
    },
    {
        name = "Industrial",
        coords = vector3(722.1307, -729.4524, 26.1094),
        radius = 100.0,
        chance = 30,
        items = {
            {name = "water_bottle", min = 1, max = 2, rarity = 40},
            {name = "condom", min = 1, max = 3, rarity = 55},
            {name = "tosti", min = 1, max = 2, rarity = 45},
            {name = "twerks_candy", min = 1, max = 5, rarity = 35},
            {name = "coffee", min = 1, max = 1, rarity = 30},
            {name = "iron", min = 1, max = 3, rarity = 50},
            {name = "steel", min = 1, max = 2, rarity = 60},
            {name = "copper", min = 1, max = 3, rarity = 50},
            {name = "plastic", min = 1, max = 5, rarity = 75},
            {name = "aluminum", min = 1, max = 4, rarity = 55},
            {name = "metalscrap", min = 1, max = 5, rarity = 35},
            {name = "rubber", min = 1, max = 3, rarity = 60},
            {name = "wood", min = 1, max = 7},
            {name = "stone", min = 3, max = 12, rarity = 25},
            {name = "coal", min = 2, max = 8, rarity = 45},
            {name = "ironore", min = 2, max = 7, rarity = 50},
            {name = "copperore", min = 2, max = 7, rarity = 50},
            {name = "silverore", min = 1, max = 4, rarity = 75},
            {name = "goldore", min = 1, max = 2, rarity = 88},
            {name = "aluminumoxide", min = 1, max = 3, rarity = 55},
        },
    },
    {
        name = "Grove",
        coords = vector3(107.2442, -1941.9656, 20.8037),
        radius = 50.0,
        chance = 10,
        items = {
            {name = "water_bottle", min = 1, max = 2, rarity = 40},
            {name = "condom", min = 1, max = 3, rarity = 55},
            {name = "tosti", min = 1, max = 2, rarity = 45},
            {name = "twerks_candy", min = 1, max = 5, rarity = 35},
            {name = "coffee", min = 1, max = 1, rarity = 30},
            {name = "iron", min = 1, max = 3, rarity = 50},
            {name = "steel", min = 1, max = 2, rarity = 60},
            {name = "copper", min = 1, max = 3, rarity = 50},
            {name = "plastic", min = 1, max = 5, rarity = 75},
            {name = "aluminum", min = 1, max = 4, rarity = 55},
            {name = "metalscrap", min = 1, max = 5, rarity = 35},
            {name = "rubber", min = 1, max = 3, rarity = 60},
            {name = "lockpick", min = 1, max = 2, rarity = 60},
            {name = "advancedlockpick", min = 1, max = 1, rarity = 75},
            {name = "crack_baggy", min = 1, max = 3, rarity = 65},
            {name = "methylamine", min = 1, max = 2, rarity = 70},
            {name = "ls_banana_kush_seed", min = 1, max = 2, rarity = 80},
            {name = "drug_scales", min = 1, max = 1, rarity = 50},
            {name = "samsungphone", min = 1, max = 1, rarity = 50},
            {name = "iphone", min = 1, max = 1, rarity = 55},
            {name = "cryptostick", min = 1, max = 1, rarity = 80},
            {name = "laptop2", min = 1, max = 1, rarity = 85},
            {name = "aluminumoxide", min = 1, max = 3, rarity = 55},
            {name = "ironoxide", min = 1, max = 2, rarity = 60},
            {name = "clonedcard", min = 1, max = 1, rarity = 75},
            {name = "WEAPON_HOBO_PLANK", min = 1, max = 1, rarity = 90},
            {name = "WEAPON_HOBO_SHARD", min = 1, max = 1, rarity = 95},
        },
    },
    {
        name = "SuperRareSpot",
        coords = vector3(169.5135, -1224.2314, 29.3662),
        radius = 10.0,
        chance = 5,
        items = {
            {name = "lockpick", min = 1, max = 2, rarity = 60},
            {name = "advancedlockpick", min = 1, max = 1, rarity = 75},
            {name = "crack_baggy", min = 1, max = 3, rarity = 65},
            {name = "methylamine", min = 1, max = 2, rarity = 70},
            {name = "ls_banana_kush_seed", min = 1, max = 2, rarity = 80},
            {name = "drug_scales", min = 1, max = 1, rarity = 50},
            {name = "samsungphone", min = 1, max = 1, rarity = 50},
            {name = "iphone", min = 1, max = 1, rarity = 55},
            {name = "cryptostick", min = 1, max = 1, rarity = 80},
            {name = "laptop2", min = 1, max = 1, rarity = 85},
            {name = "ar_pendrive_a", min = 1, max = 1, rarity = 80},
            {name = "aluminumoxide", min = 1, max = 3, rarity = 55},
            {name = "ironoxide", min = 1, max = 2, rarity = 60},
            {name = "clonedcard", min = 1, max = 1, rarity = 75},
            {name = "WEAPON_HOBO_PLANK", min = 1, max = 1, rarity = 90},
            {name = "WEAPON_HOBO_SHARD", min = 1, max = 1, rarity = 95},
        },
    }
}

-- Prop Target Models
Config.BeachCans = {
    "prop_bin_beach_01a",
    "prop_bin_beach_01d",
    "prop_bin_delpiero",
    "prop_bin_delpiero_b",
}

Config.Dumpsters = {
    "prop_cs_dumpster_01a",
    "p_dumpster_t",
    "prop_dumpster_01a",
    "prop_dumpster_02a",
    "prop_dumpster_02b",
    "prop_dumpster_3a",
    "prop_dumpster_4a",
    "prop_dumpster_4b",
}

Config.GarbageCans = {
    "prop_bin_01a",
    "prop_bin_02a",
    "prop_bin_03a",
    "prop_bin_04a",
    "prop_bin_05a",
    "prop_bin_06a",
    "prop_bin_07a",
    "prop_bin_07b",
    "prop_bin_07c",
    "prop_bin_07d",
    "prop_bin_08a",
    "prop_bin_08open",
    "prop_bin_09a",
    "prop_bin_10a",
    "prop_bin_10b",
    "prop_bin_11a",
    "prop_bin_11b",
    "prop_bin_12a",
    "zprop_bin_01a_old",
}

Config.OtherSearchables = {
    "prop_skid_tent_01",
    "prop_skid_tent_01b",
    "prop_skid_tent_03",
}

Config.TrashBagModels = {
    'prop_rub_binbag_01b',
    'prop_rub_binbag_04',
    'prop_rub_binbag_06',
}

Config.CustomSearchables = {
    [1] = {
        label = 'Steal Luggage',
        models = {
            "prop_suitcase_01", "prop_suitcase_01b", "prop_suitcase_01c", "prop_suitcase_01d",
            "prop_suitcase_02", "prop_suitcase_03b", "prop_ld_suitcase_01", "prop_ld_suitcase_02",
            "prop_luggage_01a", "prop_luggage_02a", "prop_luggage_03a", "prop_luggage_04a",
            "prop_luggage_05a", "prop_luggage_06a", "prop_luggage_07a", "prop_luggage_08a",
            "prop_luggage_09a", "h4_prop_h4_luggage_01a", "h4_prop_h4_luggage_02a",
        },
        anims = {
            { dict = 'anim@gangops@van@drive_grab@', anim = 'grab_drive' },
            { dict = 'amb@code_human_in_car_mp_actions@arse_pick@std@ps@base', anim = 'enter' },
            { dict = 'rcmepsilonism8', anim = 'bag_handler_grab_walk_left' },
            { dict = 'anim@scripted@player@freemode@gen_grab@heeled@', anim = 'low_multi' },
            { dict = 'anim@move_m@trash', anim = 'pickup' },
        },
        loot = {
            {name = "money", min = 1, max = 50, rarity = 70},
            {name = "goldwatch", min = 1, max = 1, rarity = 90},
            {name = "goldbar", min = 1, max = 1, rarity = 95},
            {name = "cryptostick", min = 1, max = 1, rarity = 98},
        },
        deleteProp = true,
    },
    [2] = {
        label = 'Steal From Mailbox',
        models = { 'prop_postbox_01a', 'prop_postbox_ss_01a' },
        anims = {
            { dict = 'anim@move_m@trash', anim = 'pickup' },
            { dict = 'anim@scripted@player@freemode@gen_grab@heeled@', anim = 'low_multi' },
            { dict = 'rcmepsilonism8', anim = 'bag_handler_grab_walk_left' },
        },
        loot = {
            {name = "letter", min = 1, max = 3, rarity = 30},
            {name = "money", min = 1, max = 20, rarity = 70},
        },
        deleteProp = false,
    },
}

-- Animations
Config.RatFailAnim = { dict = 'misscarsteal2_bin', anim = 'trev_sink_exit' }
Config.DirtyNeedlesFailAnim = { dict = 'misscarsteal2_bin', anim = 'trev_sink_exit' }
Config.FailAnim = { dict = 'move_p_m_two_idles@generic', anim = 'fidget_sniff_fingers' }

Config.BeachCanAnims = {
    { dict = 'anim@gangops@van@drive_grab@', anim = 'grab_drive' },
    { dict = 'amb@code_human_in_car_mp_actions@arse_pick@std@ps@base', anim = 'enter' },
    { dict = 'rcmepsilonism8', anim = 'bag_handler_grab_walk_left' },
    { dict = 'anim@scripted@player@freemode@gen_grab@heeled@', anim = 'low_multi' },
    { dict = 'anim@move_m@trash', anim = 'pickup' },
    { dict = 'anim@heists@prison_heiststation@heels', anim = 'pickup_bus_schedule' },
}

Config.DumpsterAnims = {
    { dict = 'weapons@first_person@aim_idle@generic@melee@knife@shared@core', anim = 'fidget_low_loop' },
    { dict = 'anim@gangops@facility@servers@bodysearch@', anim = 'player_search' },
    { dict = 'anim@gangops@morgue@table@', anim = 'player_search' },
    { dict = 'missexile3', anim = 'ex03_dingy_search_case_a_michael' },
    { dict = 'anim@amb@inspect@crouch@male_a@base', anim = 'base' },
}

Config.GarbageCanAnims = {
    { dict = 'switch@trevor@garbage_food', anim = 'loop_trevor' },
    { dict = 'amb@prop_human_bum_bin@base', anim = 'base' },
    { dict = 'amb@prop_human_bum_bin@idle_b', anim = 'idle_d' },
    { dict = 'anim@heists@money_grab@briefcase', anim = 'enter' },
}

Config.TrashBagAnims = {
    { dict = 'anim@gangops@facility@servers@bodysearch@', anim = 'player_search' },
    { dict = 'missexile3', anim = 'ex03_dingy_search_case_a_michael' },
    { dict = 'amb@medic@standing@kneel@base', anim = 'base' },
    { dict = 'amb@world_human_bum_wash@male@low@base', anim = 'base' },
    { dict = 'anim@am_hold_up@male', anim = 'shoplift_low' },
}

-- Language strings
Config.Lang = {
    ['need_gloves'] = "You searched but got pricked by a needle! Some protective gloves would have helped...",
    ['needles'] = "You got pricked by a dirty needle! You feel dizzy...",
    ['rat'] = "A rat jumped out and bit you!",
    ['trash_empty'] = "This trash is empty.",
    ['searching'] = "Searching trash...",
    ['fail'] = "You found nothing but trash...",
    ['aggressive_ped'] = "Hey! Stay away from my trash!",
}

-- Database and Progression configurations
Config.DatabaseTable = 'dumpster_reputation'

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

Config.LootLevelScaling = {
    enabled = true,
    extraRareChancePerLevel = 1.0, -- Adds 1% rare item chance per level (reduces effective rarity roll threshold)
    quantityMultiplierPerLevel = 0.03, -- +3% item count multiplier per level
}

Config.XP = {
    XPGainedPerSearch = 5,
    levels = {
        [1] = 0,
        [2] = 250,
        [3] = 650,
        [4] = 1200,
        [5] = 1900,
        [6] = 2850,
        [7] = 3900,
        [8] = 5200,
        [9] = 6700,
        [10] = 8500,
        [11] = 10500,
        [12] = 12800,
        [13] = 15400,
        [14] = 18300,
        [15] = 21500,
    }
}

