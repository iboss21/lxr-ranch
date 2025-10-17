local RSGCore = exports['rsg-core']:GetCoreObject()
local spawnedAnimals = {}
local animalDataCache = {}
local followStates = {}
local transportingAnimals = {} -- Track animals being transported to prevent despawning
local isBusy = false -- Global busy state for animal interactions
local spawningLocks = {} -- Track animals currently being spawned to prevent duplicates
lib.locale()

---------------------------------------------
-- on player load refresh animals
---------------------------------------------
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('rex-ranch:server:refreshAnimals')
end)

---------------------------------------------
-- check distance, spawn animal, and track position
---------------------------------------------
CreateThread(function()
    while true do
        -- Reduce check frequency when no animals are cached or player is inactive
        local waitTime = (#animalDataCache > 0 and IsPedInAnyVehicle(cache.ped, false)) and 2000 or 1000
        Wait(waitTime)
        
        if cache.ped and DoesEntityExist(cache.ped) then
            local playerCoords = GetEntityCoords(cache.ped)
            for k, loadData in pairs(animalDataCache) do
                -- Validate loadData before processing
                if loadData and loadData.pos_x and loadData.pos_y and loadData.pos_z then
                    local animalCoords = vector3(tonumber(loadData.pos_x), tonumber(loadData.pos_y), tonumber(loadData.pos_z))
                    local distance = #(playerCoords - animalCoords)
                    
                    -- Use consistent string key for animal ID
                    local animalKey = tostring(loadData.animalid or k)
                    
                    -- spawn animal if within range (with lock to prevent duplicates)
                    if distance < Config.AnimalDistanceSpawn and not spawnedAnimals[animalKey] and not spawningLocks[animalKey] then
                        spawningLocks[animalKey] = true
                        local spawnedAnimal = NearAnimal(loadData)
                        spawningLocks[animalKey] = nil
                        if spawnedAnimal then
                            spawnedAnimals[animalKey] = { 
                                spawnedAnimal = spawnedAnimal
                            }
                            
                            -- Debug spawning
                            if Config.Debug then
                                print('^2[ANIMAL DEBUG]^7 Spawned animal ' .. animalKey .. ' (entity: ' .. spawnedAnimal .. ') at distance ' .. math.floor(distance * 10) / 10 .. 'm')
                            end
                        end
                    end
                    
                    -- despawn animal if out of range (but not if being transported)
                    local isTransporting = transportingAnimals[animalKey] or followStates[animalKey]
                    if distance >= Config.AnimalDistanceSpawn and spawnedAnimals[animalKey] and not (Config.TransportMode and isTransporting) then
                        if DoesEntityExist(spawnedAnimals[animalKey].spawnedAnimal) then
                            if Config.AnimalFadeIn then
                                for i = 255, 0, -51 do
                                    Wait(50)
                                    if DoesEntityExist(spawnedAnimals[animalKey].spawnedAnimal) then
                                        SetEntityAlpha(spawnedAnimals[animalKey].spawnedAnimal, i, false)
                                    end
                                end
                            end
                            DeletePed(spawnedAnimals[animalKey].spawnedAnimal)
                            
                            if Config.Debug then
                                print('^1[ANIMAL DEBUG]^7 Despawned animal ' .. animalKey .. ' (too far: ' .. math.floor(distance * 10) / 10 .. 'm)')
                            end
                        end
                        spawnedAnimals[animalKey] = nil
                    end
                end -- close loadData validation
            end -- close for loop
        end -- close cache.ped check
    end -- close while loop
end)

---------------------------------------------
-- animal spawner
---------------------------------------------
function NearAnimal(loadData)
    -- Validate input data
    if not loadData or not loadData.model or not loadData.pos_x or not loadData.pos_y or not loadData.pos_z then
        print("^1[ERROR]^7 Invalid animal data provided to NearAnimal function")
        return nil
    end
    
    local model = GetHashKey(loadData.model)
    lib.requestModel(model, 5000)
    if not HasModelLoaded(model) then
        print("^1[ERROR]^7 Failed to load model: " .. tostring(loadData.model))
        return nil
    end
    
    local spawnedAnimal = CreatePed(model, tonumber(loadData.pos_x), tonumber(loadData.pos_y), tonumber(loadData.pos_z) - 1.0, tonumber(loadData.pos_w or 0), false, false, 0, 0)
    if not DoesEntityExist(spawnedAnimal) then
        print("^1[ERROR]^7 Failed to create animal entity")
        return nil
    end
    
    NetworkRegisterEntityAsNetworked(spawnedAnimal)
    SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(spawnedAnimal), true)
    
    -- Ensure scale is valid (between 0.1 and 2.0), handle NaN and invalid values
    local scale = tonumber(loadData.scale)
    if not scale or scale ~= scale or scale <= 0 then -- Check for nil, NaN, or invalid values
        scale = 1.0
    else
        scale = math.min(math.max(scale, 0.1), 2.0)
    end
    SetPedScale(spawnedAnimal, scale)
    SetEntityAsMissionEntity(spawnedAnimal, true, true)
    SetEntityInvincible(spawnedAnimal, false)
    FreezeEntityPosition(spawnedAnimal, false)
    SetPedOutfitPreset(spawnedAnimal, 0)
    SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(spawnedAnimal), joaat('PLAYER'))
    if Config.AnimalFadeIn then
        for i = 0, 255, 51 do
            Wait(50)
            SetEntityAlpha(spawnedAnimal, i, false)
        end
    end
    exports.ox_target:addLocalEntity(spawnedAnimal, {
        {
            name = 'ranch_animal',
            icon = 'far fa-eye',
            label = 'Animal Actions',
            onSelect = function()
                TriggerEvent('rex-ranch:client:animalmenu', spawnedAnimal, loadData)
            end,
            distance = 2.0
        }
    })
    return spawnedAnimal
