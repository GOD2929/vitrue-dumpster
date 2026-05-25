local searchCooldowns = {}
local QBCore = exports['qb-core']:GetCoreObject()

-- Get player citizenid
local function getCitizen(src)
    local player = QBCore.Functions.GetPlayer(src)
    if player then
        return player.PlayerData.citizenid, player
    end
    if GetResourceState('qbx_core') == 'started' then
        local qbxPlayer = exports.qbx_core:GetPlayer(src)
        return qbxPlayer and qbxPlayer.PlayerData.citizenid, qbxPlayer
    end
    return nil, nil
end

-- Database functions
local function defaultReputation(citizenid)
    return {
        citizenid = citizenid,
        dumpster_xp = 0,
        dumpster_level = 1,
    }
end

local function getLevelFromXP(xp)
    xp = tonumber(xp) or 0
    local level = 1
    for configuredLevel, requiredXp in ipairs(Config.XP.levels or {}) do
        if xp >= requiredXp and configuredLevel > level then
            level = configuredLevel
        end
    end
    return level
end

local function getReputation(citizenid)
    if not MySQL or not MySQL.single then
        return defaultReputation(citizenid)
    end
    
    local query = 'SELECT dumpster_xp, dumpster_level FROM `' .. Config.DatabaseTable .. '` WHERE citizenid = ?'
    local row = MySQL.single.await(query, { citizenid })
    if row then
        row.dumpster_level = getLevelFromXP(row.dumpster_xp)
        return row
    end
    
    local rep = defaultReputation(citizenid)
    MySQL.insert.await('INSERT INTO `' .. Config.DatabaseTable .. '` (citizenid) VALUES (?)', { citizenid })
    return rep
end

local function addXP(citizenid, amount)
    local rep = getReputation(citizenid)
    local xp = math.max(0, (rep.dumpster_xp or 0) + (tonumber(amount) or 0))
    local level = getLevelFromXP(xp)
    
    if MySQL and MySQL.update then
        local query = 'INSERT INTO `' .. Config.DatabaseTable .. '` (citizenid, dumpster_xp, dumpster_level) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE dumpster_xp = ?, dumpster_level = ?'
        MySQL.update.await(query, { citizenid, xp, level, xp, level })
    end
    
    return {
        citizenid = citizenid,
        dumpster_xp = xp,
        dumpster_level = level,
    }
end

local function setLevel(citizenid, level)
    level = math.max(1, tonumber(level) or 1)
    local xp = Config.XP.levels[level] or 0
    if MySQL and MySQL.update then
        local query = 'INSERT INTO `' .. Config.DatabaseTable .. '` (citizenid, dumpster_xp, dumpster_level) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE dumpster_xp = ?, dumpster_level = ?'
        MySQL.update.await(query, { citizenid, xp, level, xp, level })
    end
    return getReputation(citizenid)
end

local function ensureDatabaseTable()
    if not MySQL or not MySQL.query then
        print('^3[vitrue-dumpster] oxmysql was not found. Reputation persistence is disabled until oxmysql is started.^7')
        return
    end
    
    local sql = [[
        CREATE TABLE IF NOT EXISTS `]] .. Config.DatabaseTable .. [[` (
            `citizenid` varchar(50) NOT NULL,
            `dumpster_xp` int NOT NULL DEFAULT 0,
            `dumpster_level` int NOT NULL DEFAULT 1,
            PRIMARY KEY (`citizenid`)
        );
    ]]
    
    MySQL.query.await(sql)
    if Config.DebugMode then
        print(("[DEBUG] Table %s ensure complete."):format(Config.DatabaseTable))
    end
end

CreateThread(ensureDatabaseTable)


-- Helper function to generate coordinate key
local function getCoordsKey(coords)
    if not coords then return "0.0_0.0_0.0" end
    return string.format("%.1f_%.1f_%.1f", coords.x, coords.y, coords.z)
end

