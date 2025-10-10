local RSGCore = exports['rsg-core']:GetCoreObject()
local spawnedAnimals = {}
local animalDataCache = {}
local followStates = {}
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
        Wait(1000)
        for k, loadData in pairs(animalDataCache) do
            local playerCoords = GetEntityCoords(cache.ped)
            local animalCoords = vector3(loadData.pos_x, loadData.pos_y, loadData.pos_z)
            local distance = #(playerCoords - animalCoords)
            
            -- spawn animal if within range
            if distance < Config.AnimalDistanceSpawn and not spawnedAnimals[k] then
                local spawnedAnimal = NearAnimal(loadData)
                spawnedAnimals[k] = { 
                    spawnedAnimal = spawnedAnimal
                }
            end
            
            -- despawn animal if out of range
            if distance >= Config.AnimalDistanceSpawn and spawnedAnimals[k] then
                if Config.AnimalFadeIn then
                    for i = 255, 0, -51 do
                        Wait(50)
                        SetEntityAlpha(spawnedAnimals[k].spawnedAnimal, i, false)
                    end
                end
                DeletePed(spawnedAnimals[k].spawnedAnimal)
                spawnedAnimals[k] = nil
            end
        end
    end
end)

---------------------------------------------
-- animal spawner
---------------------------------------------
function NearAnimal(loadData)
    local model = GetHashKey(loadData.model)
    lib.requestModel(model, 5000)
    if not HasModelLoaded(model) then
        print("Failed to load model: " .. loadData.model)
        return nil
    end
    local spawnedAnimal = CreatePed(model, loadData.pos_x, loadData.pos_y, loadData.pos_z - 1.0, loadData.pos_w, false, false, 0, 0)
    NetworkRegisterEntityAsNetworked(spawnedAnimal)
    SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(spawnedAnimal), true)
    SetPedScale(spawnedAnimal, loadData.scale)
    SetEntityAsMissionEntity(spawnedAnimal, true, true)
    SetEntityInvincible(spawnedAnimal, false)
    FreezeEntityPosition(spawnedAnimal, false)
    SetRandomOutfitVariation(spawnedAnimal, true)
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
    animalDataCache = animalData
end)

---------------------------------------------
-- animal menu
---------------------------------------------
RegisterNetEvent('rex-ranch:client:animalmenu', function(animal, data)
    -- animal age
    local ageText = 'Youth'
    if data.age < 5 then ageText = 'Youth' end
    if data.age >= 5 then ageText = 'Adult' end
    -- health colorScheme
    local healthColorScheme = 'green'
    if data.health > 80 then healthColorScheme = 'green' end
    if data.health <= 80 and data.health > 10 then healthColorScheme = 'yellow' end
    if data.health <= 10 then healthColorScheme = 'red' end
    data.health = math.clamp(data.health, 0, 100) or math.min(math.max(data.health, 0), 100)

    -- thirst colorScheme
    local thirstColorScheme = 'green'
    if data.thirst > 80 then thirstColorScheme = 'green' end
    if data.thirst <= 80 and data.thirst > 10 then thirstColorScheme = 'yellow' end
    if data.thirst <= 10 then thirstColorScheme = 'red' end
    data.thirst = math.clamp(data.thirst, 0, 100) or math.min(math.max(data.thirst, 0), 100)

    -- hunger colorScheme
    local hungerColorScheme = 'green'
    if data.hunger > 80 then hungerColorScheme = 'green' end
    if data.hunger <= 80 and data.hunger > 10 then hungerColorScheme = 'yellow' end
    if data.hunger <= 10 then hungerColorScheme = 'red' end
    data.hunger = math.clamp(data.hunger, 0, 100) or math.min(math.max(data.hunger, 0), 100)

    lib.registerContext({
        id = 'animal_info_menu',
        title = 'Animal Info',
        options = {
            {
                title = 'Brading - '..data.animalid,
                icon = 'fa-solid fa-fingerprint',
            },
            {
                title = 'Age - '..ageText,
                icon = 'fa-solid fa-calendar-days',
            },
            {
                title = 'Health - '..data.health,
                progress = data.health,
                colorScheme = healthColorScheme,
                icon = 'fa-solid fa-heart-pulse',
            },
            {
                title = 'Thirst - '..data.thirst,
                progress = data.thirst,
                colorScheme = thirstColorScheme,
                icon = 'fa-solid fa-droplet',
            },
            {
                title = 'Hunger - '..data.hunger,
                progress = data.hunger,
                colorScheme = hungerColorScheme,
                icon = 'fa-solid fa-wheat-awn',
            },
            {
                title = 'Toggle Follow',
                icon = 'fa-solid fa-eye',
                event = 'rex-ranch:client:animalfollow',
                args = { animal = animal, animalid = data.animalid },
                arrow = true
            },
        }
    })
    lib.showContext('animal_info_menu')
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
    followStates[data.animalid] = not followStates[data.animalid] or false
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

---------------------------------
-- cleanup
---------------------------------
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for k,v in pairs(spawnedAnimals) do
        DeletePed(spawnedAnimals[k].spawnedAnimal)
        spawnedAnimals[k] = nil
    end
end)