end

---------------------------------------------
-- move animal data to cache
---------------------------------------------
RegisterNetEvent('rex-ranch:client:spawnAnimals', function(animalData)
    -- Update the cache
    animalDataCache = animalData
    
    -- Convert array to keyed table for easier lookup
    local keyedData = {}
    for _, animal in ipairs(animalData) do
        keyedData[animal.animalid] = animal
    end
    
    -- Check for animals that no longer exist in the database and remove them
    local animalsToRemove = {}
    for animalKey, _ in pairs(spawnedAnimals) do
        local found = false
        for _, animal in ipairs(animalData) do
            if tostring(animal.animalid) == tostring(animalKey) then
                found = true
                break
            end
        end
        if not found then
            table.insert(animalsToRemove, animalKey)
        end
    end
    
    -- Remove animals that are no longer in the database
    for _, animalKey in ipairs(animalsToRemove) do
        if spawnedAnimals[animalKey] and DoesEntityExist(spawnedAnimals[animalKey].spawnedAnimal) then
            exports.ox_target:removeLocalEntity(spawnedAnimals[animalKey].spawnedAnimal, 'ranch_animal')
            DeletePed(spawnedAnimals[animalKey].spawnedAnimal)
            if Config.Debug then
                print('^1[ANIMAL DEBUG]^7 Removed stale animal entity: ' .. animalKey)
            end
        end
        spawnedAnimals[animalKey] = nil
        followStates[animalKey] = nil
        transportingAnimals[animalKey] = nil
        spawningLocks[animalKey] = nil -- Clear spawning locks too
    end
    
    -- Update individual animal data in the cache for existing animals
    for i, cachedAnimal in ipairs(animalDataCache) do
        if keyedData[cachedAnimal.animalid] then
            animalDataCache[i] = keyedData[cachedAnimal.animalid]
        end
    end
end)

---------------------------------------------
-- get fresh animal data from cache
---------------------------------------------
local function getFreshAnimalData(animalid)
    for _, cachedAnimal in ipairs(animalDataCache) do
        if cachedAnimal.animalid == animalid then
            return cachedAnimal
        end
    end
    return nil
end

