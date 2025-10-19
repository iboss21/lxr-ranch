local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

RegisterNetEvent('rex-ranch:client:openranchhandmenu', function(ranchid)
    local herdingOption = {}
    if Config.HerdingEnabled then
        herdingOption = {
            title = 'Animal Herding',
            description = 'Herd animals by distance or type',
            icon = 'fa-solid fa-paw',
            event = 'rex-ranch:client:openHerdingMenu',
            arrow = true
        }
    end
    
    local options = {
        {
            title = 'Ranch Storage',
            icon = 'fa-solid fa-box',
            serverEvent = 'rex-ranch:server:ranchstorage',
            args = { ranchid = ranchid },
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
