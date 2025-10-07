local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

RegisterNetEvent('rex-ranch:client:openmanagermenu', function(data)
    lib.registerContext({
        id = 'manager_job_menu',
        title = 'Manager Menu',
        options = {
            {
                title = 'Ranch Management',
                icon = 'fa-solid fa-user-tie',
                event = 'rsg-bossmenu:client:mainmenu',
                arrow = true
            },
            {
                title = 'Ranch Storage',
                icon = 'fa-solid fa-box',
                serverEvent = 'rex-ranch:server:ranchstorage',
                args = { ranchid = data.ranchid },
                arrow = true
            },
        }
    })
    lib.showContext('manager_job_menu')
end)
