local RSGCore = exports['rsg-core']:GetCoreObject()
local spawnedPeds = {}

CreateThread(function()
    while true do
        Wait(500)
        for k,npcData in pairs(Config.RanchLocations) do
            local playerCoords = GetEntityCoords(cache.ped)
            local distance = #(playerCoords - npcData.npccoords.xyz)
            if distance < Config.DistanceSpawn and not spawnedPeds[k] then
                local spawnedPed = NearPed(npcData)
                spawnedPeds[k] = { spawnedPed = spawnedPed }
            end
            if distance >= Config.DistanceSpawn and spawnedPeds[k] then
                if Config.FadeIn then
                    for i = 255, 0, -51 do
                        Wait(50)
                        SetEntityAlpha(spawnedPeds[k].spawnedPed, i, false)
                    end
                end
                DeletePed(spawnedPeds[k].spawnedPed)
                spawnedPeds[k] = nil
            end
        end
    end
end)

function NearPed(npcData)
    RequestModel(npcData.npcmodel)
    while not HasModelLoaded(npcData.npcmodel) do
        Wait(50)
    end
    spawnedPed = CreatePed(npcData.npcmodel, npcData.npccoords.x, npcData.npccoords.y, npcData.npccoords.z - 1.0, npcData.npccoords.w, false, false, 0, 0)
    SetEntityAlpha(spawnedPed, 0, false)
    SetRandomOutfitVariation(spawnedPed, true)
    SetEntityCanBeDamaged(spawnedPed, false)
    SetEntityInvincible(spawnedPed, true)
    FreezeEntityPosition(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)
    SetPedCanBeTargetted(spawnedPed, false)
    SetPedFleeAttributes(spawnedPed, 0, false)
    if Config.FadeIn then
        for i = 0, 255, 51 do
            Wait(50)
            SetEntityAlpha(spawnedPed, i, false)
        end
    end
    exports.ox_target:addLocalEntity(spawnedPed, {
        {
            name = 'npc_ranch',
            icon = 'far fa-eye',
            label = 'Open Ranch',
            onSelect = function()
                TriggerEvent('rex-ranch:client:openranch', npcData.ranchid, npcData.jobaccess)
            end,
            distance = 2.0
        }
    })
    return spawnedPed
end

---------------------------------
-- cleanup
---------------------------------
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for k,v in pairs(spawnedPeds) do
        DeletePed(spawnedPeds[k].spawnedPed)
        spawnedPeds[k] = nil
    end
end)