---------------------------------------------
-- animal menu
---------------------------------------------
RegisterNetEvent('rex-ranch:client:animalmenu', function(animal, data)
    -- Validate inputs
    if not DoesEntityExist(animal) or not data or not data.animalid then
        lib.notify({ title = 'Error', description = 'Invalid animal data!', type = 'error' })
        return
    end
    
    -- Get fresh data from cache in case it was updated
    local freshData = getFreshAnimalData(data.animalid) or data
    
    -- Ensure required fields exist
    freshData.health = freshData.health or 100
    freshData.thirst = freshData.thirst or 100
    freshData.hunger = freshData.hunger or 100
    freshData.age = freshData.age or 0
    freshData.animalid = freshData.animalid or data.animalid
    
    -- Use database age field (calculated server-side)
    local actualAge = freshData.age or 0
    
    -- Get gender info
    local genderText = freshData.gender and freshData.gender:gsub("^%l", string.upper) or 'Unknown'
    local pregnantStatus = freshData.pregnant == 1 and 'Pregnant' or 'Not Pregnant'
    
    -- animal age
    local ageText = 'Youth'
    if actualAge < 5 then ageText = 'Youth' end
    if actualAge >= 5 then ageText = 'Adult' end
    -- health colorScheme
    local healthColorScheme = 'green'
    if freshData.health > 80 then healthColorScheme = 'green' end
    if freshData.health <= 80 and freshData.health > 10 then healthColorScheme = 'yellow' end
    if freshData.health <= 10 then healthColorScheme = 'red' end
    freshData.health = math.min(math.max(freshData.health or 100, 0), 100)

    -- thirst colorScheme
    local thirstColorScheme = 'green'
    if freshData.thirst > 80 then thirstColorScheme = 'green' end
    if freshData.thirst <= 80 and freshData.thirst > 10 then thirstColorScheme = 'yellow' end
    if freshData.thirst <= 10 then thirstColorScheme = 'red' end
    freshData.thirst = math.min(math.max(freshData.thirst or 100, 0), 100)

    -- hunger colorScheme
    local hungerColorScheme = 'green'
    if freshData.hunger > 80 then hungerColorScheme = 'green' end
    if freshData.hunger <= 80 and freshData.hunger > 10 then hungerColorScheme = 'yellow' end
    if freshData.hunger <= 10 then hungerColorScheme = 'red' end
    freshData.hunger = math.min(math.max(freshData.hunger or 100, 0), 100)

    lib.registerContext({
        id = 'animal_info_menu',
        title = 'Ranch Animal #'..freshData.animalid,
        options = {
            {
                title = 'Animal Information',
                description = 'Basic animal details',
                icon = 'fa-solid fa-info-circle',
                disabled = false
            },
            {
                title = 'Age: '..ageText,
                description = actualAge..' days old',
                icon = 'fa-solid fa-calendar-days',
                disabled = false
            },
            {
                title = 'Gender: '..genderText:gsub("^%l", string.upper),
                description = freshData.gender == 'female' and pregnantStatus or 'Male animal',
                icon = freshData.gender == 'male' and 'fa-solid fa-mars' or 'fa-solid fa-venus',
                disabled = false
            },
            {
                title = 'Health: '..math.floor(freshData.health)..'%',
                description = 'Overall animal health',
                progress = freshData.health,
                colorScheme = healthColorScheme,
                icon = 'fa-solid fa-heart-pulse',
                disabled = false
            },
            {
                title = 'Thirst: '..math.floor(freshData.thirst)..'%',
                description = 'Animal water needs',
                progress = freshData.thirst,
                colorScheme = thirstColorScheme,
                icon = 'fa-solid fa-droplet',
                disabled = false
            },
            {
                title = 'Hunger: '..math.floor(freshData.hunger)..'%',
                description = 'Animal food needs',
                progress = freshData.hunger,
                colorScheme = hungerColorScheme,
                icon = 'fa-solid fa-wheat-awn',
                disabled = false
            },
            {
                title = '─────────────────────────',
                disabled = true
            },
            {
                title = 'Animal Actions',
                description = 'Care for your animal',
                icon = 'fa-solid fa-hand-holding-heart',
                event = 'rex-ranch:client:actionsmenu',
                args = { animalid = freshData.animalid, animal = animal },
                arrow = true
            },
        }
    })
    lib.showContext('animal_info_menu')
end)

