local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

RegisterNetEvent('rex-ranch:client:openmanagermenu', function(ranchid)
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
                args = { ranchid = ranchid },
                arrow = true
            },
            {
                title = 'Buy Livestock',
                icon = 'fa-solid fa-user-tie',
                event = 'rex-ranch:client:buylivestock',
                args = { ranchid = ranchid },
                arrow = true
            },
        }
    })
    lib.showContext('manager_job_menu')
end)

RegisterNetEvent('rex-ranch:client:buylivestock', function(data)
    for _,ranchData in pairs(Config.RanchLocations) do
        if ranchData.ranchid == data.ranchid then
            lib.registerContext({
                id = 'manager_buu_livestock',
                title = 'Livestock Menu',
                options = {
                    {
                        title = 'Buy Cow',
                        icon = 'fa-solid fa-user-tie',
                        serverEvent = 'rex-ranch:server:buylivestock',
                        args = { 
                            animal = 'a_c_cow',
                            ranchid = ranchData.ranchid,
                            spawnpoint = ranchData.spawnpoint,
                            cowbuy = ranchData.cowbuy,
                            jobaccess = ranchData.jobaccess
                        },
                        arrow = true
                    },
                }
            })
            lib.showContext('manager_buu_livestock')
        end
    end
end)
