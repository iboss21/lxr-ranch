local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

RegisterNetEvent('rex-ranch:client:opentraineemenu', function(ranchid)
    local options = {
        {
            title = 'Ranch Information',
            description = 'Learn about ranch operations and your duties',
            icon = 'fa-solid fa-info-circle',
            onSelect = function()
                lib.notify({
                    title = 'Trainee Info',
                    description = 'Welcome! As a trainee, focus on learning ranch operations. Feed and water animals to gain experience.',
                    type = 'inform',
                    duration = 8000
                })
            end
        },
        {
            title = 'Basic Animal Care',
            description = 'Learn how to care for ranch animals',
            icon = 'fa-solid fa-heart',
            onSelect = function()
                lib.notify({
                    title = 'Animal Care Guide',
                    description = 'Find animals around the ranch and interact with them to feed and water them. Keep them healthy!',
                    type = 'inform',
                    duration = 8000
                })
            end
        }
    }
    
    -- Add herding guide if herding is enabled
    if Config.HerdingEnabled then
        table.insert(options, {
            title = 'Herding Guide',
            description = 'Learn about animal herding (available at higher ranks)',
            icon = 'fa-solid fa-paw',
            onSelect = function()
                lib.notify({
                    title = 'Herding Info',
                    description = 'Animal herding will be available when you become a ranch hand. Focus on basic care for now.',
                    type = 'inform',
                    duration = 6000
                })
            end
        })
    end
    
    lib.registerContext({
        id = 'trainee_job_menu',
        title = 'Trainee Menu',
        options = options
    })
    lib.showContext('trainee_job_menu')
end)
