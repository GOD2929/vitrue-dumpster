local QBCore = exports['qb-core']:GetCoreObject()
local isSearching = false
local drugged = false

-- Load animation dictionary utility
local function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
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
            local isTramp = false
            for _, model in ipairs(Config.AggressivePeds) do
                if targetModel == GetHashKey(model) then
                    isTramp = true
                    break
                end
            end
            if isTramp then
                local dist = #(coords - GetEntityCoords(targetPed))
                if dist <= Config.AggressivePedDistance then
                    ClearPedTasksImmediately(targetPed)
                    TaskPlayAnim(targetPed, "amb@world_human_bum_wash@male@high@idle_a", "idle_b", 8.0, -8.0, -1, 0, 0, false, false, false)
                    PlayAmbientSpeech1(targetPed, "GENERIC_CURSE_HIGH", "SPEECH_PARAMS_FORCE_SHOUT")
                    
                    -- Handle Hobo Weapon Spawn
                    if Config.AggressivePedWeapons.GiveHoboWeapon.enabled then
                        local chance = math.random(1, 100)
                        if chance <= Config.AggressivePedWeapons.GiveHoboWeapon.chance then
                            local weapon = Config.AggressivePedWeapons.GiveHoboWeapon.weapons[math.random(1, #Config.AggressivePedWeapons.GiveHoboWeapon.weapons)]
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
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnCoords = coords + forward * 0.3
    local spawnPed = CreatePed(4, model, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(ped), true, false)
    
    TaskSmartFleePed(spawnPed, ped, 50.0, -1, false, false)
    SetPedAsNoLongerNeeded(spawnPed)
    
    Wait(2000)
    ClearPedTasks(ped)
    
    lib.notify({
        title = 'Dumpster Diving',
        description = Config.Lang['rat'],
        type = 'error'
    })
    
    -- Cleanup ped
    SetTimeout(30000, function()
        if DoesEntityExist(spawnPed) then
            DeletePed(spawnPed)
        end
    end)
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
    local ped = PlayerPedId()
    local entity = data.entity
    if not DoesEntityExist(entity) then return end
    
    local coords = GetEntityCoords(entity)
    local roundedCoords = vector3(
        math.floor(coords.x * 10) / 10,
        math.floor(coords.y * 10) / 10,
        math.floor(coords.z * 10) / 10
    )
    
    -- Check Cooldown and Level Requirements on Server
    local canSearch, reason = lib.callback.await('vitrue-dumpster:server:canSearch', false, roundedCoords, category, customIndex)
    if not canSearch then
        lib.notify({
            title = 'Dumpster Diving',
            description = reason or Config.Lang['trash_empty'],
            type = 'error'
        })
        return
    end
    
    isSearching = true
    
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
    
    -- Progress Bar
    local searchDuration = math.random(10000, 13000)
    
    exports['progressbar']:Progress({
        name = "searching_dumpster",
        duration = searchDuration,
        label = Config.Lang['searching'],
        useWhileDead = false,
        canCancel = true,
        disarm = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = chosenAnim.dict,
            anim = chosenAnim.anim,
            flags = 49,
        }
    }, function(cancelled)
        isSearching = false
        ClearPedTasks(ped)
        if not cancelled then
            TriggerServerEvent('vitrue-dumpster:server:searchComplete', roundedCoords, category, customIndex)
            
            -- If custom searchable is set to delete prop, delete it on complete
            if category == 'custom' and customIndex and Config.CustomSearchables[customIndex].deleteProp then
                SetEntityAsMissionEntity(entity, true, true)
                DeleteEntity(entity)
            end
        end
    end)
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
    
    -- Other Searchables
    exports.ox_target:addModel(Config.OtherSearchables, {
        {
            name = 'search_other',
            icon = 'fa-solid fa-dumpster',
            label = 'Search Prop',
            onSelect = function(data)
                StartDumpsterSearch(data, 'other')
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
        title = 'Other Searchables',
        description = formatReq(req.other or 1),
        icon = 'box-open',
        iconColor = '#8ecae6'
    }
    
    -- Custom searchables
    for i, cs in ipairs(Config.CustomSearchables) do
        options[#options + 1] = {
            title = cs.label or ('Custom ' .. i),
            description = formatReq(req.custom and req.custom[i] or 1),
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
