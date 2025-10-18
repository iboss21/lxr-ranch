local RSGCore = exports['rsg-core']:GetCoreObject()
local herdingActive = false
local herdedAnimals = {}
local herdingTarget = nil
local herdingThreadId = nil -- Changed from boolean to thread ID
local herdingStartTime = nil
local selectedAnimals = {} -- For individual animal selection
local selectionMode = false -- Whether we're in selection mode
local animalBlips = {} -- Track blips for herded animals
lib.locale()

---------------------------------------------
-- herding command/keybind
---------------------------------------------
RegisterCommand('herd', function(source, args, rawCommand)
    if not Config.HerdingEnabled then
        lib.notify({ title = 'Herding Disabled', description = 'Animal herding is currently disabled!', type = 'error' })
        return
    end
    
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.job then
        return
    end
    
    -- Check if player works at a ranch
    local isRancher = false
    for _, ranchData in pairs(Config.RanchLocations) do
        if PlayerData.job.name == ranchData.jobaccess then
            isRancher = true
            break
        end
    end
    
    if not isRancher then
        lib.notify({ title = 'Access Denied', description = 'You must be a rancher to use herding!', type = 'error' })
        return
    end
    
    -- Check if player has required tool (if enabled)
    if Config.RequireHerdingTool then
        local hasItem = RSGCore.Functions.HasItem(Config.HerdingTool, 1)
        if not hasItem then
            lib.notify({ title = 'Missing Tool', description = 'You need a ' .. Config.HerdingTool .. ' to herd animals!', type = 'error' })
            return
        end
    end
    
    TriggerEvent('rex-ranch:client:openHerdingMenu')
end, false)

