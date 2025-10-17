local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

RegisterNetEvent('rex-ranch:client:openmanagermenu', function(ranchid)
    local options = {
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
            title = 'Buy Animals',
            description = 'Visit livestock dealers around the map to purchase animals',
            icon = 'fa-solid fa-shopping-cart',
            event = 'rex-ranch:client:showBuyPoints',
            arrow = true
        },
        {
            title = 'Sell Animals',
            icon = 'fa-solid fa-hand-holding-dollar',
            event = 'rex-ranch:client:showSalePoints',
            args = { ranchid = ranchid },
            arrow = true
        }
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

---------------------------------------------
-- show buy points selector
---------------------------------------------
RegisterNetEvent('rex-ranch:client:showBuyPoints', function()
    local options = {}
    
    for _, buyPointData in pairs(Config.BuyPointLocations) do
        table.insert(options, {
            title = buyPointData.name,
            description = 'Visit this livestock dealer to purchase animals for your ranch',
            icon = 'fa-solid fa-map-marker-alt',
            disabled = true -- Just informational, they need to physically visit
        })
    end
    
    table.insert(options, {
        title = '─────────────────────────',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Visit Locations',
        description = 'Check your map for livestock dealer blips and visit them in person',
        icon = 'fa-solid fa-info-circle',
        disabled = true
    })
    
    lib.registerContext({
        id = 'buy_points_selector',
        title = 'Livestock Dealers',
        options = options
    })
    lib.showContext('buy_points_selector')
end)

