local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------------------
-- blips
---------------------------------------------
CreateThread(function()
    for _,ranchData in pairs(Config.RanchLocations) do
        if ranchData.showblip == true then
            local RanchBlip = BlipAddForCoords(1664425300, ranchData.coords)
            SetBlipSprite(RanchBlip, joaat(ranchData.blipsprite), true)
            SetBlipScale(RanchBlip, ranchData.blipscale)
            SetBlipName(RanchBlip, ranchData.blipname)
        end
    end
end)

---------------------------------------------
-- get correct menu
---------------------------------------------
RegisterNetEvent('rex-ranch:client:openranch', function(data)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local playerjob = PlayerData.job.name
    local playerlevel = PlayerData.job.grade.level
    if playerjob ~= data.jobaccess then return end
    if playerlevel == 0 then
        TriggerEvent('rex-ranch:client:opentraineemenu', data)
    end
    if playerlevel == 1 then
        TriggerEvent('rex-ranch:client:openranchhandmenu', data)
    end
    if playerlevel == 2 then
        TriggerEvent('rex-ranch:client:openmanagermenu', data)
    end
end)
