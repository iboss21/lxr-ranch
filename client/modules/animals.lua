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
-- force refresh animals from server
---------------------------------------------
RegisterNetEvent('rex-ranch:client:refreshAnimals', function()
    if Config.Debug then
        print('^3[ANIMAL DEBUG]^7 Force refresh triggered - clearing all spawned animals')
    end
    
    -- Clear all currently spawned animals
    for animalKey, animalData in pairs(spawnedAnimals) do
        if animalData and animalData.spawnedAnimal and DoesEntityExist(animalData.spawnedAnimal) then
            exports.ox_target:removeLocalEntity(animalData.spawnedAnimal, 'ranch_animal')
            DeletePed(animalData.spawnedAnimal)
            if Config.Debug then
                print('^1[ANIMAL DEBUG]^7 Force removed animal entity: ' .. animalKey)
            end
        end
    end
    
    -- Clear all tracking data
    spawnedAnimals = {}
    followStates = {}
    spawningLocks = {}
    
    -- Request fresh animal data from server
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
                -- Comprehensive validation of loadData before processing
                if loadData and loadData.pos_x and loadData.pos_y and loadData.pos_z and 
                   loadData.animalid and loadData.model and
                   type(loadData.pos_x) == 'number' and type(loadData.pos_y) == 'number' and type(loadData.pos_z) == 'number' then
                    
                    local animalCoords = vector3(loadData.pos_x, loadData.pos_y, loadData.pos_z)
                    local distance = #(playerCoords - animalCoords)
                    
                    -- Use consistent string key for animal ID
                    local animalKey = tostring(loadData.animalid or k)
                    
                    -- spawn animal if within range (with lock to prevent duplicates)
                    if distance < Config.AnimalDistanceSpawn and not spawnedAnimals[animalKey] and not spawningLocks[animalKey] then
                        spawningLocks[animalKey] = true
                        local spawnedAnimal = NearAnimal(loadData)
                        
                        if spawnedAnimal and DoesEntityExist(spawnedAnimal) then
                            spawnedAnimals[animalKey] = { 
                                spawnedAnimal = spawnedAnimal
                            }
                            
                            -- Debug spawning
                            if Config.Debug then
                                print('^2[ANIMAL DEBUG]^7 Spawned animal ' .. animalKey .. ' (entity: ' .. spawnedAnimal .. ') at distance ' .. math.floor(distance * 10) / 10 .. 'm')
                            end
                        else
                            -- Failed to spawn, log error if debug enabled
                            if Config.Debug then
                                print('^1[ANIMAL DEBUG]^7 Failed to spawn animal ' .. animalKey .. ' at distance ' .. math.floor(distance * 10) / 10 .. 'm')
                            end
                        end
                        
                        -- Always clear the lock, regardless of spawn success
                        spawningLocks[animalKey] = nil
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
                end
            end
        end
    end
end)

---------------------------------------------
-- animal spawner
---------------------------------------------
function NearAnimal(loadData)
    -- Validate input data
    if not loadData or not loadData.model or not loadData.pos_x or not loadData.pos_y or not loadData.pos_z then
        if Config.Debug then
            print("^1[ERROR]^7 Invalid animal data provided to NearAnimal function")
        end
        return nil
    end
    
    local model = GetHashKey(loadData.model)
    lib.requestModel(model, 5000)
    if not HasModelLoaded(model) then
        if Config.Debug then
            print("^1[ERROR]^7 Failed to load model: " .. tostring(loadData.model))
        end
        return nil
    end
    
    local spawnedAnimal = CreatePed(model, tonumber(loadData.pos_x), tonumber(loadData.pos_y), tonumber(loadData.pos_z) - 1.0, tonumber(loadData.pos_w or 0), false, false, 0, 0)
    if not DoesEntityExist(spawnedAnimal) then
        if Config.Debug then
            print("^1[ERROR]^7 Failed to create animal entity")
        end
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
    -- Debug: Check pregnancy status in received data
    if Config.Debug then
        for _, animal in ipairs(animalData) do
            if animal.pregnant == 1 then
                print('^3[CLIENT DEBUG]^7 Received pregnant animal ' .. animal.animalid .. ' (pregnant: ' .. tostring(animal.pregnant) .. ', gestation_end_time: ' .. tostring(animal.gestation_end_time) .. ')')
            end
        end
    end
    
    -- Update the cache
    animalDataCache = animalData
    
    -- Convert array to keyed table for easier lookup (ensure string keys)
    local keyedData = {}
    for _, animal in ipairs(animalData) do
        local animalKey = tostring(animal.animalid)
        keyedData[animalKey] = animal
    end
    
    -- Check for animals that no longer exist in the database and remove them
    local animalsToRemove = {}
    for animalKey, _ in pairs(spawnedAnimals) do
        local found = false
        for _, animal in ipairs(animalData) do
            if tostring(animal.animalid) == animalKey then
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
        local animalKey = tostring(cachedAnimal.animalid)
        if keyedData[animalKey] then
            animalDataCache[i] = keyedData[animalKey]
        end
    end