---------------------------------------------
-- herding menu
---------------------------------------------
RegisterNetEvent('rex-ranch:client:openHerdingMenu', function()
    -- Debug: Check for nearby animals
    if Config.Debug then
        local nearbyAnimals = GetNearbyAnimals()
        print('^3[HERDING DEBUG]^7 Found ' .. #nearbyAnimals .. ' nearby animals')
        for i, animal in ipairs(nearbyAnimals) do
            print('^3[HERDING DEBUG]^7 Animal ' .. i .. ': ID=' .. tostring(animal.id) .. ', Model=' .. tostring(animal.model) .. ', Distance=' .. tostring(math.floor(animal.distance * 10) / 10) .. 'm')
        end
    end
    
    if herdingActive then
        lib.registerContext({
            id = 'herding_active_menu',
            title = 'Herding Control',
            options = {
                {
                    title = 'Stop Herding',
                    description = 'Stop herding all animals (' .. #herdedAnimals .. ' animals)',
                    icon = 'fa-solid fa-stop',
                    event = 'rex-ranch:client:stopHerding'
                },
                {
                    title = 'Herding Status',
                    description = 'Currently herding ' .. #herdedAnimals .. ' animals',
                    icon = 'fa-solid fa-info',
                    disabled = true
                }
            }
        })
        lib.showContext('herding_active_menu')
    else
        local options = {
            {
                title = 'Herd by Distance',
                description = 'Herd all animals within ' .. Config.HerdingDistance .. ' units',
                icon = 'fa-solid fa-location-dot',
                event = 'rex-ranch:client:startDistanceHerding'
            },
            {
                title = 'Herd by Type',
                description = 'Select animals by type to herd',
                icon = 'fa-solid fa-filter',
                event = 'rex-ranch:client:showTypeMenu',
                arrow = true
            }
        }
        
        -- Add individual selection option if enabled
        if Config.IndividualSelectionEnabled then
            table.insert(options, {
                title = 'Select Individual Animals',
                description = 'Choose specific animals to herd',
                icon = 'fa-solid fa-hand-pointer',
                event = 'rex-ranch:client:showIndividualSelectionMenu',
                arrow = true
            })
        end
        
        lib.registerContext({
            id = 'herding_menu',
            title = 'Animal Herding',
            options = options
        })
        lib.showContext('herding_menu')
    end
end)

---------------------------------------------
-- animal type selection menu
---------------------------------------------
RegisterNetEvent('rex-ranch:client:showTypeMenu', function()
    local nearbyAnimals = GetNearbyAnimals()
    local animalTypes = {}
    local typeCounts = {}
    
    -- Count animals by type
    for _, animalData in pairs(nearbyAnimals) do
        local model = animalData.model
        if not animalTypes[model] then
            animalTypes[model] = true
            typeCounts[model] = 0
        end
        typeCounts[model] = typeCounts[model] + 1
    end
    
    local options = {}
    for model, _ in pairs(animalTypes) do
        local displayName = GetAnimalDisplayName(model)
        table.insert(options, {
            title = 'Herd ' .. displayName .. 's',
            description = typeCounts[model] .. ' ' .. displayName .. '(s) nearby',
            icon = 'fa-solid fa-paw',
            event = 'rex-ranch:client:startTypeHerding',
            args = { animalType = model }
        })
    end
    
    if #options == 0 then
        table.insert(options, {
            title = 'No Animals Found',
            description = 'No animals within herding range',
            icon = 'fa-solid fa-exclamation-triangle',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'herding_type_menu',
        title = 'Select Animal Type',
        menu = 'herding_menu',
        options = options
    })
    lib.showContext('herding_type_menu')
end)

---------------------------------------------
-- individual animal selection menu
---------------------------------------------
RegisterNetEvent('rex-ranch:client:showIndividualSelectionMenu', function()
    local nearbyAnimals = GetNearbyAnimals()
    
    if #nearbyAnimals == 0 then
        lib.notify({ title = 'No Animals', description = 'No animals found within selection range!', type = 'error' })
        return
    end
    
    local options = {}
    
    -- Add header option showing current selection
    local selectedCount = 0
    for _ in pairs(selectedAnimals) do
        selectedCount = selectedCount + 1
    end
    
    table.insert(options, {
        title = 'Selected Animals: ' .. selectedCount,
        description = 'Currently selected ' .. selectedCount .. ' animals for herding',
        icon = 'fa-solid fa-list-check',
        disabled = true
    })
    
    if selectedCount > 0 then
        table.insert(options, {
            title = 'Start Herding Selected',
            description = 'Begin herding the ' .. selectedCount .. ' selected animals',
            icon = 'fa-solid fa-play',
            event = 'rex-ranch:client:startSelectedHerding'
        })
        
        table.insert(options, {
            title = 'Clear Selection',
            description = 'Deselect all animals',
            icon = 'fa-solid fa-times',
            event = 'rex-ranch:client:clearAnimalSelection'
        })
        
        table.insert(options, {
            title = '─────────────────────────',
            disabled = true
        })
    end
    
    -- Add individual animals
    for i, animalData in ipairs(nearbyAnimals) do
        local isSelected = selectedAnimals[animalData.id] ~= nil
        local displayName = GetAnimalDisplayName(animalData.model)
        local distance = math.floor(animalData.distance * 10) / 10
        
        local statusIcon = isSelected and 'fa-solid fa-check-square' or 'fa-regular fa-square'
        local statusText = isSelected and '[SELECTED]' or '[NOT SELECTED]'
        
        -- Build description based on config
        local description = 'Click to toggle selection'
        if Config.ShowAnimalDistance then
            description = 'Distance: ' .. distance .. 'm - ' .. description
        end
        
        table.insert(options, {
            title = displayName .. ' #' .. i .. ' ' .. statusText,
            description = description,
            icon = statusIcon,
            event = 'rex-ranch:client:toggleAnimalSelection',
            args = { 
                animalData = animalData,
                animalIndex = i
            }
        })
    end
    
    lib.registerContext({
        id = 'herding_individual_menu',
        title = 'Select Animals to Herd',
        menu = 'herding_menu',
        options = options
    })
    lib.showContext('herding_individual_menu')
end)

---------------------------------------------
-- toggle animal selection
---------------------------------------------
RegisterNetEvent('rex-ranch:client:toggleAnimalSelection', function(data)
    local animalData = data.animalData
    local animalId = animalData.id
    
    if selectedAnimals[animalId] then
        -- Deselect animal
        selectedAnimals[animalId] = nil
        lib.notify({ 
            title = 'Animal Deselected', 
            description = 'Removed ' .. GetAnimalDisplayName(animalData.model) .. ' from selection',
            type = 'info'
        })
    else
        -- Check if we've reached the maximum
        local selectedCount = 0
        for _ in pairs(selectedAnimals) do
            selectedCount = selectedCount + 1
        end
        
        if selectedCount >= Config.HerdingMaxAnimals then
            lib.notify({ 
                title = 'Selection Full', 
                description = 'Maximum ' .. Config.HerdingMaxAnimals .. ' animals can be selected',
                type = 'error'
            })
            TriggerEvent('rex-ranch:client:showIndividualSelectionMenu') -- Refresh menu
            return
        end
        
        -- Select animal
        selectedAnimals[animalId] = animalData
        lib.notify({ 
            title = 'Animal Selected', 
            description = 'Added ' .. GetAnimalDisplayName(animalData.model) .. ' to selection',
            type = 'success'
        })
    end
    
    -- Refresh the menu to show updated selection
    TriggerEvent('rex-ranch:client:showIndividualSelectionMenu')
end)

---------------------------------------------
-- clear animal selection
---------------------------------------------
RegisterNetEvent('rex-ranch:client:clearAnimalSelection', function()
    local clearedCount = 0
    for _ in pairs(selectedAnimals) do
        clearedCount = clearedCount + 1
    end
    
    selectedAnimals = {}
    
    lib.notify({ 
        title = 'Selection Cleared', 
        description = 'Removed ' .. clearedCount .. ' animals from selection',
        type = 'info'
    })
    
    -- Refresh the menu
    TriggerEvent('rex-ranch:client:showIndividualSelectionMenu')
end)

---------------------------------------------
-- start herding selected animals
---------------------------------------------
RegisterNetEvent('rex-ranch:client:startSelectedHerding', function()
    if herdingActive then
        lib.notify({ title = 'Already Herding', description = 'Stop current herding session first!', type = 'error' })
        return
    end
    
    local selectedCount = 0
    local selectedList = {}
    for animalId, animalData in pairs(selectedAnimals) do
        -- Verify animal still exists and is nearby
        if DoesEntityExist(animalData.entity) then
            local playerPos = GetEntityCoords(cache.ped)
            local animalPos = GetEntityCoords(animalData.entity)
            local distance = #(playerPos - animalPos)
            
            if distance <= Config.HerdingDistance * Config.SelectionRangeMultiplier then
                table.insert(selectedList, animalData)
                selectedCount = selectedCount + 1
            end
        end
    end
    
    if selectedCount == 0 then
        lib.notify({ title = 'No Valid Animals', description = 'No selected animals are available for herding!', type = 'error' })
        selectedAnimals = {} -- Clear invalid selections
        return
    end
    
    -- Clear selection after starting herding
    selectedAnimals = {}
    
    StartHerding(selectedList, 'selected')
end)

---------------------------------------------
-- start distance-based herding
---------------------------------------------
RegisterNetEvent('rex-ranch:client:startDistanceHerding', function()
    if herdingActive then
        lib.notify({ title = 'Already Herding', description = 'Stop current herding session first!', type = 'error' })
        return
    end
    
    local nearbyAnimals = GetNearbyAnimals()
    if #nearbyAnimals == 0 then
        lib.notify({ title = 'No Animals', description = 'No animals found within herding distance!', type = 'error' })
        return
    end
    
    if #nearbyAnimals > Config.HerdingMaxAnimals then
        lib.notify({ title = 'Too Many Animals', description = 'Found ' .. #nearbyAnimals .. ' animals, max is ' .. Config.HerdingMaxAnimals, type = 'error' })
        return
    end
    
    StartHerding(nearbyAnimals, 'distance')
end)

---------------------------------------------
-- start type-based herding
---------------------------------------------
RegisterNetEvent('rex-ranch:client:startTypeHerding', function(data)
    if herdingActive then
        lib.notify({ title = 'Already Herding', description = 'Stop current herding session first!', type = 'error' })
        return
    end
    
    local nearbyAnimals = GetNearbyAnimals()
    local filteredAnimals = {}
    
    for _, animalData in pairs(nearbyAnimals) do
        if animalData.model == data.animalType then
            table.insert(filteredAnimals, animalData)
        end
    end
    
    if #filteredAnimals == 0 then
        lib.notify({ title = 'No Animals', description = 'No animals of this type found nearby!', type = 'error' })
        return
    end
    
    if #filteredAnimals > Config.HerdingMaxAnimals then
        lib.notify({ title = 'Too Many Animals', description = 'Found ' .. #filteredAnimals .. ' animals, max is ' .. Config.HerdingMaxAnimals, type = 'error' })
        return
    end
    
    StartHerding(filteredAnimals, 'type')
end)

---------------------------------------------
-- stop herding
---------------------------------------------
RegisterNetEvent('rex-ranch:client:stopHerding', function()
    if not herdingActive then return end
    
    herdingActive = false
    
    -- Stop herding thread
    if herdingThreadId then
        herdingThreadId = nil
    end
    
    -- Collect animal IDs and clear tasks
    local animalIds = {}
    for animalId, animalInfo in pairs(herdedAnimals) do
        table.insert(animalIds, animalId)
        if DoesEntityExist(animalInfo.entity) then
            ClearPedTasks(animalInfo.entity)
            local pos = GetEntityCoords(animalInfo.entity)
            local heading = GetEntityHeading(animalInfo.entity)
            TriggerServerEvent('rex-ranch:server:saveAnimalPosition', animalId, pos.x, pos.y, pos.z, heading)
        end
    end
    
    -- Disable transport mode
    if Config.TransportMode then
        TriggerEvent('rex-ranch:client:setAnimalTransporting', animalIds, false)
        if Config.Debug then
            print('^2[HERDING DEBUG]^7 Disabled transport mode for ' .. #animalIds .. ' animals')
        end
    end
    
    -- Remove all animal blips
    RemoveAllAnimalBlips()
    
    local animalCount = #herdedAnimals
    herdedAnimals = {}
    herdingTarget = nil
    herdingStartTime = nil
    
    -- Clear any pending selections
    selectedAnimals = {}
    
    lib.notify({ 
        title = 'Herding Stopped', 
        description = 'Released ' .. animalCount .. ' animals from herding', 
        type = 'success' 
    })
end)

---------------------------------------------
-- core herding functions
---------------------------------------------
function GetNearbyAnimals()
    local playerPos = GetEntityCoords(cache.ped)
    local nearbyAnimals = {}
    
    -- Try to get animal data cache, fall back to entity scanning if not available
    local animalDataCache = nil
    local success, result = pcall(function()
        return exports['rex-ranch']:GetAnimalDataCache()
    end)
    
    if success and result then
        animalDataCache = result
    end
    
    -- Method 1: Use animal data cache (preferred)
    if animalDataCache and type(animalDataCache) == 'table' then
        if Config.Debug then
            print('^3[HERDING DEBUG]^7 Using animal data cache method, found ' .. #animalDataCache .. ' animals in cache')
        end
        for i, animalData in ipairs(animalDataCache) do
            if Config.Debug then
                print('^3[HERDING DEBUG]^7 Checking animal ' .. i .. ': ID=' .. tostring(animalData.animalid or 'nil') .. ', Model=' .. tostring(animalData.model or 'nil'))
            end
            
            if animalData and animalData.pos_x and animalData.pos_y and animalData.pos_z and animalData.animalid then
                local animalPos = vector3(animalData.pos_x, animalData.pos_y, animalData.pos_z)
                local distance = #(playerPos - animalPos)
                
                if Config.Debug then
                    print('^3[HERDING DEBUG]^7 Animal ' .. animalData.animalid .. ' DB position: ' .. tostring(animalPos) .. ', Distance: ' .. tostring(math.floor(distance * 10) / 10) .. 'm')
                end
                
                if distance <= Config.HerdingDistance then
                    if Config.Debug then
                        print('^3[HERDING DEBUG]^7 Animal ' .. animalData.animalid .. ' is within herding distance, checking for spawned entity')
                    end
                    
                    -- Try to get the actual spawned entity
                    local animalEntity = nil
                    pcall(function()
                        animalEntity = exports['rex-ranch']:GetAnimalEntityById(animalData.animalid)
                    end)
                    
                    if Config.Debug then
                        print('^3[HERDING DEBUG]^7 Animal ' .. animalData.animalid .. ' entity: ' .. tostring(animalEntity) .. ', exists: ' .. tostring(animalEntity and DoesEntityExist(animalEntity)))
                    end
                    
                    if animalEntity and DoesEntityExist(animalEntity) then
                        -- Update position to current entity position (more accurate)
                        animalPos = GetEntityCoords(animalEntity)
                        distance = #(playerPos - animalPos)
                        
                        if Config.Debug then
                            print('^3[HERDING DEBUG]^7 Animal ' .. animalData.animalid .. ' actual position: ' .. tostring(animalPos) .. ', Distance: ' .. tostring(math.floor(distance * 10) / 10) .. 'm')
                        end
                        
                        if distance <= Config.HerdingDistance then
                            table.insert(nearbyAnimals, {
                                id = animalData.animalid,
                                entity = animalEntity,
                                model = animalData.model,
                                position = animalPos,
                                distance = distance
                            })
                            
                            if Config.Debug then
                                print('^2[HERDING DEBUG]^7 Added animal ' .. animalData.animalid .. ' to nearby list')
                            end
                        else
                            if Config.Debug then
                                print('^1[HERDING DEBUG]^7 Animal ' .. animalData.animalid .. ' entity too far: ' .. tostring(math.floor(distance * 10) / 10) .. 'm')
                            end
                        end
                    else
                        if Config.Debug then
                            print('^1[HERDING DEBUG]^7 Animal ' .. animalData.animalid .. ' has no spawned entity or entity does not exist')
                        end
                    end
                else
                    if Config.Debug then
                        print('^1[HERDING DEBUG]^7 Animal ' .. animalData.animalid .. ' DB position too far: ' .. tostring(math.floor(distance * 10) / 10) .. 'm (max: ' .. Config.HerdingDistance .. 'm)')
                    end
                end
            else
                if Config.Debug then
                    print('^1[HERDING DEBUG]^7 Animal ' .. i .. ' has invalid data: pos_x=' .. tostring(animalData and animalData.pos_x) .. ', pos_y=' .. tostring(animalData and animalData.pos_y) .. ', pos_z=' .. tostring(animalData and animalData.pos_z) .. ', animalid=' .. tostring(animalData and animalData.animalid))
                end
            end
        end
    else
        -- Method 2: Fallback to entity scanning
        if Config.Debug then
            print('^3[HERDING DEBUG]^7 Using fallback entity scanning method')
        end
        local nearbyEntities = GetGamePool('CPed')
        
        for _, entity in ipairs(nearbyEntities) do
            if DoesEntityExist(entity) and entity ~= cache.ped then
                local entityModel = GetEntityModel(entity)
                local modelName = nil
                
                -- Check if this is a ranch animal by model
                if Config.AnimalProducts then
                    for model, _ in pairs(Config.AnimalProducts) do
                        if GetHashKey(model) == entityModel then
                            modelName = model
                            break
                        end
                    end
                end
                
                -- Also check for models that might not be in products config
                if not modelName then
                    local commonModels = {
                        [GetHashKey('a_c_cow')] = 'a_c_cow',
                        [GetHashKey('a_c_sheep_01')] = 'a_c_sheep_01',
                        [GetHashKey('a_c_pig_01')] = 'a_c_pig_01',
                        [GetHashKey('a_c_horse_americanpaint_greyovero')] = 'a_c_horse_americanpaint_greyovero'
                    }
                    modelName = commonModels[entityModel]
                end
                
                if modelName then
                    local animalPos = GetEntityCoords(entity)
                    local distance = #(playerPos - animalPos)
                    
                    if distance <= Config.HerdingDistance then
                        -- Use entity handle as ID for fallback method
                        table.insert(nearbyAnimals, {
                            id = entity,
                            entity = entity,
                            model = modelName,
                            position = animalPos,
                            distance = distance
                        })
                    end
                end
            end
        end
    end
    
    return nearbyAnimals
end

function GetAnimalDisplayName(model)
    local displayNames = {
        ['a_c_cow'] = 'Cow',
        ['a_c_sheep_01'] = 'Sheep',
        ['a_c_pig_01'] = 'Pig',
        ['a_c_horse_americanpaint_greyovero'] = 'Horse'
    }
    return displayNames[model] or 'Animal'
end

---------------------------------------------
-- blip management for herded animals
---------------------------------------------
function CreateAnimalBlip(animalId, entity, model)
    if not Config.ShowHerdingBlips or not DoesEntityExist(entity) then
        return nil
    end

    local entityPos = GetEntityCoords(entity)
    local blip = nil
    
    -- Create coordinate-based blip (more reliable in RedM)
    blip = BlipAddForCoords(Config.BLIP_HASH, entityPos.x, entityPos.y, entityPos.z)
    
    if blip and blip ~= 0 then
        -- Set blip sprite
        local blipSprite = joaat(Config.HerdingBlipSprite) or joaat('blip_ambient_herd')
        SetBlipSprite(blip, blipSprite, true)
        
        -- Set blip name
        local animalName = GetAnimalDisplayName(model)
        SetBlipName(blip, animalName .. ' (Herding)')
        
        -- Set blip scale
        local blipScale = Config.HerdingBlipScale or 0.2
        SetBlipScale(blip, blipScale)
        
        if Config.Debug then
            print('^2[HERDING DEBUG]^7 Created blip ' .. blip .. ' for animal ' .. animalId .. ' (' .. animalName .. ') at ' .. tostring(entityPos))
        end
        
        return blip
    end
    
    if Config.Debug then
        print('^1[HERDING DEBUG]^7 Failed to create blip for animal ' .. animalId .. ' at ' .. tostring(entityPos))
    end
    
    return nil
end

function RemoveAnimalBlip(animalId)
    if animalBlips[animalId] then
        local blip = animalBlips[animalId]
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
            if Config.Debug then
                print('^1[HERDING DEBUG]^7 Removed blip ' .. blip .. ' for animal ' .. animalId)
            end
        end
        animalBlips[animalId] = nil
    end
end

function RemoveAllAnimalBlips()
    for animalId, blip in pairs(animalBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
            if Config.Debug then
                print('^1[HERDING DEBUG]^7 Removed blip ' .. blip .. ' for animal ' .. animalId)
            end
        end
    end
    animalBlips = {}
end

function StartHerding(animals, herdType)
    herdingActive = true
    herdingStartTime = GetGameTimer()
    herdedAnimals = {}
    
    -- Convert animals to herded format and create blips
    local animalIds = {}
    for _, animalData in pairs(animals) do
        herdedAnimals[animalData.id] = {
            entity = animalData.entity,
            model = animalData.model,
            originalPos = animalData.position
        }
        table.insert(animalIds, animalData.id)
        
        -- Create blip for this animal
        if Config.ShowHerdingBlips then
            local blip = CreateAnimalBlip(animalData.id, animalData.entity, animalData.model)
            if blip then
                animalBlips[animalData.id] = blip
            end
        end
    end
    
    -- Enable transport mode to prevent despawning
    if Config.TransportMode then
        TriggerEvent('rex-ranch:client:setAnimalTransporting', animalIds, true)
        if Config.Debug then
            print('^2[HERDING DEBUG]^7 Enabled transport mode for ' .. #animalIds .. ' animals')
        end
    end
    
    local animalCount = #animals
    local typeText
    if herdType == 'distance' then
        typeText = 'nearby'
    elseif herdType == 'selected' then
        typeText = 'selected'
    else
        typeText = 'selected type'
    end
    
    lib.notify({ 
        title = 'Herding Started', 
        description = 'Now herding ' .. animalCount .. ' ' .. typeText .. ' animals', 
        type = 'success',
        duration = 5000
    })
    
    -- Start herding control thread
    herdingThreadId = CreateThread(function()
        local threadActive = true
        while herdingActive and threadActive do
            Wait(100)
            
            -- Check if we should still be running (thread wasn't cancelled)
            if not herdingActive or not herdingThreadId then
                threadActive = false
                break
            end
            
            -- Check timeout
            if herdingStartTime and (GetGameTimer() - herdingStartTime) > (Config.HerdingTimeout * 1000) then
                TriggerEvent('rex-ranch:client:stopHerding')
                lib.notify({ title = 'Herding Timeout', description = 'Herding session ended automatically', type = 'info' })
                break
            end
            
            -- Update animal following
            UpdateHerdingMovement()
        end
        
        -- Thread cleanup
        if Config.Debug then
            print('^3[HERDING DEBUG]^7 Herding thread ended')
        end
    end)
    
    -- Show herding instructions
    lib.notify({
        title = 'Herding Active',
        description = 'Use /herd to stop herding. Animals will follow you.',
        type = 'info',
        duration = 8000
    })
end

function UpdateHerdingMovement()
    if not herdingActive or not cache.ped then return end
    
    local playerPos = GetEntityCoords(cache.ped)
    local playerSpeed = GetEntitySpeed(cache.ped)
    
    -- Only update if player is moving
    if playerSpeed > 0.1 then
        local animalIndex = 0
        for animalId, animalInfo in pairs(herdedAnimals) do
            if DoesEntityExist(animalInfo.entity) and not IsPedDeadOrDying(animalInfo.entity, true) then
                animalIndex = animalIndex + 1
                
                -- Calculate follow position (spread animals around player)
                local angle = (animalIndex * 60) * (math.pi / 180) -- Convert to radians
                local followDistance = Config.HerdingFollowDistance + (animalIndex * 0.5)
                local followPos = vector3(
                    playerPos.x + math.cos(angle) * followDistance,
                    playerPos.y + math.sin(angle) * followDistance,
                    playerPos.z
                )
                
                -- Set animal to follow to position
                ClearPedTasks(animalInfo.entity)
                TaskGoToCoordAnyMeans(animalInfo.entity, followPos.x, followPos.y, followPos.z, Config.HerdingSpeed, 0, false, 786603, 0xbf800000)
            else
                -- Remove dead or non-existent animals
                RemoveAnimalBlip(animalId)
                herdedAnimals[animalId] = nil
            end
        end
        
        -- Check if all animals are gone
        local remainingAnimals = 0
        for _ in pairs(herdedAnimals) do
            remainingAnimals = remainingAnimals + 1
        end
        
        if remainingAnimals == 0 then
            TriggerEvent('rex-ranch:client:stopHerding')
            lib.notify({ title = 'No Animals Left', description = 'All herded animals are gone', type = 'info' })
        end
    end
end

---------------------------------------------
-- cleanup on resource stop
---------------------------------------------
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if herdingActive then
        TriggerEvent('rex-ranch:client:stopHerding')
    end
    -- Clear any pending selections
    selectedAnimals = {}
    -- Remove all blips
    RemoveAllAnimalBlips()
end)

-- Additional selection management commands
RegisterCommand('herdselectstatus', function()
    if not Config.HerdingEnabled or not Config.IndividualSelectionEnabled then return end
    
    local selectedCount = 0
    for _ in pairs(selectedAnimals) do
        selectedCount = selectedCount + 1
    end
    
    if selectedCount == 0 then
        lib.notify({ title = 'No Selection', description = 'No animals currently selected for herding', type = 'info' })
    else
        lib.notify({ 
            title = 'Selection Status', 
            description = selectedCount .. ' animals selected for herding',
            type = 'info',
            duration = 3000
        })
    end
end, false)

RegisterCommand('herdclear', function()
    if not Config.HerdingEnabled or not Config.IndividualSelectionEnabled then return end
    
    local clearedCount = 0
    for _ in pairs(selectedAnimals) do
        clearedCount = clearedCount + 1
    end
    
    if clearedCount > 0 then
        selectedAnimals = {}
        lib.notify({ 
            title = 'Selection Cleared', 
            description = 'Cleared ' .. clearedCount .. ' selected animals',
            type = 'success'
        })
    else
        lib.notify({ title = 'No Selection', description = 'No animals were selected', type = 'info' })
    end
end, false)

-- Note: Use /herd command to access herding menu
-- RegisterKeyMapping is not available in RedM