-- Callback to check if player can search dumpster
lib.callback.register('vitrue-dumpster:server:canSearch', function(source, coords, category, customIndex)
    local key = getCoordsKey(coords)
    local lastSearch = searchCooldowns[key]
    if lastSearch then
        local timeDiff = os.time() - lastSearch
        if timeDiff < (Config.TrashCooldown * 60) then
            if Config.DebugMode then
                print(("[DEBUG] Dumpster at %s is on cooldown. Remaining: %ds"):format(key, (Config.TrashCooldown * 60) - timeDiff))
            end
            return false, Config.Lang['trash_empty']
        end
    end
    
    -- Check Level Requirements
    if Config.LevelRequirements.Enabled then
        local citizenid = getCitizen(source)
        if citizenid then
            local rep = getReputation(citizenid)
            local level = rep and rep.dumpster_level or 1
            local reqLevel = 1
            
            if category == 'custom' and customIndex then
                reqLevel = Config.LevelRequirements.Custom[customIndex] or 1
            else
                reqLevel = Config.LevelRequirements[category] or 1
            end
            
            if level < reqLevel then
                return false, ("You need dumpster level %d to search this!"):format(reqLevel)
            end
        end
    end
    
    return true
end)

-- Helper function to select items based on rarity and level scaling
local function GetLootFromTable(lootTable, maxItems, level)
    local rewards = {}
    local candidates = {}
    
    local levelScaling = Config.LootLevelScaling or {}
    local rareChanceModifier = 0
    if levelScaling.enabled and level then
        -- Decreases the rarity threshold, making rare rolls easier to pass
        rareChanceModifier = (level - 1) * (levelScaling.extraRareChancePerLevel or 0)
    end
    
    -- Filter candidate items based on rarity roll
    for _, item in ipairs(lootTable) do
        local roll = math.random(1, 100)
        local itemRarity = item.rarity or 50
        local adjustedRarity = math.max(1, itemRarity - rareChanceModifier)
        if roll >= adjustedRarity then
            candidates[#candidates + 1] = item
        end
    end
    
    -- If no candidate passed rarity check, fallback to choosing a random one
    if #candidates == 0 and #lootTable > 0 then
        candidates[1] = lootTable[math.random(1, #lootTable)]
    end
    
    -- Select random candidates up to maxItems
    local selectedCount = math.random(Config.RandomSelection.itemCountMin, math.min(maxItems, Config.RandomSelection.itemCountMax))
    for i = 1, selectedCount do
        if #candidates == 0 then break end
        local idx = math.random(1, #candidates)
        rewards[#rewards + 1] = candidates[idx]
        table.remove(candidates, idx)
    end
    
    return rewards
end

-- Server Event: Search Complete
RegisterNetEvent('vitrue-dumpster:server:searchComplete', function(coords, category, customIndex)
    local src = source
    local key = getCoordsKey(coords)
    
    -- Double check cooldown
    local lastSearch = searchCooldowns[key]
    if lastSearch and (os.time() - lastSearch) < (Config.TrashCooldown * 60) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Dumpster Diving',
            description = Config.Lang['trash_empty'],
            type = 'error'
        })
        return
    end
    
    -- Get Player Reputation
    local citizenid = getCitizen(src)
    local rep = citizenid and getReputation(citizenid) or { dumpster_level = 1, dumpster_xp = 0 }
    local level = rep.dumpster_level or 1
    
    -- Enforce level requirement on complete check as well
    if Config.LevelRequirements.Enabled then
        local reqLevel = 1
        if category == 'custom' and customIndex then
            reqLevel = Config.LevelRequirements.Custom[customIndex] or 1
        else
            reqLevel = Config.LevelRequirements[category] or 1
        end
        if level < reqLevel then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Dumpster Diving',
                description = ("You need dumpster level %d to search this!"):format(reqLevel),
                type = 'error'
            })
            return
        end
    end
    
    -- Set cooldown
    searchCooldowns[key] = os.time()
    
    -- Check if gloves protect from fail events
    local glovesCount = exports.ox_inventory:Search(src, 'count', 'hobo_gloves') or 0
    local hasGloves = glovesCount > 0
    
    -- 1. Handle Fail Events
    if Config.Fails.EnableFail and not hasGloves then
        if math.random(1, 100) <= Config.Fails.FailChancePercent then
            -- Determine fail type
            local roll = math.random(1, 100)
            if Config.Fails.EnableNeedleEvent and roll <= Config.Fails.DirtyNeedlesChancePercent then
                -- Needle event
                TriggerClientEvent('vitrue-dumpster:client:triggerNeedleEffect', src, Config.Fails.DirtyNeedlesEffectTime, Config.Fails.DirtyNeedlesHealthLoss)
                local ped = GetPlayerPed(src)
                local health = GetEntityHealth(ped)
                SetEntityHealth(ped, math.max(1, health - Config.Fails.DirtyNeedlesHealthLoss))
                return
            elseif Config.Fails.EnableRatEvent and roll <= (Config.Fails.DirtyNeedlesChancePercent + Config.Fails.RatChancePercent) then
                -- Rat event (or Raccoon)
                local isRacoon = math.random(1, 100) <= Config.Fails.RacoonChancePercent
                local damage = isRacoon and Config.Fails.RacoonHealthLoss or Config.Fails.RatHealthLoss
                TriggerClientEvent('vitrue-dumpster:client:triggerRatEffect', src, isRacoon, damage)
                local ped = GetPlayerPed(src)
                local health = GetEntityHealth(ped)
                SetEntityHealth(ped, math.max(1, health - damage))
                return
            else
                -- Generic fail
                if Config.Fails.HealthLoss > 0 then
                    local ped = GetPlayerPed(src)
                    local health = GetEntityHealth(ped)
                    SetEntityHealth(ped, math.max(1, health - Config.Fails.HealthLoss))
                end
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Dumpster Diving',
                    description = Config.Lang['fail'],
                    type = 'error'
                })
                return
            end
        end
    elseif Config.Fails.EnableFail and hasGloves then
        -- Notify player their gloves protected them from any potential hazard
        if math.random(1, 100) <= Config.Fails.FailChancePercent then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Dumpster Diving',
                description = "Your protective gloves prevented you from getting injured while searching!",
                type = 'success'
            })
        end
    end
    
    -- 2. Check for Exclusive Item Zones
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local inZone = nil
    
    for _, zone in ipairs(Config.ExclusiveItemZones) do
        local dist = #(playerCoords - zone.coords)
        if dist <= zone.radius then
            if math.random(1, 100) <= zone.chance then
                inZone = zone
                break
            end
        end
    end
    
    local finalLoot = {}
    
    if inZone then
        if Config.DebugMode then
            print(("[DEBUG] Player %d is in exclusive zone: %s"):format(src, inZone.name))
        end
        finalLoot = GetLootFromTable(inZone.items, 4, level)
    else
        -- Standard category loot pools
        local itemsTable = {}
        local rareItemsTable = {}
        local rareChance = 0
        
        if category == 'beach' then
            itemsTable = Config.BeachCanItems
            rareItemsTable = Config.BeachCanItemsRare
            rareChance = Config.BeachCanItemsRareChance
        elseif category == 'garbage' then
            itemsTable = Config.GarbageCanItems
            rareItemsTable = Config.GarbageCanItemsRare
            rareChance = Config.GarbageCanItemsRareChance
        elseif category == 'other' then
            itemsTable = Config.OtherSearchablesItems
            rareItemsTable = Config.OtherSearchablesItemsRare
            rareChance = Config.OtherSearchablesItemsRareChance
        elseif category == 'bag' then
            itemsTable = Config.GarbageBagsItems
            rareItemsTable = Config.GarbageBagsItemsRare
            rareChance = Config.GarbageBagsItemsRareChance
        elseif category == 'custom' and customIndex then
            itemsTable = Config.CustomSearchables[customIndex].loot
            rareChance = 0 -- Custom searchables don't use rare tables by default
        else
            -- Default to dumpster
            itemsTable = Config.DumpsterItems
            rareItemsTable = Config.DumpsterItemsRare
            rareChance = Config.DumpsterItemsRareChance
        end
        
        finalLoot = GetLootFromTable(itemsTable, 4, level)
        
        -- Roll for extra rare item (applies better rewards rareChance modification too)
        local levelScaling = Config.LootLevelScaling or {}
        local rareChanceModifier = 0
        if levelScaling.enabled and level then
            rareChanceModifier = (level - 1) * (levelScaling.extraRareChancePerLevel or 0)
        end
        
        local finalRareChance = rareChance
        if levelScaling.enabled then
            finalRareChance = rareChance + (level - 1) * (levelScaling.extraRareChancePerLevel or 0)
        end
        
        if finalRareChance > 0 and #rareItemsTable > 0 then
            if math.random(1, 100) <= finalRareChance then
                -- Filter rare candidates
                local rareCandidates = {}
                for _, item in ipairs(rareItemsTable) do
                    local roll = math.random(1, 100)
                    local itemRarity = item.rarity or 50
                    local adjustedRarity = math.max(1, itemRarity - rareChanceModifier)
                    if roll >= adjustedRarity then
                        rareCandidates[#rareCandidates + 1] = item
                    end
                end
                if #rareCandidates == 0 then
                    rareCandidates[1] = rareItemsTable[math.random(1, #rareItemsTable)]
                end
                local chosenRare = rareCandidates[math.random(1, #rareCandidates)]
                finalLoot[#finalLoot + 1] = chosenRare
                if Config.DebugMode then
                    print(("[DEBUG] Lucky roll! Awarded extra rare item: %s"):format(chosenRare.name))
                end
            end
        end
    end
    
    -- Give items to player with quantity scaling (More rewards)
    local itemsAwarded = 0
    local levelScaling = Config.LootLevelScaling or {}
    local quantityMultiplier = 1.0
    if levelScaling.enabled and level then
        quantityMultiplier = 1.0 + (level - 1) * (levelScaling.quantityMultiplierPerLevel or 0.0)
    end
    
    for _, item in ipairs(finalLoot) do
        local minCount = item.min or 1
        local maxCount = item.max or 1
        local baseCount = math.random(minCount, maxCount)
        local count = math.floor(baseCount * quantityMultiplier)
        if count < 1 and baseCount > 0 then count = 1 end
        
        if count > 0 then
            local success = exports.ox_inventory:AddItem(src, item.name, count)
            if success then
                itemsAwarded = itemsAwarded + 1
            end
        end
    end
    
    if itemsAwarded == 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Dumpster Diving',
            description = Config.Lang['fail'],
            type = 'error'
        })
    else
        local extraMsg = ""
        if citizenid then
            local xpGained = Config.XP.XPGainedPerSearch or 5
            local newRep = addXP(citizenid, xpGained)
            local newLevel = newRep.dumpster_level or 1
            
            if newLevel > level then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Level Up!',
                    description = ("You reached Dumpster Level %d!"):format(newLevel),
                    type = 'success',
                    duration = 5000
                })
            else
                extraMsg = (" (+%d XP)"):format(xpGained)
            end
        end
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Dumpster Diving',
            description = "You found some useful items in the trash!" .. extraMsg,
            type = 'success'
        })
    end
