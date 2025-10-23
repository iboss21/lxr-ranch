local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

RegisterNetEvent('rex-ranch:client:openmanagermenu', function(ranchid)
    local options = {
        {
            title = '👥 Staff Management',
            description = 'Manage ranch employees',
            icon = 'fa-solid fa-user-tie',
            event = 'rex-ranch:client:openStaffManagement',
            args = ranchid,
            arrow = true
        },
        {
            title = 'Ranch Storage',
            icon = 'fa-solid fa-box',
            serverEvent = 'rex-ranch:server:ranchstorage',
            args = { ranchid = ranchid },
            arrow = true
        },
        {
            title = 'Animal Overview',
            description = 'View detailed animal statistics and status',
            icon = 'fa-solid fa-list',
            event = 'rex-ranch:client:openAnimalOverview',
            args = ranchid,
            arrow = true
        },
    }
    
    -- Add herding option if enabled
    if Config.HerdingEnabled then
        table.insert(options, {
            title = 'Animal Herding',
            description = 'Herd animals by distance or type',
            icon = 'fa-solid fa-paw',
            event = 'rex-ranch:client:openHerdingMenu',
            arrow = true
        })
    end
    
    lib.registerContext({
        id = 'manager_job_menu',
        title = 'Manager Menu',
        options = options
    })
    lib.showContext('manager_job_menu')
end)
