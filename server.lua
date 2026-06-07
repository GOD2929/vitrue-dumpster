local searchCooldowns = {}
local activeCompartments = {}
local pendingSearches = {}
local playerReputations = {}
local playerCitizenIds = {}
local antibioticsInProgress = {}

assert(Config.DatabaseTable and Config.DatabaseTable:match('^[%w_]+$'), 'Invalid Config.DatabaseTable value')

-- Safely check for qb-core to prevent startup crashes on pure QBox
local hasQBX = GetResourceState('qbx_core') == 'started'
local QBCore = GetResourceState('qb-core') == 'started' and exports['qb-core']:GetCoreObject() or nil

-- Get player citizenid
local function getCitizen(src)
    if hasQBX then
        local qbxPlayer = exports.qbx_core:GetPlayer(src)
        if qbxPlayer then
            playerCitizenIds[src] = qbxPlayer.PlayerData.citizenid
        end
        return qbxPlayer and qbxPlayer.PlayerData.citizenid, qbxPlayer
    end
    if QBCore then
        local player = QBCore.Functions.GetPlayer(src)
        if player then
            playerCitizenIds[src] = player.PlayerData.citizenid
            return player.PlayerData.citizenid, player
        end
    end
    return nil, nil
end

-- Clear cache when player drops to save memory
AddEventHandler('playerDropped', function()
    local src = source
    local citizenid = playerCitizenIds[src]
    if citizenid then
        playerReputations[citizenid] = nil
    end
    playerCitizenIds[src] = nil
    pendingSearches[src] = nil
    antibioticsInProgress[src] = nil
end)

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
    if playerReputations[citizenid] then
        return playerReputations[citizenid]
    end
    
    if not MySQL or not MySQL.single then
        return defaultReputation(citizenid)
    end
    
    local query = 'SELECT dumpster_xp, dumpster_level FROM `' .. Config.DatabaseTable .. '` WHERE citizenid = ?'
    local row = MySQL.single.await(query, { citizenid })
    if row then
        row.dumpster_level = getLevelFromXP(row.dumpster_xp)
        playerReputations[citizenid] = row
        return row
    end
    
    local rep = defaultReputation(citizenid)
    MySQL.insert.await('INSERT IGNORE INTO `' .. Config.DatabaseTable .. '` (citizenid) VALUES (?)', { citizenid })
    playerReputations[citizenid] = rep
    return rep
end

local function addXP(citizenid, amount)
    local rep = getReputation(citizenid)
    local xp = math.max(0, (rep.dumpster_xp or 0) + (tonumber(amount) or 0))
    local level = getLevelFromXP(xp)
    
    rep.dumpster_xp = xp
    rep.dumpster_level = level
    playerReputations[citizenid] = rep
    
    if MySQL and MySQL.update then
        local query = 'INSERT INTO `' .. Config.DatabaseTable .. '` (citizenid, dumpster_xp, dumpster_level) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE dumpster_xp = ?, dumpster_level = ?'
        MySQL.update.await(query, { citizenid, xp, level, xp, level })
    end
    
    return rep
end

local function setLevel(citizenid, level)
    level = math.max(1, tonumber(level) or 1)
    local xp = Config.XP.levels[level] or 0
    
    local rep = getReputation(citizenid)
    rep.dumpster_xp = xp
    rep.dumpster_level = level
    playerReputations[citizenid] = rep
    
    if MySQL and MySQL.update then
        local query = 'INSERT INTO `' .. Config.DatabaseTable .. '` (citizenid, dumpster_xp, dumpster_level) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE dumpster_xp = ?, dumpster_level = ?'
        MySQL.update.await(query, { citizenid, xp, level, xp, level })
    end
    return rep
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

local function getSearchKey(coords, category, customIndex, model)
    return ('%s:%s:%s:%s'):format(category or 'unknown', customIndex or 0, tonumber(model) or 0, getCoordsKey(coords))
end

local function setDumpsterCooldown(key)
    local searchedAt = os.time()
    searchCooldowns[key] = searchedAt

    SetTimeout(((Config.TrashCooldown * 60) + 60) * 1000, function()
        if searchCooldowns[key] == searchedAt then
            searchCooldowns[key] = nil
        end
    end)