end)

-- Callback to get player dumpster reputation/progression stats
lib.callback.register('vitrue-dumpster:server:getReputation', function(source)
    local citizenid = getCitizen(source)
    if not citizenid then return nil end
    return getReputation(citizenid)
end)

-- Admin Commands
lib.addCommand('dumpsterlevel', {
    help = 'Set a player dumpster level',
    params = {
        { name = 'id', type = 'playerId', help = 'Player ID' },
        { name = 'level', type = 'number', help = 'Level' },
    },
    restricted = 'group.admin',
}, function(source, args)
    local citizenid = getCitizen(args.id)
    if not citizenid then return end
    local rep = setLevel(citizenid, args.level)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Dumpster Diving',
        description = ('Set dumpster level to %s.'):format(rep.dumpster_level),
        type = 'success'
    })
end)

lib.addCommand('dumpsterxp', {
    help = 'Add dumpster reputation XP',
    params = {
        { name = 'id', type = 'playerId', help = 'Player ID' },
        { name = 'amount', type = 'number', help = 'XP amount' },
    },
    restricted = 'group.admin',
}, function(source, args)
    local citizenid = getCitizen(args.id)
    if not citizenid then return end
    local rep = addXP(citizenid, args.amount)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Dumpster Diving',
        description = ('Dumpster XP is now %s, level %s.'):format(rep.dumpster_xp, rep.dumpster_level),
        type = 'success'
    })
end)