---------------------------------------------
-- animal action menu
---------------------------------------------
RegisterNetEvent('rex-ranch:client:actionsmenu', function(data)
    local animalid = data.animalid
    local animal = data.animal
    
    -- Get fresh data from cache in case it was updated
    local freshData = getFreshAnimalData(animalid)
    if not freshData then
        lib.notify({ title = 'Error', description = 'Animal data not found!', type = 'error' })
        return
    end
    
    -- Get current stats for descriptions
    local hungerStatus = freshData.hunger > 80 and 'Well Fed' or freshData.hunger > 50 and 'Hungry' or 'Starving'
    local thirstStatus = freshData.thirst > 80 and 'Hydrated' or freshData.thirst > 50 and 'Thirsty' or 'Dehydrated'
    local followStatus = followStates[animalid] and 'Following' or 'Idle'
    
    -- Use database age field (calculated server-side)
    local actualAge = freshData.age or 0
    
    -- Get breeding status
    local breedingStatus = 'Unknown'
    
    if Config.BreedingEnabled and Config.MinAgeForBreeding and Config.MaxBreedingAge and actualAge >= Config.MinAgeForBreeding and actualAge <= Config.MaxBreedingAge then
        if freshData.gender == 'female' and freshData.pregnant == 1 then
            breedingStatus = 'Pregnant'
        elseif freshData.breeding_ready_time and freshData.breeding_ready_time > 0 then
            -- Note: Server handles cooldown timing, just show that there is a cooldown
            breedingStatus = 'Cooldown Active'
        else
            breedingStatus = 'Ready to Breed'
        end
    elseif Config.MinAgeForBreeding and actualAge < Config.MinAgeForBreeding then
        breedingStatus = 'Too Young'
    elseif Config.MaxBreedingAge and actualAge > Config.MaxBreedingAge then
        breedingStatus = 'Too Old'
    else
        breedingStatus = 'Breeding Disabled'
    end
    
    lib.registerContext({
        id = 'animal_action_menu',
        title = 'Animal Actions',
        menu = 'animal_info_menu',
        options = {
            {
                title = 'Toggle Follow ('..followStatus..')',
                description = 'Make the animal follow you or stay put',
                icon = followStates[animalid] and 'fa-solid fa-user-check' or 'fa-solid fa-walking',
                event = 'rex-ranch:client:animalfollow',
                args = { animal = animal, animalid = animalid }
            },
            {
                title = '─────────────────────────',
                disabled = true
            },
            {
                title = 'Feed Animal ('..hungerStatus..')',
                description = 'Requires: '..Config.FeedItem,
                icon = 'fa-solid fa-wheat-awn',
                event = 'rex-ranch:client:feedAnimal',
                args = { animalid = animalid, animal = animal }
            },
            {
                title = 'Water Animal ('..thirstStatus..')',
                description = 'Requires: '..Config.WaterItem,
                icon = 'fa-solid fa-droplet',
                event = 'rex-ranch:client:waterAnimal',
                args = { animalid = animalid, animal = animal }
            },
            {
                title = '─────────────────────────',
                disabled = true
            },
            {
                title = 'Check Products',
                description = 'See what products this animal can produce',
                icon = 'fa-solid fa-gift',
                event = 'rex-ranch:client:checkProducts',
                args = { animalid = animalid, animal = animal }
            },
            {
                title = '─────────────────────────',
                disabled = true
            },
            {
                title = 'Breeding ('..breedingStatus..')',
                description = 'Manage animal breeding',
                icon = 'fa-solid fa-heart',
                event = 'rex-ranch:client:breedingMenu',
                args = { animalid = animalid, animal = animal, freshData = freshData },
                arrow = true
            },
        }
    })
    lib.showContext('animal_action_menu')
end)

---------------------------------------------
-- set animal to follow you
---------------------------------------------
RegisterNetEvent('rex-ranch:client:animalfollow', function(data)
    -- validate entities
    if not DoesEntityExist(data.animal) or not DoesEntityExist(cache.ped) then
        lib.notify({ title = 'Error', description = 'Invalid animal or player!', type = 'error' })
        return
    end
    -- check if animal is dead
    if IsPedDeadOrDying(data.animal, true) then
        lib.notify({ title = 'Animal Dead', description = 'This animal is dead!', type = 'error' })
        return 
    end
    -- toggle follow state for this animal
    if followStates[data.animalid] == nil then
        followStates[data.animalid] = false
    end
    followStates[data.animalid] = not followStates[data.animalid]
    if followStates[data.animalid] then
        local playerCoords = GetEntityCoords(cache.ped)
        local animalOffset = vector3(0.0, 2.0, 0.0)
        ClearPedTasks(data.animal)
        TaskFollowToOffsetOfEntity(data.animal, cache.ped, animalOffset.x, animalOffset.y, animalOffset.z, 1.0, -1, 0.0, 1)
        lib.notify({ title = 'Animal Following!', description = 'The animal is now following you.', duration = 5000, type = 'info' })
    else
        local currentPos = GetEntityCoords(data.animal)
        local heading = GetEntityHeading(data.animal)
        ClearPedTasks(data.animal) -- stop following, let animal idle
        TriggerServerEvent('rex-ranch:server:saveAnimalPosition', data.animalid, currentPos.x, currentPos.y, currentPos.z, heading)
        lib.notify({ title = 'Animal Stopped', description = 'The animal stopped following you.', duration = 5000, type = 'info' })
    end
end)

