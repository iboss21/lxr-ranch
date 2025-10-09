local RSGCore = exports['rsg-core']:GetCoreObject()
local spawnedAnimals = {}
local animalDataCache = {}

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('rex-ranch:server:refreshAnimals')
end)

-- check distance and spawn animal
CreateThread(function()
    while true do
        Wait(500)
        for k,loadData in pairs(animalDataCache) do
            local playerCoords = GetEntityCoords(cache.ped)
            local distance = #(playerCoords - vector3(loadData.pos_x, loadData.pos_y, loadData.pos_z))
            if distance < Config.AnimalDistanceSpawn and not spawnedAnimals[k] then
                local spawnedAnimal = NearAnimal(loadData)
                spawnedAnimals[k] = { spawnedAnimal = spawnedAnimal }
            end
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
                TriggerEvent('rex-ranch:client:animalmenu', loadData)
            end,
            distance = 2.0
        }
    })
    return spawnedAnimal
end

RegisterNetEvent('rex-ranch:client:spawnAnimals', function(animalData)
    animalDataCache = animalData
end)

RegisterNetEvent('rex-ranch:client:animalmenu', function(data)
    lib.registerContext({
        id = 'animal_info_menu',
        title = 'Adimal Actions',
        options = {
            {
                title = 'Ranch Management',
                icon = 'fa-solid fa-user-tie',
                event = 'rsg-bossmenu:client:mainmenu',
                arrow = true
            },
        }
    })
    lib.showContext('animal_info_menu')
end)

---------------------------------
-- cleanup
---------------------------------
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for k,v in pairs(spawnedAnimals) do
        DeletePed(spawnedAnimals[k].spawnedAnimal)
        spawnedAnimals[k] = nil
    end
end)
