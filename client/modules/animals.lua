local RSGCore = exports['rsg-core']:GetCoreObject()
local spawnedAnimals = {}
local animalsSpawned = false
lib.locale()

---------------------------------------------
-- spawn animals and verify all animals spawned
---------------------------------------------
RegisterNetEvent('rex-ranch:client:spawnAnimals', function(animalData)

    for _, animal in pairs(spawnedAnimals) do
        if DoesEntityExist(animal) then
            DeleteEntity(animal)
        end
    end

    spawnedAnimals = {}

    -- spawn animals
    local totalAnimals = #animalData
    local spawnedCount = 0

    for _, data in ipairs(animalData) do
        local model = GetHashKey(data.model)
        lib.requestModel(model, 5000)
        local animal = CreatePed(model, data.pos_x, data.pos_y, data.pos_z - 1.0, data.pos_w, false, true)
        if DoesEntityExist(animal) then
            NetworkRegisterEntityAsNetworked(animal)
            SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(animal), true)
            SetEntityAsMissionEntity(animal, true, true)
            SetEntityInvincible(animal, false)
            FreezeEntityPosition(animal, false)
            SetRandomOutfitVariation(animal, true)
            SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), joaat('PLAYER'))
            table.insert(spawnedAnimals, animal)
            spawnedCount = spawnedCount + 1
            SetModelAsNoLongerNeeded(model)
        else
            if Config.Debug then
                print('^1[DEBUG]^7 Failed to spawn animal: ' .. data.model .. ' at ' .. data.pos_x .. ', ' .. data.pos_y .. ', ' .. data.pos_z)
            end
        end
    end

    if spawnedCount == totalAnimals then
        if Config.Debug then
            print('^2[DEBUG]^7 Successfully spawned ' .. spawnedCount .. '/' .. totalAnimals .. ' animals.')
        end
    else
        if Config.Debug then
            print('^1[DEBUG]^7 Warning: Only spawned ' .. spawnedCount .. '/' .. totalAnimals .. ' animals.')
        end
        Citizen.CreateThread(function()
            Wait(5000)
            TriggerServerEvent('rex-ranch:server:refreshAnimals')
            if Config.Debug then
                print('^3[DEBUG]^7 Retrying animal spawn due to incomplete spawning.')
            end
        end)
    end

end)

---------------------------------------------
-- spawn loop
---------------------------------------------
CreateThread(function()
    while true do
        Wait(5000)
        if LocalPlayer.state.isLoggedIn and not animalsSpawned then
            if Config.Debug then 
                print('^3[DEBUG]^7 Attempting to spawn animals.')
            end
            TriggerServerEvent('rex-ranch:server:refreshAnimals')
            animalsSpawned = true
        end
    end
end)

---------------------------------------------
-- cleanup
---------------------------------------------
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, animal in pairs(spawnedAnimals) do
            if DoesEntityExist(animal) then
                DeleteEntity(animal)
            end
        end
    end
end)