end

local function isValidCoords(coords)
    return coords
        and type(coords.x) == 'number'
        and type(coords.y) == 'number'
        and type(coords.z) == 'number'
end

local validCategories = {
    beach = true,
    garbage = true,
    campsite = true,
    bag = true,
    dumpster = true,
    custom = true,
}

local function hashModel(model)
    if type(model) == 'number' then return model end
    if joaat then return joaat(model) end
    return nil
end

local searchModelHashes = {}

local function addModelHashes(category, models, customIndex)
    local categoryKey = category == 'custom' and ('custom:' .. customIndex) or category
    searchModelHashes[categoryKey] = searchModelHashes[categoryKey] or {}

    for _, model in ipairs(models or {}) do
        local hash = hashModel(model)
        if hash then
            searchModelHashes[categoryKey][hash] = true
        end
    end
end

addModelHashes('beach', Config.BeachCans)
addModelHashes('garbage', Config.GarbageCans)
addModelHashes('campsite', Config.Campsites)
addModelHashes('bag', Config.TrashBagModels)
addModelHashes('dumpster', Config.Dumpsters)
for i, searchable in ipairs(Config.CustomSearchables or {}) do
    addModelHashes('custom', searchable.models, i)
end

local function validateSearchCategory(category, customIndex)
    if not validCategories[category] then
        return nil, nil, nil
    end

    if category == 'custom' then
        customIndex = tonumber(customIndex)
        if not customIndex or customIndex % 1 ~= 0 then
            return nil, nil, nil
        end

        local custom = Config.CustomSearchables[customIndex]
        if not custom or not custom.loot or not custom.anims then
            return nil, nil, nil
        end

        return category, customIndex, custom
    end

    return category, nil, nil
end

local function getRequiredLevel(category, customIndex)
    if category == 'custom' then
        return (Config.LevelRequirements.Custom and Config.LevelRequirements.Custom[customIndex]) or 1
    end

    return Config.LevelRequirements[category] or 1
end

local function validateSearchModel(category, customIndex, model)
    model = tonumber(model)
    if not model then return false end

    local categoryKey = category == 'custom' and ('custom:' .. customIndex) or category
    return searchModelHashes[categoryKey] and searchModelHashes[categoryKey][model] == true
end

local function validateNetworkedEntity(netId, coords, model)
    if not netId then return true end

    netId = tonumber(netId)
    if not netId or netId <= 0 then return true end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    if GetEntityModel(entity) ~= model then return false end
    if #(GetEntityCoords(entity) - coords) > 1.5 then return false end

    return true
end

local function isRainingWeather(weather)
    if not weather then return false end

    local weatherType = type(weather) == 'number' and weather or tostring(weather):upper()
    return weatherType == `RAIN`
        or weatherType == `THUNDER`
        or weatherType == `CLEARING`
        or weatherType == 'RAIN'
        or weatherType == 'THUNDER'
        or weatherType == 'CLEARING'
end

-- Callback to check if player can search dumpster
lib.callback.register('vitrue-dumpster:server:canSearch', function(source, coords, category, customIndex, model, netId)
    if not isValidCoords(coords) then return false, Config.Lang['fail'] end

    category, customIndex = validateSearchCategory(category, customIndex)
    if not category then return false, Config.Lang['fail'] end
    if not validateSearchModel(category, customIndex, model) then return false, Config.Lang['fail'] end
    if not validateNetworkedEntity(netId, coords, model) then return false, Config.Lang['fail'] end

    local playerPed = GetPlayerPed(source)
    if not playerPed or playerPed == 0 then return false, Config.Lang['fail'] end

    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - coords) > 5.0 then return false, Config.Lang['fail'] end

    local key = getSearchKey(coords, category, customIndex, model)
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
            local reqLevel = getRequiredLevel(category, customIndex)
            
            if level < reqLevel then
                return false, ("You need dumpster level %d to search this!"):format(reqLevel)
            end
        end
    end
    
    pendingSearches[source] = {
        key = key,
        coords = coords,
        category = category,
        customIndex = customIndex,
        model = tonumber(model),
        netId = tonumber(netId),
        readyAt = GetGameTimer() + 9000,
        expiresAt = os.time() + 45,
    }

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

