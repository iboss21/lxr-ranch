local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------------------
-- blips
---------------------------------------------
CreateThread(function()
    for _,ranchData in pairs(Config.RanchLocations) do
        if ranchData.showblip == true then
            local RanchBlip = BlipAddForCoords(Config.BLIP_HASH, ranchData.coords)
            SetBlipSprite(RanchBlip, joaat(ranchData.blipsprite), true)
            SetBlipScale(RanchBlip, ranchData.blipscale)
            SetBlipName(RanchBlip, ranchData.blipname)
        end
    end
end)

---------------------------------------------
-- get correct menu
---------------------------------------------
RegisterNetEvent('rex-ranch:client:openranch', function(ranchid, jobaccess)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local playerjob = PlayerData.job.name
    local playerlevel = PlayerData.job.grade.level
    if playerjob ~= jobaccess then return end
    if playerlevel == 0 then
        TriggerEvent('rex-ranch:client:opentraineemenu', ranchid)
    end
    if playerlevel == 1 then
        TriggerEvent('rex-ranch:client:openranchhandmenu', ranchid)
    end
    if playerlevel == 2 then
        TriggerEvent('rex-ranch:client:openmanagermenu', ranchid)
    end
end)
