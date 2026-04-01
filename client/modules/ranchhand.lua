--[[ ═══════════════════════════════════════════════════════════════════════════
     🐺 LXR-RANCH — The Land of Wolves
     ═══════════════════════════════════════════════════════════════════════════
     Developer   : iBoss21 | Brand : The Lux Empire
     https://www.wolves.land | https://discord.gg/CrKcWdfd3A
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / The Lux Empire — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]
local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

RegisterNetEvent('lxr-ranch:client:openranchhandmenu', function(ranchid)
    local herdingOption = {}
    if Config.HerdingEnabled then
        herdingOption = {
            title = 'Animal Herding',
            description = 'Herd animals by distance or type',
            icon = 'fa-solid fa-paw',
            event = 'lxr-ranch:client:openHerdingMenu',
            arrow = true
        }
    end
    
    local options = {
        {
            title = 'Ranch Storage',
            icon = 'fa-solid fa-box',
            serverEvent = 'lxr-ranch:server:ranchstorage',
            args = { ranchid = ranchid },
            arrow = true
        },
        {
            title = 'Animal Overview',
            description = 'View detailed animal statistics and status',
            icon = 'fa-solid fa-list',
            event = 'lxr-ranch:client:openAnimalOverview',
            args = ranchid,
            arrow = true
        },
    }
    
    if Config.HerdingEnabled then
        table.insert(options, herdingOption)
    end
    
    lib.registerContext({
        id = 'ranchhand_job_menu',
        title = 'Rancher Menu',
        options = options
    })
    lib.showContext('ranchhand_job_menu')
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 wolves.land — The Land of Wolves
-- © 2026 iBoss21 / The Lux Empire — All Rights Reserved
-- ═══════════════════════════════════════════════════════════════════════════════