local function calculateScaledCount(item, quantityMultiplier)
    local minCount = item.min or 1
    local maxCount = item.max or 1
    local baseCount = math.random(minCount, maxCount)
    local count = math.floor(baseCount * quantityMultiplier)
    if count < 1 and baseCount > 0 then count = 1 end
    return count
end

local function addLootItem(src, item, count)
    if count <= 0 then return false end
    if not exports.ox_inventory:CanCarryItem(src, item.name, count) then return false end

    local success = exports.ox_inventory:AddItem(src, item.name, count)
    return success == true
end

-- Server Event: Search Complete
-- Helper function to check in-game night time
local function IsNightTime()
    local hour = GetClockHours()
    local startHour = Config.DynamicLoot.NightTimeStart
    local endHour = Config.DynamicLoot.NightTimeEnd
    if startHour > endHour then
        return (hour >= startHour or hour < endHour)
    else
        return (hour >= startHour and hour < endHour)
    end
end

-- Helper function to check weather
local function IsItRaining()
    local weather = GlobalState.weather or GlobalState.CurrentWeather or GlobalState.Weather
    if not weather and GetPrevailingWeatherType then
        local ok, nativeWeather = pcall(GetPrevailingWeatherType)
        if ok then
            weather = nativeWeather
        end
    end

    return isRainingWeather(weather)
end

-- Server Event: Search Complete
RegisterNetEvent('vitrue-dumpster:server:searchComplete', function(coords, category, customIndex, model, netId)
    local src = source
    if not isValidCoords(coords) then return end

    category, customIndex = validateSearchCategory(category, customIndex)
    if not category then return end
    if not validateSearchModel(category, customIndex, model) then return end
    if not validateNetworkedEntity(netId, coords, model) then return end
    
    local key = getSearchKey(coords, category, customIndex, model)
    local pending = pendingSearches[src]
    pendingSearches[src] = nil
    if not pending
        or pending.expiresAt < os.time()
        or pending.readyAt > GetGameTimer()
        or pending.key ~= key
        or pending.category ~= category
        or pending.customIndex ~= customIndex then
        return
    end
    
    -- Verify distance between player and target coordinates (Secures against remote exec exploits)
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - coords) > 5.0 then
        return
    end
    
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
        local reqLevel = getRequiredLevel(category, customIndex)
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
    setDumpsterCooldown(key)
    
    -- Check if gloves protect from fail events using correct server export GetItemCount
    local glovesCount = exports.ox_inventory:GetItemCount(src, Config.GlovesItem) or 0
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
                
                -- Contract infection check
                if math.random(1, 100) <= Config.Disease.InfectChanceOnFail then
                    Player(src).state.sanitationInfected = true
                end
                return
            elseif Config.Fails.EnableRatEvent and roll <= (Config.Fails.DirtyNeedlesChancePercent + Config.Fails.RatChancePercent) then
                -- Rat event
                local damage = Config.Fails.RatHealthLoss
                TriggerClientEvent('vitrue-dumpster:client:triggerRatEffect', src, damage)
                local ped = GetPlayerPed(src)
                local health = GetEntityHealth(ped)
                SetEntityHealth(ped, math.max(1, health - damage))
                
                -- Contract infection check
                if math.random(1, 100) <= Config.Disease.InfectChanceOnFail then
                    Player(src).state.sanitationInfected = true
                end
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
        elseif category == 'campsite' then
            itemsTable = Config.CampsiteItems
            rareItemsTable = Config.CampsiteItemsRare
            rareChance = Config.CampsiteItemsRareChance
        elseif category == 'bag' then
            itemsTable = Config.GarbageBagsItems
            rareItemsTable = Config.GarbageBagsItemsRare
            rareChance = Config.GarbageBagsItemsRareChance
        elseif category == 'custom' and customIndex then
            local custom = Config.CustomSearchables[customIndex]
            if not custom or not custom.loot then return end
            itemsTable = custom.loot
            rareChance = 0 -- Custom searchables don't use rare tables by default
        else
            -- Default to dumpster
            itemsTable = Config.DumpsterItems
            rareItemsTable = Config.DumpsterItemsRare
            rareChance = Config.DumpsterItemsRareChance
        end
        
        finalLoot = GetLootFromTable(itemsTable, 4, level)
        
        -- Environmental states
        local isNight = IsNightTime()
        local isRaining = IsItRaining()
        
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
        
        -- Add environmental rare chance modifiers
        if isNight then
            finalRareChance = finalRareChance + Config.DynamicLoot.NightRareChanceModifier
        end
        if isRaining then
            finalRareChance = finalRareChance + Config.DynamicLoot.RainRareChanceModifier
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
    
    -- Append Night-Only & Rain-Only items based on environment
    local isNight = IsNightTime()
    local isRaining = IsItRaining()
    
    if isNight and #Config.DynamicLoot.NightOnlyLoot > 0 then
        if math.random(1, 100) <= 30 then
            local nightLoot = GetLootFromTable(Config.DynamicLoot.NightOnlyLoot, 1, level)
            for _, item in ipairs(nightLoot) do
                finalLoot[#finalLoot + 1] = item
            end
        end
    end
    
    if isRaining and #Config.DynamicLoot.RainOnlyLoot > 0 then
        if math.random(1, 100) <= 30 then
            local rainLoot = GetLootFromTable(Config.DynamicLoot.RainOnlyLoot, 1, level)
            for _, item in ipairs(rainLoot) do
                finalLoot[#finalLoot + 1] = item
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
        local count = calculateScaledCount(item, quantityMultiplier)
        if addLootItem(src, item, count) then
            itemsAwarded = itemsAwarded + 1
        end
    end
    
    if itemsAwarded == 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Dumpster Diving',
            description = Config.Lang['fail'],
            type = 'error'
        })
    else
        -- Roll for Hidden Compartment (Feature 3)
        if math.random(1, 100) <= Config.HiddenCompartments.TriggerChance then
            local activeKey = getCoordsKey(coords)
            activeCompartments[activeKey] = os.time() + 900
            SetTimeout(900000, function()
                if activeCompartments[activeKey] and activeCompartments[activeKey] <= os.time() then
                    activeCompartments[activeKey] = nil
                end
            end)
            TriggerClientEvent('vitrue-dumpster:client:foundCompartment', src, coords)
        end
        
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

