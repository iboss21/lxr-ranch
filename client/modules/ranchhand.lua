local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

RegisterNetEvent('rex-ranch:client:openranchhandmenu', function(data)
    lib.registerContext({
        id = 'ranchhand_job_menu',
        title = 'Rancher Menu',
        options = {
            {
                title = 'Ranch Storage',
                icon = 'fa-solid fa-box',
                serverEvent = 'rex-ranch:server:ranchstorage',
                args = { ranchid = data.ranchid },
                arrow = true
            },
        }
    })
    lib.showContext('ranchhand_job_menu')
end)