---------------------------------------------
-- feed animal with animation
---------------------------------------------
RegisterNetEvent('rex-ranch:client:feedAnimal', function(data)
    local playerPed = cache.ped
    local animal = data.animal
    local animalid = data.animalid
    
    -- Validate entities
    if not DoesEntityExist(playerPed) or not DoesEntityExist(animal) then
        lib.notify({ title = 'Error', description = 'Invalid player or animal!', type = 'error' })
        return
    end
    
    local hasItem = RSGCore.Functions.HasItem('animal_feed', 1)
    if hasItem and not isBusy then
        isBusy = true
        LocalPlayer.state:set('inv_busy', true, true)
        TaskTurnPedToFaceEntity(cache.ped, animal, 2000)
        Wait(1500)
        FreezeEntityPosition(cache.ped, true)
        TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_FEED_PIGS`, 0, true)
        Wait(10000)
        ClearPedTasks(cache.ped)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        FreezeEntityPosition(cache.ped, false)
        TriggerServerEvent('rex-ranch:server:feedAnimal', animalid)
        LocalPlayer.state:set('inv_busy', false, true)
        isBusy = false
    else
        lib.notify({type = 'error', description = 'You need animal feed to feed the animals!'})
    end

end)

---------------------------------------------
-- water animal with animation
---------------------------------------------
RegisterNetEvent('rex-ranch:client:waterAnimal', function(data)
    local animal = data.animal
    local animalid = data.animalid
    
    -- Validate entities
    if not DoesEntityExist(cache.ped) or not DoesEntityExist(animal) then
        lib.notify({ title = 'Error', description = 'Invalid player or animal!', type = 'error' })
        return
    end    

    local hasItem = RSGCore.Functions.HasItem('water_bucket', 1)
    if hasItem and not isBusy then
        isBusy = true
        LocalPlayer.state:set('inv_busy', true, true)
        TaskTurnPedToFaceEntity(cache.ped, animal, 2000)
        Wait(1500)
        FreezeEntityPosition(cache.ped, true)
        TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_BUCKET_POUR_LOW`, 0, true)
        Wait(10000)
        ClearPedTasks(cache.ped)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        FreezeEntityPosition(cache.ped, false)
        TriggerServerEvent('rex-ranch:server:waterAnimal', animalid)
        LocalPlayer.state:set('inv_busy', false, true)
        isBusy = false
    else
        lib.notify({type = 'error', description = 'You need water bucket to water the animals!'})
    end

end)

---------------------------------------------
-- check animal products
---------------------------------------------
RegisterNetEvent('rex-ranch:client:checkProducts', function(data)
    local animalid = data.animalid
    local animal = data.animal
    
    -- Validate entities
    if not DoesEntityExist(animal) or not animalid then
        lib.notify({ title = 'Error', description = 'Invalid animal!', type = 'error' })
        return
    end
    
    RSGCore.Functions.TriggerCallback('rex-ranch:server:getAnimalProductionStatus', function(productionData)
        if not productionData then
            lib.notify({ title = 'No Production', description = 'This animal doesn\'t produce anything!', type = 'info' })
            return
        end
        
        local timeText = ''
        if productionData.hasProduct then
            timeText = 'Ready to collect!'
        elseif productionData.canProduce then
            local hours = math.floor(productionData.timeUntilNext / 3600)
            local minutes = math.floor((productionData.timeUntilNext % 3600) / 60)
            timeText = 'Next production in: ' .. hours .. 'h ' .. minutes .. 'm'
        else
            timeText = 'Animal needs better care to produce'
        end
        
        local options = {
            {
                title = 'Product Information',
                description = 'Animal production details',
                icon = 'fa-solid fa-info-circle',
                disabled = false
            },
            {
                title = 'Product: ' .. productionData.productName,
                description = 'This animal produces ' .. productionData.productAmount .. ' ' .. productionData.productName,
                icon = 'fa-solid fa-box',
                disabled = false
            },
            {
                title = 'Status: ' .. timeText,
                description = productionData.canProduce and 'Animal meets production requirements' or 'Improve animal health, hunger, and thirst',
                icon = productionData.hasProduct and 'fa-solid fa-check-circle' or 'fa-solid fa-clock',
                disabled = false
            }
        }
        
        if productionData.hasProduct then
            table.insert(options, {
                title = '─────────────────────────',
                disabled = true
            })
            table.insert(options, {
                title = 'Collect ' .. productionData.productName,
                description = 'Collect ' .. productionData.productAmount .. ' ' .. productionData.productName .. ' from this animal',
                icon = 'fa-solid fa-hand-holding',
                event = 'rex-ranch:client:collectProduct',
                args = { animalid = animalid, animal = animal }
            })
        end
        
        lib.registerContext({
            id = 'animal_production_menu',
            title = 'Animal Production',
            menu = 'animal_action_menu',
            options = options
        })
        lib.showContext('animal_production_menu')
    end, animalid)
end)

