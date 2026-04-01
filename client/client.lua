--[[
    ██╗     ██╗  ██╗██████╗       ██████╗  █████╗ ███╗   ██╗ ██████╗██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗      ██╔══██╗██╔══██╗████╗  ██║██╔════╝██║  ██║
    ██║      ╚███╔╝ ██████╔╝█████╗██████╔╝███████║██╔██╗ ██║██║     ███████║
    ██║      ██╔██╗ ██╔══██╗╚════╝██╔══██╗██╔══██║██║╚██╗██║██║     ██╔══██║
    ███████╗██╔╝ ██╗██║  ██║      ██║  ██║██║  ██║██║ ╚████║╚██████╗██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝

    🐺 LXR Core - Ranch Simulation Client Entry
    Server:      The Land of Wolves 🐺
    Developer:   iBoss21 / The Lux Empire
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ INITIALIZATION ████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ BLIP REGISTRATION █████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

CreateThread(function()
    for _, ranchData in pairs(Config.RanchLocations) do
        if ranchData.showblip == true then
            local blipHash = Config.NPC and Config.NPC.blipHash or 1664425300
            local RanchBlip = BlipAddForCoords(blipHash, ranchData.coords)
            SetBlipSprite(RanchBlip, joaat(ranchData.blipsprite), true)
            SetBlipScale(RanchBlip, ranchData.blipscale)
            SetBlipName(RanchBlip, ranchData.blipname)
        end
    end
end)

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ MENU ROUTING ██████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

RegisterNetEvent('lxr-ranch:client:openranch', function(ranchid, jobaccess)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local playerjob = PlayerData.job.name
    local playerlevel = PlayerData.job.grade.level
    if playerjob ~= jobaccess then return end
    if playerlevel == 0 then
        TriggerEvent('lxr-ranch:client:opentraineemenu', ranchid)
    elseif playerlevel == 1 then
        TriggerEvent('lxr-ranch:client:openranchhandmenu', ranchid)
    elseif playerlevel >= 2 then
        TriggerEvent('lxr-ranch:client:openmanagermenu', ranchid)
    end
end)

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ NUI DASHBOARD █████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

local dashboardOpen = false

function OpenRanchDashboard(ranchid)
    if dashboardOpen then return end
    RSGCore.Functions.TriggerCallback('lxr-ranch:server:getDashboardData', function(data)
        if not data then
            lib.notify({ title = 'Error', description = 'Failed to load ranch data', type = 'error' })
            return
        end
        dashboardOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', ranchid = ranchid, data = data })
    end, ranchid)
end

RegisterNUICallback('closeUI', function(_, cb)
    dashboardOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('payTax', function(data, cb)
    TriggerServerEvent('lxr-ranch:server:payTax', data.ranchid)
    cb('ok')
end)

RegisterNUICallback('refreshDashboard', function(data, cb)
    RSGCore.Functions.TriggerCallback('lxr-ranch:server:getDashboardData', function(newData)
        if newData then
            SendNUIMessage({ action = 'update', data = newData })
        end
        cb('ok')
    end, data.ranchid)
end)

RegisterCommand('ranchdashboard', function()
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.job then return end
    local playerjob = PlayerData.job.name
    local playerlevel = PlayerData.job.grade.level
    if playerlevel < (Config.Staff and Config.Staff.minGradeToManage or 2) then
        lib.notify({ title = 'Access Denied', description = 'Managers only', type = 'error' })
        return
    end
    for _, ranchData in pairs(Config.RanchLocations) do
        if playerjob == ranchData.jobaccess then
            OpenRanchDashboard(ranchData.ranchid)
            return
        end
    end
end, false)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 wolves.land — The Land of Wolves
-- © 2026 iBoss21 / The Lux Empire — All Rights Reserved
-- ═══════════════════════════════════════════════════════════════════════════════
