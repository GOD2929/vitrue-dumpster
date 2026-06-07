local isSearching = false
local drugged = false
local searchModelHashes = nil

-- Load animation dictionary utility
local function loadAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > timeout then
            return false
        end
        Wait(5)
    end
    return true
end

-- Aggressive Ped Logic
local function CheckForAggressivePeds(coords)
    if not Config.AggressivePedsAttack then return end
    local ped = PlayerPedId()
    local peds = GetGamePool('CPed')
    for i = 1, #peds do
        local targetPed = peds[i]
        if targetPed ~= ped and not IsPedAPlayer(targetPed) and not IsEntityDead(targetPed) then
            local targetModel = GetEntityModel(targetPed)
            local isHostile = false
            for _, model in ipairs(Config.AggressivePeds) do
                if targetModel == GetHashKey(model) then
                    isHostile = true
                    break
                end
            end
            if isHostile then
                local dist = #(coords - GetEntityCoords(targetPed))
                if dist <= Config.AggressivePedDistance then
                    ClearPedTasksImmediately(targetPed)
                    
                    if IsPedHuman(targetPed) then
                        PlayAmbientSpeech1(targetPed, "GENERIC_CURSE_HIGH", "SPEECH_PARAMS_FORCE_SHOUT")
                        
                        -- Handle Melee Weapon Spawn (Only for human peds)
                        if Config.AggressivePedWeapons.GiveMeleeWeapon.enabled then
                            local chance = math.random(1, 100)
                            if chance <= Config.AggressivePedWeapons.GiveMeleeWeapon.chance then
                                local weapon = Config.AggressivePedWeapons.GiveMeleeWeapon.weapons[math.random(1, #Config.AggressivePedWeapons.GiveMeleeWeapon.weapons)]
                                GiveWeaponToPed(targetPed, GetHashKey(weapon), 1, false, true)
                                SetCurrentPedWeapon(targetPed, GetHashKey(weapon), true)
                            else
                                local weaponChance = math.random(1, 100)
                                local weaponType = nil
                                if weaponChance >= Config.AggressivePedWeapons.ChanceThresholds.Rare then
                                    weaponType = Config.AggressivePedWeapons.Weapons.Rare
                                elseif weaponChance >= Config.AggressivePedWeapons.ChanceThresholds.Uncommon then
                                    weaponType = Config.AggressivePedWeapons.Weapons.Uncommon
                                elseif weaponChance >= Config.AggressivePedWeapons.ChanceThresholds.Common then
                                    weaponType = Config.AggressivePedWeapons.Weapons.Common
                                end
                                if weaponType then
                                    GiveWeaponToPed(targetPed, GetHashKey(weaponType.name), weaponType.ammo, false, true)
                                    SetCurrentPedWeapon(targetPed, GetHashKey(weaponType.name), true)
                                end
                            end
                        end
                    end
                    
                    TaskCombatPed(targetPed, ped, 0, 16)
                    lib.notify({
                        title = 'Dumpster Diving',
                        description = Config.Lang['aggressive_ped'],
                        type = 'error'
                    })
                    break
                end
            end
        end
    end
end

-- Raccoon/Rat Effect
RegisterNetEvent('vitrue-dumpster:client:triggerRatEffect', function(healthLoss)
    local ped = PlayerPedId()
    local dict = Config.RatFailAnim.dict
    local anim = Config.RatFailAnim.anim
    
    loadAnimDict(dict)
    TaskPlayAnim(ped, dict, anim, 8.0, 8.0, -1, 49, 0, false, false, false)
    
    local model = `a_c_rat`
    if IsModelInCdimage(model) then
        RequestModel(model)
        local timeout = 100 -- 1 second timeout
        while not HasModelLoaded(model) and timeout > 0 do
            Wait(10)
            timeout = timeout - 1
        end
        
        if HasModelLoaded(model) then
            local coords = GetEntityCoords(ped)
            local forward = GetEntityForwardVector(ped)
            local spawnCoords = coords + forward * 0.3
            -- Spawn local entity (false for isNetworked) to reduce OneSync traffic
            local spawnPed = CreatePed(4, model, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(ped), false, false)
            
            TaskSmartFleePed(spawnPed, ped, 50.0, -1, false, false)
            SetPedAsNoLongerNeeded(spawnPed)
            
            -- Cleanup ped
            SetTimeout(30000, function()
                if DoesEntityExist(spawnPed) then
                    DeletePed(spawnPed)
                end
            end)
        end
    end
    
    Wait(2000)
    ClearPedTasks(ped)
    
    lib.notify({
        title = 'Dumpster Diving',
        description = Config.Lang['rat'],
        type = 'error'
    })
end)

-- Dirty Needle Effect
RegisterNetEvent('vitrue-dumpster:client:triggerNeedleEffect', function(effectTime, healthLoss)
    drugged = true
    local ped = PlayerPedId()
    
    local dict = Config.DirtyNeedlesFailAnim.dict
    local anim = Config.DirtyNeedlesFailAnim.anim
    loadAnimDict(dict)
    TaskPlayAnim(ped, dict, anim, 8.0, 8.0, -1, 49, 0, false, false, false)
    Wait(2000)
    ClearPedTasks(ped)
    
    AnimpostfxPlay("DrugsMichaelAliensFight", 0, true)
    ApplyPedBlood(ped, 0, 0.0, 0.0, 0.0, "wound_sheet")
    
    RequestAnimSet("MOVE_M@DRUNK@MODERATEDRUNK")
    while not HasAnimSetLoaded("MOVE_M@DRUNK@MODERATEDRUNK") do
        Wait(0)
    end
    SetPedMovementClipset(ped, "MOVE_M@DRUNK@MODERATEDRUNK", 0.0)
    
    lib.notify({
        title = 'Dumpster Diving',
        description = Config.Lang['needles'],
        type = 'error'
    })
    
    SetTimeout(effectTime * 1000, function()
        drugged = false
        AnimpostfxStop("DrugsMichaelAliensFight")
        ResetPedMovementClipset(ped, 0)
    end)
end)

-- Main Search Function
local function StartDumpsterSearch(data, category, customIndex)
    if isSearching then return end
    isSearching = true

    local ped = PlayerPedId()
    local entity = data.entity
    if not DoesEntityExist(entity) then
        isSearching = false
        return
    end

    if category == 'custom' and (not customIndex or not Config.CustomSearchables[customIndex]) then
        isSearching = false
        return
    end
    
    local coords = GetEntityCoords(entity)
    local model = GetEntityModel(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId == 0 then netId = nil end

    local roundedCoords = vector3(
        math.floor(coords.x * 10) / 10,
        math.floor(coords.y * 10) / 10,
        math.floor(coords.z * 10) / 10
    )
    
    -- Check Cooldown and Level Requirements on Server
    local canSearch, reason = lib.callback.await('vitrue-dumpster:server:canSearch', false, roundedCoords, category, customIndex, model, netId)
    if not canSearch then
        lib.notify({
            title = 'Dumpster Diving',
            description = reason or Config.Lang['trash_empty'],
            type = 'error'
        })
        isSearching = false
        return
    end
    
    -- Pick Random Animation based on category
    local anims = Config.DumpsterAnims
    if category == 'beach' then
        anims = Config.BeachCanAnims
    elseif category == 'garbage' then
        anims = Config.GarbageCanAnims
    elseif category == 'bag' then
        anims = Config.TrashBagAnims
    elseif category == 'custom' and customIndex then
        anims = Config.CustomSearchables[customIndex].anims
    end
    
    local chosenAnim = anims[math.random(1, #anims)]
    loadAnimDict(chosenAnim.dict)
    
    -- Check for Aggressive Peds nearby
    CheckForAggressivePeds(coords)
    
    local searchDuration = math.random(10000, 13000)
    
    local completed = lib.progressBar({
        duration = searchDuration,
        label = Config.Lang['searching'],
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = chosenAnim.dict,
            clip = chosenAnim.anim,
            flag = 49,
        }
    })

    isSearching = false
    ClearPedTasks(ped)
    if completed then
        TriggerServerEvent('vitrue-dumpster:server:searchComplete', roundedCoords, category, customIndex, model, netId)
        
        -- If custom searchable is set to delete prop, delete it on complete
        if category == 'custom' and customIndex and Config.CustomSearchables[customIndex].deleteProp then
            SetEntityAsMissionEntity(entity, true, true)
            DeleteEntity(entity)
        end
    end
end

-- Initialize ox_target model registration
CreateThread(function()
    -- Beach Cans
    exports.ox_target:addModel(Config.BeachCans, {
        {
            name = 'search_beach_can',
            icon = 'fa-solid fa-dumpster',
            label = 'Search Beach Can',
            onSelect = function(data)
                StartDumpsterSearch(data, 'beach')
            end
        }
    })
    
    -- Dumpsters
    exports.ox_target:addModel(Config.Dumpsters, {
        {
            name = 'search_dumpster',
            icon = 'fa-solid fa-dumpster',
            label = 'Search Dumpster',
            onSelect = function(data)
                StartDumpsterSearch(data, 'dumpster')
            end
        }
    })
    
    -- Garbage Cans
    exports.ox_target:addModel(Config.GarbageCans, {
        {
            name = 'search_garbage_can',
            icon = 'fa-solid fa-dumpster',
            label = 'Search Garbage Can',
            onSelect = function(data)
                StartDumpsterSearch(data, 'garbage')
            end
        }
    })
    
    -- Campsites
    exports.ox_target:addModel(Config.Campsites, {
        {
            name = 'search_campsite',
            icon = 'fa-solid fa-campground',
            label = 'Search Campsite',
            onSelect = function(data)
                StartDumpsterSearch(data, 'campsite')
            end
        }
    })
    
    -- Trash Bags
    exports.ox_target:addModel(Config.TrashBagModels, {
        {
            name = 'search_bag',
            icon = 'fa-solid fa-trash-can',
            label = 'Search Trash Bag',
            onSelect = function(data)
                StartDumpsterSearch(data, 'bag')
            end
        }
    })
    
    -- Custom Searchables
    for i, searchable in ipairs(Config.CustomSearchables) do
        exports.ox_target:addModel(searchable.models, {
            {
                name = 'custom_search_' .. i,
                icon = 'fa-solid fa-magnifying-glass',
                label = searchable.label,
                onSelect = function(data)
                    StartDumpsterSearch(data, 'custom', i)
                end
            }
        })
    end
end)

-- Stats UI menus
RegisterNetEvent('vitrue-dumpster:client:openStats', function()
    local rep = lib.callback.await('vitrue-dumpster:server:getReputation', false)
    if not rep then
        lib.notify({
            title = 'Dumpster Diving',
            description = 'Unable to load your stats.',
            type = 'error'
        })
        return
    end
    
    local currentLevel = rep.dumpster_level or 1
    local currentXP = rep.dumpster_xp or 0
    local nextLevelXP = Config.XP.levels[currentLevel + 1] or "Max Level"
    
    local options = {
        {
            title = ('Level: %d'):format(currentLevel),
            description = 'Your dumpster diving/garbage level',
            icon = 'star',
            iconColor = '#ffb703'
        },
        {
            title = ('XP: %d / %s'):format(currentXP, tostring(nextLevelXP)),
            description = 'Progress to next level',
            icon = 'circle-up',
            iconColor = '#219ebc'
        },
        {
            title = 'Level Requirements',
            description = 'Check what level you need for each category',
            icon = 'lock-open',
            iconColor = '#8ecae6',
            onSelect = function()
                TriggerEvent('vitrue-dumpster:client:openUnlocks')
            end
        }
    }
    
    lib.registerContext({
        id = 'vitrue_dumpster_stats',
        title = 'Garbage Stats',
        options = options
    })
    lib.showContext('vitrue_dumpster_stats')
end)

RegisterNetEvent('vitrue-dumpster:client:openUnlocks', function()
    local options = {}
    local req = Config.LevelRequirements
    
    local function formatReq(val)
        return ("Level %d+ Required"):format(val)
    end
    
    options[#options + 1] = {
        title = 'Beach Cans',
        description = formatReq(req.beach or 1),
        icon = 'umbrella-beach',
        iconColor = '#ffb703'
    }
    options[#options + 1] = {
        title = 'Trash Bags',
        description = formatReq(req.bag or 1),
        icon = 'trash-can',
        iconColor = '#219ebc'
    }
    options[#options + 1] = {
        title = 'Garbage Cans',
        description = formatReq(req.garbage or 1),
        icon = 'trash',
        iconColor = '#023047'
    }
    options[#options + 1] = {
        title = 'Dumpsters',
        description = formatReq(req.dumpster or 1),
        icon = 'dumpster',
        iconColor = '#fb8500'
    }
    options[#options + 1] = {
        title = 'Campsites',
        description = formatReq(req.campsite or 1),
        icon = 'campground',
        iconColor = '#8ecae6'
    }
    
    -- Custom searchables
    for i, cs in ipairs(Config.CustomSearchables) do
        options[#options + 1] = {
            title = cs.label or ('Custom ' .. i),
            description = formatReq(req.Custom and req.Custom[i] or 1),
            icon = 'magnifying-glass',
            iconColor = '#2a9d8f'
        }
    end
    
    lib.registerContext({
        id = 'vitrue_dumpster_unlocks',
        title = 'Category Unlocks',
        menu = 'vitrue_dumpster_stats',
        options = options
    })
    lib.showContext('vitrue_dumpster_unlocks')
end)

RegisterCommand('dumpsterstats', function()
    TriggerEvent('vitrue-dumpster:client:openStats')
end, false)

-- ==========================================
-- New Features: Disease & Hidden Compartments
-- ==========================================

-- Cough Animation Helper
local function PlayCoughAnimation()
    local ped = PlayerPedId()
    loadAnimDict("amb@code_human_in_car_mp_actions@cough@std@ps@base")
    TaskPlayAnim(ped, "amb@code_human_in_car_mp_actions@cough@std@ps@base", "enter", 8.0, 8.0, 3000, 49, 0, false, false, false)
    PlayAmbientSpeech1(ped, "GENERIC_COUGH", "SPEECH_PARAMS_FORCE")
end

-- Sickness / Infection Active Thread
CreateThread(function()
    while true do
        if LocalPlayer.state.sanitationInfected then
            local ped = PlayerPedId()
            if not IsEntityDead(ped) then
                local health = GetEntityHealth(ped)
                -- Let's drain health but not instantly kill, or let it down them based on standard GTA health (0 is dead, on some servers 100 is dead. Let's use math.max(0) to allow standard downing/death).
                SetEntityHealth(ped, math.max(0, health - Config.Disease.HealthDrain))
                
                -- Sickness visual effects
                ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.08)
                PlayCoughAnimation()
                
                lib.notify({
                    title = 'Sickness',
                    description = "You feel weak and cough heavily from the infection...",
                    type = 'error'
                })
            end
            Wait(Config.Disease.DrainInterval * 1000)
        else
            Wait(2000)
        end
    end
end)

-- Notify client on infection start
AddStateBagChangeHandler("sanitationInfected", nil, function(bagName, key, value, reserved, replicated)
    local ply = GetPlayerFromStateBagName(bagName)
    if ply == PlayerId() then
        if value then
            lib.notify({
                title = 'Sickness',
                description = Config.Lang['infected'],
                type = 'error',
                duration = 7000
            })
        end
    end
end)

-- Find closest searchable entity to coords helper
local function FindSearchableEntityAtCoords(coords)
    if not searchModelHashes then
        searchModelHashes = {}
        for _, model in ipairs(Config.BeachCans) do searchModelHashes[#searchModelHashes + 1] = GetHashKey(model) end
        for _, model in ipairs(Config.Dumpsters) do searchModelHashes[#searchModelHashes + 1] = GetHashKey(model) end
        for _, model in ipairs(Config.GarbageCans) do searchModelHashes[#searchModelHashes + 1] = GetHashKey(model) end
        for _, model in ipairs(Config.Campsites) do searchModelHashes[#searchModelHashes + 1] = GetHashKey(model) end
        for _, model in ipairs(Config.TrashBagModels) do searchModelHashes[#searchModelHashes + 1] = GetHashKey(model) end
        for _, cs in ipairs(Config.CustomSearchables) do
            for _, model in ipairs(cs.models) do
                searchModelHashes[#searchModelHashes + 1] = GetHashKey(model)
            end
        end
    end
    
    for _, model in ipairs(searchModelHashes) do
        local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 2.0, model, false, false, false)
        if DoesEntityExist(entity) then
            return entity
        end
    end
    return nil
end

-- Event: Hidden Compartment Found
RegisterNetEvent('vitrue-dumpster:client:foundCompartment', function(coords)
    local entity = FindSearchableEntityAtCoords(coords)
    if not entity or not DoesEntityExist(entity) then return end
    
    lib.notify({
        title = 'Dumpster Diving',
        description = Config.Lang['found_compartment'],
        type = 'success',
        duration = 6000
    })
    
    -- Register target option for this specific local entity
    exports.ox_target:addLocalEntity(entity, {
        {
            name = 'pry_hidden_compartment',
            icon = 'fa-solid fa-screwdriver',
            label = 'Pry Open Hidden Compartment',
            onSelect = function(data)
                -- Call local handler passing entity and coords
                TriggerEvent('vitrue-dumpster:client:pryCompartmentMenu', data.entity, coords)
            end
        }
    })
end)

-- Helper: Start Prying Compartment
local function StartPryCompartment(entity, coords, tool)
    local toolConfig = Config.HiddenCompartments.Tools[tool] or Config.HiddenCompartments.Tools[string.lower(tostring(tool))]
    if not toolConfig then return end
    
    -- Check if tool is still in inventory
    local toolCount = exports.ox_inventory:Search('count', tool)
    if toolCount <= 0 then
        lib.notify({
            title = 'Compartment',
            description = "You no longer have this tool!",
            type = 'error'
        })
        return
    end
    
    local ped = PlayerPedId()
    
    -- Alert nearby peds immediately if loud tool (Crowbar)
    if toolConfig.alertChance >= 100 then
        CheckForAggressivePeds(coords)
    end
    
    local animDict = "anim@gangops@facility@servers@bodysearch@"
    local animName = "player_search"
    local normalizedTool = string.lower(tostring(tool))
    if normalizedTool == 'weapon_crowbar' then
        animDict = "amb@world_human_hammering@male@base"
        animName = "base"
    elseif normalizedTool == 'screwdriver' then
        animDict = "amb@medic@standing@tendtodead@idle_a"
        animName = "idle_a"
    end
    
    loadAnimDict(animDict)
    
    local completed = lib.progressBar({
        duration = toolConfig.pryTime,
        label = Config.Lang['prying_compartment'],
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = animDict,
            clip = animName,
            flag = 49,
        }
    })

    ClearPedTasks(ped)
    if completed then
        TriggerServerEvent('vitrue-dumpster:server:pryCompartment', coords, tool)
        exports.ox_target:removeLocalEntity(entity, 'pry_hidden_compartment')
    end
end

-- Register Menu Event
RegisterNetEvent('vitrue-dumpster:client:pryCompartmentMenu', function(entity, coords)
    local function firstAvailableItem(items)
        for _, itemName in ipairs(items) do
            if exports.ox_inventory:Search('count', itemName) > 0 then
                return itemName
            end
        end
        return nil
    end

    local crowbarItem = firstAvailableItem(Config.HiddenCompartments.ToolAliases.Crowbar)
    local lockpickItem = firstAvailableItem(Config.HiddenCompartments.ToolAliases.Lockpick)
    local screwdriverItem = firstAvailableItem(Config.HiddenCompartments.ToolAliases.Screwdriver)
    
    if not crowbarItem and not lockpickItem and not screwdriverItem then
        lib.notify({
            title = 'Compartment',
            description = Config.Lang['no_tool'],
            type = 'error'
        })
        return
    end
    
    local options = {}
    if crowbarItem then
        options[#options + 1] = {
            title = 'Pry with Crowbar',
            description = 'Fast (5s), but loud (alerts nearby guards/dogs)',
            icon = 'hammer',
            onSelect = function()
                StartPryCompartment(entity, coords, crowbarItem)
            end
        }
    end
    if lockpickItem then
        options[#options + 1] = {
            title = 'Pick with Lockpick',
            description = 'Silent, but slow (12s) and may break (15% chance)',
            icon = 'key',
            onSelect = function()
                StartPryCompartment(entity, coords, lockpickItem)
            end
        }
    end
    if screwdriverItem then
        options[#options + 1] = {
            title = 'Unscrew with Screwdriver',
            description = 'Medium (8s), quiet, but may damage items (20% chance)',
            icon = 'screwdriver',
            onSelect = function()
                StartPryCompartment(entity, coords, screwdriverItem)
            end
        }
    end
    
    lib.registerContext({
        id = 'pry_compartment_menu',
        title = 'Pry Hidden Compartment',
        options = options
    })
    lib.showContext('pry_compartment_menu')
end)

-- Event: Take Antibiotics
RegisterNetEvent('vitrue-dumpster:client:useAntibiotics', function()
    local ped = PlayerPedId()
    loadAnimDict("amb@world_human_drinking@coffee@male@base")
    TaskPlayAnim(ped, "amb@world_human_drinking@coffee@male@base", "base", 8.0, 8.0, 3000, 49, 0, false, false, false)
    
    lib.progressBar({
        duration = 3000,
        label = "Taking Antibiotics...",
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true,
        }
    })
    ClearPedTasks(ped)
end)