end)

---------------------------------------------
-- get fresh animal data from cache
---------------------------------------------
local function getFreshAnimalData(animalid)
    local targetId = tostring(animalid)
    for _, cachedAnimal in ipairs(animalDataCache) do
        if tostring(cachedAnimal.animalid) == targetId then
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
    -- Handle both boolean and integer pregnancy values from database
    local isPregnant = (freshData.pregnant == 1 or freshData.pregnant == true)
    local pregnantStatus = isPregnant and 'Pregnant' or 'Not Pregnant'
    
    -- Debug pregnancy status
    if Config.Debug and freshData.gender == 'female' then
        print('^3[MENU DEBUG]^7 Animal ' .. freshData.animalid .. ' - pregnant field: ' .. tostring(freshData.pregnant) .. ', status: ' .. pregnantStatus)
    end
    
    -- Breeding status calculation (simplified to avoid client-side time issues)
    local breedingStatus = 'Unknown'
    local canBreed = false
    local breedingDescription = ''
    
    if Config.BreedingEnabled then
        local isPregnant = freshData.gender == 'female' and (freshData.pregnant == 1 or freshData.pregnant == true)
        canBreed = not isPregnant
        
        if isPregnant then
            breedingStatus = 'Pregnant'
            breedingDescription = 'Expecting offspring soon'
        elseif freshData.gender == 'male' then
            breedingStatus = 'Male - Ready'
            breedingDescription = 'Can participate in breeding'
        else
            -- Check breeding requirements for females
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
            
            -- Skip client-side cooldown check - let server handle it
            -- The server will properly validate cooldown timing during breeding attempts
            
            if canBreed and #breedingIssues == 0 then
                breedingStatus = 'Ready to Breed'
                breedingDescription = 'All requirements met for breeding'
            else
                breedingStatus = 'Not Ready'
                breedingDescription = table.concat(breedingIssues, ', ')
            end
        end
        
        -- Also allow males to breed (not just females)
        if freshData.gender == 'male' then
            local maleIssues = {}
            
            if Config.MinAgeForBreeding and actualAge < Config.MinAgeForBreeding then
                canBreed = false
                table.insert(maleIssues, 'Too young (need ' .. Config.MinAgeForBreeding .. ' days)')
            elseif Config.MaxBreedingAge and actualAge > Config.MaxBreedingAge then
                canBreed = false
                table.insert(maleIssues, 'Too old (max ' .. Config.MaxBreedingAge .. ' days)')
            end
            
            if Config.RequireHealthForBreeding and (freshData.health or 100) < Config.RequireHealthForBreeding then
                canBreed = false
                table.insert(maleIssues, 'Health too low (need ' .. Config.RequireHealthForBreeding .. '%)')
            end
            
            if Config.RequireHungerForBreeding and (freshData.hunger or 100) < Config.RequireHungerForBreeding then
                canBreed = false
                table.insert(maleIssues, 'Hunger too low (need ' .. Config.RequireHungerForBreeding .. '%)')
            end
            
            if Config.RequireThirstForBreeding and (freshData.thirst or 100) < Config.RequireThirstForBreeding then
                canBreed = false
                table.insert(maleIssues, 'Thirst too low (need ' .. Config.RequireThirstForBreeding .. '%)')
            end
            
            -- Skip client-side cooldown check for males too
            -- Server will validate cooldown timing
            
            if #maleIssues > 0 then
                breedingStatus = 'Male - Not Ready'
                breedingDescription = table.concat(maleIssues, ', ')
                canBreed = false
            end
        end
    else
        breedingStatus = 'Disabled'
        breedingDescription = 'Breeding system is disabled'
    end
    
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

    -- Build menu options dynamically
    local menuOptions = {
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
        }
    }
    
    -- Add breeding status for female animals only
    if Config.BreedingEnabled and freshData.gender == 'female' then
        local breedingOption = {
            title = 'Breeding: '..breedingStatus,
            description = breedingDescription,
            icon = (freshData.pregnant == 1 or freshData.pregnant == true) and 'fa-solid fa-baby' or 'fa-solid fa-venus',
            disabled = false
        }
        
        -- Add pregnancy progress bar if animal is pregnant
        if (freshData.pregnant == 1 or freshData.pregnant == true) and freshData.gestation_end_time then
            -- Get pregnancy progress from server before displaying menu
            RSGCore.Functions.TriggerCallback('rex-ranch:server:getPregnancyProgress', function(progressData)
                if progressData and progressData.isPregnant then
                    breedingOption.progress = progressData.progressPercent
                    breedingOption.colorScheme = 'blue'
                    breedingOption.description = progressData.description
                else
                    -- Fallback if server callback fails
                    breedingOption.description = 'Pregnant - calculating progress...'
                end
                
                -- Update the breeding option
                table.insert(menuOptions, breedingOption)
                
                -- Add breeding partner option for eligible animals
                if canBreed and freshData.gender then
                    local buttonTitle = 'Find Breeding Partner'
                    local buttonDesc = 'Look for compatible animals to breed with'
                    
                    -- Customize button text based on gender
                    if freshData.gender == 'male' then
                        buttonDesc = 'Find female animals to breed with'
                    elseif freshData.gender == 'female' then
                        buttonDesc = 'Find male animals to breed with'
                    end
                    
                    table.insert(menuOptions, {
                        title = buttonTitle,
                        description = buttonDesc,
                        icon = 'fa-solid fa-search',
                        event = 'rex-ranch:client:findBreedingPartner',
                        args = { animalid = freshData.animalid, animal = animal }
                    })
                end
                
                -- Add separator and actions
                table.insert(menuOptions, {
                    title = '─────────────────────────',
                    disabled = true
                })
                table.insert(menuOptions, {
                    title = 'Animal Actions',
                    description = 'Care for your animal',
                    icon = 'fa-solid fa-hand-holding-heart',
                    event = 'rex-ranch:client:actionsmenu',
                    args = { animalid = freshData.animalid, animal = animal },
                    arrow = true
                })
                
                -- Display the menu with updated pregnancy progress
                lib.registerContext({
                    id = 'animal_info_menu',
                    title = 'Ranch Animal #'..freshData.animalid,
                    options = menuOptions
                })
                lib.showContext('animal_info_menu')
            end, freshData.animalid)
            
            -- Don't add the breeding option yet - wait for callback
            return
        end
        
        table.insert(menuOptions, breedingOption)
    end
    
    -- Add breeding partner option for eligible animals (both male and female)
    -- Males can breed with females, females can breed with males
    if Config.BreedingEnabled and canBreed and freshData.gender then
        local buttonTitle = 'Find Breeding Partner'
        local buttonDesc = 'Look for compatible animals to breed with'
        
        -- Customize button text based on gender
        if freshData.gender == 'male' then
            buttonDesc = 'Find female animals to breed with'
        elseif freshData.gender == 'female' then
            buttonDesc = 'Find male animals to breed with'
        end
        
        table.insert(menuOptions, {
            title = buttonTitle,
            description = buttonDesc,
            icon = 'fa-solid fa-search',
            event = 'rex-ranch:client:findBreedingPartner',
            args = { animalid = freshData.animalid, animal = animal }
        })
    end
    
    -- Add separator and actions
    table.insert(menuOptions, {
        title = '─────────────────────────',
        disabled = true
    })
    table.insert(menuOptions, {
        title = 'Animal Actions',
        description = 'Care for your animal',
        icon = 'fa-solid fa-hand-holding-heart',
        event = 'rex-ranch:client:actionsmenu',
        args = { animalid = freshData.animalid, animal = animal },
        arrow = true
    })
    
    lib.registerContext({
        id = 'animal_info_menu',
        title = 'Ranch Animal #'..freshData.animalid,
        options = menuOptions
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
    
    if freshData.gender == 'male' then
        breedingStatus = 'Male - Breeding Disabled'
    elseif Config.BreedingEnabled and Config.MinAgeForBreeding and Config.MaxBreedingAge and actualAge >= Config.MinAgeForBreeding and actualAge <= Config.MaxBreedingAge then
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
                description = 'Requires: '..RSGCore.Shared.Items[Config.FeedItem].label,
                icon = 'fa-solid fa-wheat-awn',
                event = 'rex-ranch:client:feedAnimal',
                args = { animalid = animalid, animal = animal }
            },
            {
                title = 'Water Animal ('..thirstStatus..')',
                description = 'Requires: '..RSGCore.Shared.Items[Config.WaterItem].label,
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
-- update animal status (for breeding, etc.)
---------------------------------------------
RegisterNetEvent('rex-ranch:client:updateAnimalStatus', function(animalid, updatedData)
    local targetId = tostring(animalid)
    
    -- Update the animal cache
    for i, cachedAnimal in ipairs(animalDataCache) do
        if tostring(cachedAnimal.animalid) == targetId then
            -- Update the specific fields that were changed
            for key, value in pairs(updatedData) do
                animalDataCache[i][key] = value
            end
            
            if Config.Debug then
                print('^2[ANIMAL DEBUG]^7 Updated animal ' .. animalid .. ' status in cache')
            end
            break
        end
    end
    
    -- If there's an open menu for this animal, we should close it so the player can reopen with fresh data
    -- This ensures they see the updated pregnancy status immediately
    lib.hideContext()
end)

---------------------------------------------
-- remove animal when sold
---------------------------------------------
RegisterNetEvent('rex-ranch:client:removeAnimal', function(animalid)
    local animalKey = tostring(animalid)
    
    if Config.Debug then
        print('^1[ANIMAL REMOVAL DEBUG]^7 Received removal request for animal: ' .. animalKey)
        print('^1[ANIMAL REMOVAL DEBUG]^7 Current spawned animals count: ' .. GetTableLength(spawnedAnimals))
    end
    
    -- Use consistent string key lookup
    local entityToRemove = nil
    if spawnedAnimals[animalKey] then
        if Config.Debug then
            print('^2[ANIMAL REMOVAL DEBUG]^7 Found animal in spawned table: ' .. animalKey)
        end
        
        if DoesEntityExist(spawnedAnimals[animalKey].spawnedAnimal) then
            entityToRemove = spawnedAnimals[animalKey].spawnedAnimal
            if Config.Debug then
                print('^2[ANIMAL REMOVAL DEBUG]^7 Entity exists, will remove: ' .. entityToRemove)
            end
        else
            if Config.Debug then
                print('^3[ANIMAL REMOVAL DEBUG]^7 Entity no longer exists for animal: ' .. animalKey)
            end
        end
        spawnedAnimals[animalKey] = nil
    else
        if Config.Debug then
            print('^3[ANIMAL REMOVAL DEBUG]^7 Animal not found in spawned table: ' .. animalKey)
        end
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
            print('^2[ANIMAL REMOVAL DEBUG]^7 Successfully removed animal entity: ' .. animalid .. ' (entity: ' .. entityToRemove .. ')')
        end
    else
        if Config.Debug then
            print('^1[ANIMAL REMOVAL DEBUG]^7 No entity to remove for animal: ' .. animalid)
        end
    end
    
    -- Also remove from follow states and transport states
    followStates[animalKey] = nil
    transportingAnimals[animalKey] = nil
    
    -- Remove from cache
    local removedFromCache = false
    for i, cachedAnimal in ipairs(animalDataCache) do
        if tostring(cachedAnimal.animalid) == animalKey then
            table.remove(animalDataCache, i)
            removedFromCache = true
            break
        end
    end
    
    if Config.Debug then
        print('^2[ANIMAL REMOVAL DEBUG]^7 Removal completed for animal ' .. animalKey .. ' - Cache removed: ' .. tostring(removedFromCache))
        print('^2[ANIMAL REMOVAL DEBUG]^7 New spawned animals count: ' .. GetTableLength(spawnedAnimals))
        print('^2[ANIMAL REMOVAL DEBUG]^7 New cached animals count: ' .. #animalDataCache)
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
-- Debug command to check animal entities
---------------------------------------------
RegisterCommand('debuganimals', function()
    local playerCoords = GetEntityCoords(cache.ped)
    local nearbyPeds = {}
    local totalAnimals = 0
    local orphanedEntities = 0
    
    print('^3[ANIMAL DEBUG]^7 === Animal Debug Report ===')
    print('^3[ANIMAL DEBUG]^7 Spawned Animals Count: ' .. GetTableLength(spawnedAnimals))
    print('^3[ANIMAL DEBUG]^7 Cached Animals Count: ' .. #animalDataCache)
    
    -- Check for nearby animal entities
    for i = 1, 256 do -- Check nearby entities
        local entity = GetClosestPed(playerCoords.x, playerCoords.y, playerCoords.z, i, false, false, 0)
        if DoesEntityExist(entity) and entity ~= cache.ped then
            local model = GetEntityModel(entity)
            local modelName = ''
            
            -- Check if it's a known ranch animal model
            if model == GetHashKey('a_c_bull_01') then
                modelName = 'a_c_bull_01'
                totalAnimals = totalAnimals + 1
            elseif model == GetHashKey('a_c_cow') then
                modelName = 'a_c_cow' 
                totalAnimals = totalAnimals + 1
            end
            
            if modelName ~= '' then
                local distance = #(playerCoords - GetEntityCoords(entity))
                local isTracked = false
                
                -- Check if this entity is tracked in our spawned animals
                for _, animalData in pairs(spawnedAnimals) do
                    if animalData.spawnedAnimal == entity then
                        isTracked = true
                        break
                    end
                end
                
                if not isTracked then
                    orphanedEntities = orphanedEntities + 1
                    print('^1[ANIMAL DEBUG]^7 Orphaned ' .. modelName .. ' entity found at distance ' .. math.floor(distance * 10) / 10 .. 'm (entity: ' .. entity .. ')')
                else
                    print('^2[ANIMAL DEBUG]^7 Tracked ' .. modelName .. ' entity at distance ' .. math.floor(distance * 10) / 10 .. 'm (entity: ' .. entity .. ')')
                end
            end
        end
    end
    
    print('^3[ANIMAL DEBUG]^7 Total Animal Entities: ' .. totalAnimals)
    print('^1[ANIMAL DEBUG]^7 Orphaned Entities: ' .. orphanedEntities)
    print('^3[ANIMAL DEBUG]^7 === End Debug Report ===')
end, false)

function GetTableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end


---------------------------------------------
-- find breeding partner (from animal info menu)
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
            menu = 'animal_info_menu',
            options = options
        })
        lib.showContext('breeding_partner_menu')
        
    end, ranchid, animalid)
end)

---------------------------------------------
-- confirm breeding (from animal info menu)
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

---------------------------------------------
-- cleanup
---------------------------------------------
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