-- Event: Pry Hidden Compartment Loot & Tool Checks
RegisterNetEvent('vitrue-dumpster:server:pryCompartment', function(coords, tool)
    local src = source
    if not isValidCoords(coords) then return end
    
    -- Verify player distance to coordinates (Secures against remote executions)
    local playerPed = GetPlayerPed(src)
    if not playerPed or playerPed == 0 then return end

    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - coords) > 5.0 then
        return
    end
    
    -- Verify hidden compartment actually exists at coords (Secures against arbitrary loot requests)
    local activeKey = getCoordsKey(coords)
    if not activeCompartments[activeKey] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Compartment',
            description = "There is no compartment here to pry!",
            type = 'error'
        })
        return
    end
    if activeCompartments[activeKey] <= os.time() then
        activeCompartments[activeKey] = nil
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Compartment',
            description = "There is no compartment here to pry!",
            type = 'error'
        })
        return
    end
    
    local toolConfig = Config.HiddenCompartments.Tools[tool] or Config.HiddenCompartments.Tools[string.lower(tostring(tool))]
    if not toolConfig then return end
    
    -- Verify the player actually has the tool using correct server export GetItemCount
    local toolCount = exports.ox_inventory:GetItemCount(src, tool) or 0
    if toolCount <= 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Compartment',
            description = "You don't have the correct tool!",
            type = 'error'
        })
        return
    end
    
    -- Consume compartment state so it cannot be double-pried/exploited
    activeCompartments[activeKey] = nil
    
    -- Tool durability/breaking check
    if toolConfig.breakChance > 0 then
        if math.random(1, 100) <= toolConfig.breakChance then
            exports.ox_inventory:RemoveItem(src, tool, 1)
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Tool Broken',
                description = Config.Lang['tool_broken']:format(toolConfig.label),
                type = 'error'
            })
        end
    end
    
    -- Loot damage check
    local lootDamaged = false
    if toolConfig.damageLootChance > 0 then
        if math.random(1, 100) <= toolConfig.damageLootChance then
            lootDamaged = true
        end
    end
    
    -- Award hidden compartment loot
    local citizenid = getCitizen(src)
    local rep = citizenid and getReputation(citizenid) or { dumpster_level = 1 }
    local level = rep.dumpster_level or 1
    
    -- Get hidden compartment loot table
    local finalLoot = GetLootFromTable(Config.HiddenCompartments.Loot, 2, level)
    
    -- If loot was damaged, we discard some items or reduce their quantity
    if lootDamaged then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Damaged Loot',
            description = Config.Lang['loot_damaged'],
            type = 'error'
        })
        -- Randomly remove one item if multiple
        if #finalLoot > 1 then
            table.remove(finalLoot, math.random(1, #finalLoot))
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Compartment Opened',
            description = Config.Lang['pry_success'],
            type = 'success'
        })
    end
    
    -- Give items to player with quantity scaling
    local itemsAwarded = 0
    local levelScaling = Config.LootLevelScaling or {}
    local quantityMultiplier = 1.0
    if levelScaling.enabled and level then
        quantityMultiplier = 1.0 + (level - 1) * (levelScaling.quantityMultiplierPerLevel or 0.0)
    end
    
    -- If damaged, reduce quantity multiplier further
    if lootDamaged then
        quantityMultiplier = quantityMultiplier * 0.5
    end
    
    for _, item in ipairs(finalLoot) do
        local count = calculateScaledCount(item, quantityMultiplier)
        if addLootItem(src, item, count) then
            itemsAwarded = itemsAwarded + 1
        end
    end
    
    -- Small extra XP reward for prying successfully
    if itemsAwarded > 0 and citizenid then
        local xpGained = Config.XP.XPGainedPerSearch or 5
        addXP(citizenid, xpGained)
    end