---------------------------------------------
-- collect animal product with animation
---------------------------------------------
RegisterNetEvent('rex-ranch:client:collectProduct', function(data)
    local animal = data.animal
    local animalid = data.animalid
    
    -- Validate entities
    if not DoesEntityExist(cache.ped) or not DoesEntityExist(animal) then
        lib.notify({ title = 'Error', description = 'Invalid player or animal!', type = 'error' })
        return
    end
    
    if not isBusy then
        isBusy = true
        LocalPlayer.state:set('inv_busy', true, true)
        TaskTurnPedToFaceEntity(cache.ped, animal, 2000)
        Wait(1500)
        FreezeEntityPosition(cache.ped, true)
        TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_CROUCH_INSPECT`, 0, true)
        Wait(5000)
        ClearPedTasks(cache.ped)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        FreezeEntityPosition(cache.ped, false)
        TriggerServerEvent('rex-ranch:server:collectProduct', animalid)
        LocalPlayer.state:set('inv_busy', false, true)
        isBusy = false
    end
end)

---------------------------------------------
-- refresh single animal data after feeding/watering
---------------------------------------------
RegisterNetEvent('rex-ranch:client:refreshSingleAnimal', function(animalid, updatedData)
    for i, cachedAnimal in ipairs(animalDataCache) do
        if cachedAnimal.animalid == animalid then
            -- Update the specific fields that were changed
            for key, value in pairs(updatedData) do
                animalDataCache[i][key] = value
            end
            break
        end
    end
end)

---------------------------------------------
-- remove animal when sold
---------------------------------------------
RegisterNetEvent('rex-ranch:client:removeAnimal', function(animalid)
    local animalKey = tostring(animalid)
    
    -- Use consistent string key lookup
    local entityToRemove = nil
    if spawnedAnimals[animalKey] and DoesEntityExist(spawnedAnimals[animalKey].spawnedAnimal) then
        entityToRemove = spawnedAnimals[animalKey].spawnedAnimal
        spawnedAnimals[animalKey] = nil
    end
    
    if entityToRemove then
        -- Remove target interaction
        exports.ox_target:removeLocalEntity(entityToRemove, 'ranch_animal')
        
        -- Fade out and delete
        if Config.AnimalFadeIn then
            CreateThread(function()
                for i = 255, 0, -51 do
                    Wait(50)
                    if DoesEntityExist(entityToRemove) then
                        SetEntityAlpha(entityToRemove, i, false)
                    end
                end
                if DoesEntityExist(entityToRemove) then
                    DeletePed(entityToRemove)
                end
            end)
        else
            DeletePed(entityToRemove)
        end
        
        if Config.Debug then
            print('^2[ANIMAL DEBUG]^7 Removed sold animal entity: ' .. animalid .. ' (entity: ' .. entityToRemove .. ')')
        end
    else
        if Config.Debug then
            print('^1[ANIMAL DEBUG]^7 Could not find entity to remove for animal: ' .. animalid)
        end
    end
    
    -- Also remove from follow states and transport states
    followStates[animalKey] = nil
    transportingAnimals[animalKey] = nil
    
    -- Remove from cache
    for i, cachedAnimal in ipairs(animalDataCache) do
        if tostring(cachedAnimal.animalid) == animalKey then
            table.remove(animalDataCache, i)
            break
        end
    end
end)

---------------------------------------------
-- transport mode events (called from herding system)
---------------------------------------------
RegisterNetEvent('rex-ranch:client:setAnimalTransporting', function(animalIds, transporting)
    if type(animalIds) == 'table' then
        for _, animalId in ipairs(animalIds) do
            local key = tostring(animalId)
            transportingAnimals[key] = transporting or nil
        end
    else
        local key = tostring(animalIds)
        transportingAnimals[key] = transporting or nil
    end
    
    if Config.Debug then
        local count = 0
        for _ in pairs(transportingAnimals) do count = count + 1 end
        print('^2[DEBUG]^7 Transport mode animals: ' .. count)
    end
end)

---------------------------------------------
-- get animal entity by ID (for herding system)
---------------------------------------------
function GetAnimalEntityById(animalId)
    -- Convert to string to match key format
    local key = tostring(animalId)
    
    if Config.Debug then
        print('^3[ANIMAL DEBUG]^7 Looking for animal entity with ID: ' .. key)
        local count = 0
        for k, v in pairs(spawnedAnimals) do
            count = count + 1
            print('^3[ANIMAL DEBUG]^7 Spawned animal key: ' .. tostring(k) .. ', entity: ' .. tostring(v.spawnedAnimal) .. ', exists: ' .. tostring(DoesEntityExist(v.spawnedAnimal)))
        end
        print('^3[ANIMAL DEBUG]^7 Total spawned animals: ' .. count)
    end
    
    if spawnedAnimals[key] and DoesEntityExist(spawnedAnimals[key].spawnedAnimal) then
        if Config.Debug then
            print('^2[ANIMAL DEBUG]^7 Found entity for animal ' .. key .. ': ' .. spawnedAnimals[key].spawnedAnimal)
        end
        return spawnedAnimals[key].spawnedAnimal
    end
    
    -- No fallback needed - all keys should be consistent strings now
    
    if Config.Debug then
        print('^1[ANIMAL DEBUG]^7 No entity found for animal ID: ' .. key)
    end
    return nil
end

-- Export functions for other modules
exports('GetAnimalEntityById', GetAnimalEntityById)
exports('GetAnimalDataCache', function() return animalDataCache end)

---------------------------------------------
-- breeding menu
---------------------------------------------
RegisterNetEvent('rex-ranch:client:breedingMenu', function(data)
    local animalid = data.animalid
    local animal = data.animal
    local freshData = data.freshData
    
    if not Config.BreedingEnabled then
        lib.notify({ title = 'Breeding Disabled', description = 'Animal breeding is currently disabled!', type = 'error' })
        return
    end
    
    -- Get fresh data from cache in case it was updated
    freshData = getFreshAnimalData(animalid) or freshData
    
    -- Use database age field (calculated server-side)
    local actualAge = freshData.age or 0
    local genderText = freshData.gender and freshData.gender:gsub("^%l", string.upper) or 'Unknown'
    
    -- Check breeding requirements
    local canBreed = true
    local breedingIssues = {}
    
    if Config.MinAgeForBreeding and actualAge < Config.MinAgeForBreeding then
        canBreed = false
        table.insert(breedingIssues, 'Too young (need ' .. Config.MinAgeForBreeding .. ' days)')
    elseif Config.MaxBreedingAge and actualAge > Config.MaxBreedingAge then
        canBreed = false
        table.insert(breedingIssues, 'Too old (max ' .. Config.MaxBreedingAge .. ' days)')
    end
    
    if Config.RequireHealthForBreeding and (freshData.health or 100) < Config.RequireHealthForBreeding then
        canBreed = false
        table.insert(breedingIssues, 'Health too low (need ' .. Config.RequireHealthForBreeding .. '%)')
    end
    
    if Config.RequireHungerForBreeding and (freshData.hunger or 100) < Config.RequireHungerForBreeding then
        canBreed = false
        table.insert(breedingIssues, 'Hunger too low (need ' .. Config.RequireHungerForBreeding .. '%)')
    end
    
    if Config.RequireThirstForBreeding and (freshData.thirst or 100) < Config.RequireThirstForBreeding then
        canBreed = false
        table.insert(breedingIssues, 'Thirst too low (need ' .. Config.RequireThirstForBreeding .. '%)')
    end
    
    if freshData.breeding_ready_time and freshData.breeding_ready_time > 0 then
        canBreed = false
        table.insert(breedingIssues, 'Breeding cooldown active')
    end
    
    if freshData.gender == 'female' and freshData.pregnant == 1 then
        canBreed = false
        table.insert(breedingIssues, 'Already pregnant')
    end
    
    local statusText = canBreed and 'Ready to breed' or table.concat(breedingIssues, ', ')
    local gestationText = ''
    
    if freshData.gender == 'female' and freshData.pregnant == 1 then
        if freshData.gestation_end_time and freshData.gestation_end_time > 0 then
            gestationText = 'Pregnancy in progress'
        else
            gestationText = 'Ready to give birth!'
        end
    end
    
    local options = {
        {
            title = 'Breeding Information',
            description = 'Animal breeding details',
            icon = 'fa-solid fa-info-circle',
            disabled = false
        },
        {
            title = 'Gender: ' .. genderText,
            description = 'Age: ' .. actualAge .. ' days',
            icon = freshData.gender == 'male' and 'fa-solid fa-mars' or 'fa-solid fa-venus',
            disabled = false
        },
        {
            title = 'Status: ' .. statusText,
            description = canBreed and 'This animal can breed' or 'Requirements not met',
            icon = canBreed and 'fa-solid fa-check-circle' or 'fa-solid fa-exclamation-triangle',
            disabled = false
        }
    }
    
    if freshData.gender == 'female' and freshData.pregnant == 1 then
        table.insert(options, {
            title = 'Pregnancy: ' .. gestationText,
            description = 'This animal is expecting offspring',
            icon = 'fa-solid fa-baby',
            disabled = false
        })
    end
    
    if canBreed and freshData.gender then
        table.insert(options, {
            title = '─────────────────────────',
            disabled = true
        })
        table.insert(options, {
            title = 'Find Breeding Partner',
            description = 'Look for compatible animals to breed with',
            icon = 'fa-solid fa-search',
            event = 'rex-ranch:client:findBreedingPartner',
            args = { animalid = animalid, animal = animal, freshData = freshData }
        })
    end
    
    lib.registerContext({
        id = 'animal_breeding_menu',
        title = 'Animal Breeding',
        menu = 'animal_action_menu',
        options = options
    })
    lib.showContext('animal_breeding_menu')
end)

---------------------------------------------
-- find breeding partner
---------------------------------------------
RegisterNetEvent('rex-ranch:client:findBreedingPartner', function(data)
    local animalid = data.animalid
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local ranchid = PlayerData.job.name
    
    RSGCore.Functions.TriggerCallback('rex-ranch:server:getAvailableAnimalsForBreeding', function(availableAnimals)
        if not availableAnimals or #availableAnimals == 0 then
            lib.notify({ 
                title = 'No Partners Available', 
                description = 'No compatible breeding partners found!', 
                type = 'info' 
            })
            return
        end
        
        local options = {
            {
                title = 'Available Breeding Partners',
                description = #availableAnimals .. ' animals found',
                icon = 'fa-solid fa-list',
                disabled = false
            },
            {
                title = '─────────────────────────',
                disabled = true
            }
        }
        
        for _, partner in ipairs(availableAnimals) do
            local genderIcon = partner.gender == 'male' and 'fa-solid fa-mars' or 'fa-solid fa-venus'
            local statusIcon = partner.canBreed and 'fa-solid fa-check' or 'fa-solid fa-times'
            local statusColor = partner.canBreed and 'green' or 'red'
            
            local healthStatus = partner.health > 80 and 'Excellent' or partner.health > 50 and 'Good' or 'Poor'
            local description = 'Age: ' .. partner.age .. ' days, Health: ' .. healthStatus .. ' (' .. math.floor(partner.health) .. '%)\n'
            description = description .. 'Distance: ' .. partner.distance .. 'm'
            
            if not partner.canBreed then
                description = description .. '\nIssue: ' .. partner.breedingIssue
            end
            
            table.insert(options, {
                title = partner.gender:gsub("^%l", string.upper) .. ' #' .. partner.animalid,
                description = description,
                icon = genderIcon,
                metadata = {
                    { label = 'Status', value = partner.canBreed and 'Ready' or 'Not Ready' },
                    { label = 'Health', value = math.floor(partner.health) .. '%' },
                    { label = 'Distance', value = partner.distance .. 'm' }
                },
                disabled = not partner.canBreed,
                event = partner.canBreed and 'rex-ranch:client:confirmBreeding' or nil,
                args = partner.canBreed and { 
                    animal1id = animalid, 
                    animal2id = partner.animalid,
                    partner = partner
                } or nil
            })
        end
        
        lib.registerContext({
            id = 'breeding_partner_menu',
            title = 'Select Breeding Partner',
            menu = 'animal_breeding_menu',
            options = options
        })
        lib.showContext('breeding_partner_menu')
        
    end, ranchid, animalid)
end)

---------------------------------------------
-- confirm breeding
---------------------------------------------
RegisterNetEvent('rex-ranch:client:confirmBreeding', function(data)
    local animal1id = data.animal1id
    local animal2id = data.animal2id
    local partner = data.partner
    
    local alert = lib.alertDialog({
        header = 'Confirm Breeding',
        content = 'Are you sure you want to breed these animals?\n\n' ..
                 'Animal #' .. animal1id .. ' with Animal #' .. animal2id .. '\n\n' ..
                 'Both animals will have a breeding cooldown afterward.',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        TriggerServerEvent('rex-ranch:server:startBreeding', animal1id, animal2id)
    end
end)

---------------------------------
-- cleanup
---------------------------------
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for k,v in pairs(spawnedAnimals) do
        if DoesEntityExist(spawnedAnimals[k].spawnedAnimal) then
            DeletePed(spawnedAnimals[k].spawnedAnimal)
        end
        spawnedAnimals[k] = nil
    end
    -- Clear transport states
    transportingAnimals = {}
    followStates = {}
end)