end)

-- Antibiotics Item Callback Helpers
local function startAntibioticsCure(src)
    if antibioticsInProgress[src] then return end

    antibioticsInProgress[src] = true
    TriggerClientEvent('vitrue-dumpster:client:useAntibiotics', src)
    SetTimeout(3000, function()
        antibioticsInProgress[src] = nil
        if GetPlayerPing(src) <= 0 then return end

        Player(src).state.sanitationInfected = false
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Sickness',
            description = Config.Lang['cure_infection'],
            type = 'success'
        })
    end)
end

local function isInfected(src)
    return Player(src).state.sanitationInfected == true
end

local function useAntibiotics(src, consumeItem)
    local citizenid, player = getCitizen(src)
    if player then
        if not isInfected(src) then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Sickness',
                description = 'You do not need antibiotics right now.',
                type = 'error'
            })
            return false
        end

        local success = false
        if consumeItem then
            success = exports.ox_inventory:RemoveItem(src, Config.AntibioticsItem, 1)
        else
            success = true
        end
        if success then
            startAntibioticsCure(src)
        end
        return success == true
    end
    return false
end

-- QBox/QBCore usable item hooks for non-export item use paths.
if hasQBX then
    exports.qbx_core:CreateUseableItem(Config.AntibioticsItem, function(source, item)
        useAntibiotics(source, true)
    end)
elseif QBCore then
    QBCore.Functions.CreateUseableItem(Config.AntibioticsItem, function(source, item)
        useAntibiotics(source, true)
    end)
end

-- ox usable item hook
exports('useAntibiotics', function(event, item, inventory, slot)
    if event == 'usingItem' then
        local src = inventory.id
        if not isInfected(src) then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Sickness',
                description = 'You do not need antibiotics right now.',
                type = 'error'
            })
            return false
        end
    end

    if event == 'usedItem' then
        local src = inventory.id
        useAntibiotics(src, false)
    end
end)


