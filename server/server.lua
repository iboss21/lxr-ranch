local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------------------
-- ranch storage
---------------------------------------------
RegisterNetEvent('rex-ranch:server:ranchstorage', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local playerjob = Player.PlayerData.job.name
    local playerjobgrade = Player.PlayerData.job.grade.level
    if playerjob ~= data.ranchid then return end
    if playerjobgrade < Config.StorageMinJobGrade then return end
    local stashdata = { label = 'Ranch Storage', maxweight = Config.RanchStorageMaxWeight, slots = Config.RanchStorageMaxSlots }
    local stashName = data.ranchid
    exports['rsg-inventory']:OpenInventory(src, stashName, stashdata)
end)

---------------------------------------------
-- create unique animalid
---------------------------------------------
local function CreateAnimalId()
    local UniqueFound = false
    local animalid = nil
    local maxAttempts = 50 -- Reduced attempts for better performance
    local attempts = 0
    
    while not UniqueFound and attempts < maxAttempts do
        attempts = attempts + 1
        animalid = math.random(Config.ANIMAL_ID_MIN, Config.ANIMAL_ID_MAX)
        
        local success, result = pcall(function()
            return MySQL.query.await("SELECT COUNT(*) as count FROM rex_ranch_animals WHERE animalid = ?", { animalid })
        end)
        
        if success and result and result[1] and result[1].count == 0 then
            UniqueFound = true
        elseif not success then
            if Config.Debug then
                print("^1[ERROR]^7 Database error in CreateAnimalId: " .. tostring(result))
            end
            break
        end
    end
    
    if not UniqueFound then
        -- Better fallback: use timestamp + server ID + random for uniqueness
        local serverTime = os.time()
        local randomSuffix = math.random(Config.FALLBACK_ID_SUFFIX_MIN, Config.FALLBACK_ID_SUFFIX_MAX)
        animalid = tostring(serverTime) .. tostring(randomSuffix)
        -- Ensure it's not too long by taking last N characters
        if string.len(animalid) > Config.MAX_ID_LENGTH then
            animalid = string.sub(animalid, -Config.MAX_ID_LENGTH)
        end
        if Config.Debug then
            print("^3[WARNING]^7 Used fallback animal ID generation: " .. animalid)
        end
    end
    
    return tonumber(animalid) -- Ensure consistent numeric ID
end

---------------------------------------------
-- count amount of animals the ranch owns
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-ranch:server:countanimals', function(src, cb, ranchid)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not ranchid then 
        cb(0)
        return 
    end
    
    local success, result = pcall(function()
        return MySQL.query.await("SELECT COUNT(*) as count FROM rex_ranch_animals WHERE ranchid = ?", { ranchid })
    end)
    
        if success and result and result[1] then
            cb(result[1].count or 0)
        else
            cb(0)
            if Config.Debug then
                print("^1[ERROR]^7 Failed to query animal count for ranchid: " .. tostring(ranchid))
            end
        end
end)


---------------------------------------------
-- send animals to client side from database
---------------------------------------------
RegisterNetEvent('rex-ranch:server:refreshAnimals', function()
    local success, error = pcall(function()
        MySQL.query('SELECT * FROM `rex_ranch_animals`', {}, function(animals, error)
            if error then
                print('^1[ERROR]^7 Database query failed in refreshAnimals: ' .. tostring(error))
                return
            end
            
            if animals and #animals > 0 then
                -- Debug: Check pregnancy status in data being sent
                if Config.Debug then
                    for i, animal in ipairs(animals) do
                        if animal.pregnant == 1 then
                            print('^3[DEBUG PREGNANCY]^7 Animal ' .. animal.animalid .. ' is pregnant (gestation_end_time: ' .. tostring(animal.gestation_end_time) .. ')')
                        end
                    end
                end
                
                TriggerClientEvent('rex-ranch:client:spawnAnimals', -1, animals)
                if Config.Debug then
                    print('^2[DEBUG]^7 Successfully sent ' .. #animals .. ' animals entries to clients.')
                end
            else
                if Config.Debug then
                    print('^3[INFO]^7 No animals found in database.')
                end
            end
        end)
    end)
    
    if not success then
        if Config.Debug then
            print('^1[ERROR]^7 Critical error in refreshAnimals: ' .. tostring(error))
        end
    end
end)

---------------------------------------------
-- save animal position to database
---------------------------------------------
RegisterNetEvent('rex-ranch:server:saveAnimalPosition', function(animalid, pos_x, pos_y, pos_z, pos_w)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not animalid then return end
    -- update the animal's position in the database
    MySQL.update.await('UPDATE rex_ranch_animals SET pos_x = ?, pos_y = ?, pos_z = ?, pos_w = ? WHERE animalid = ?', {
        pos_x,
        pos_y,
        pos_z,
        pos_w,
        animalid
    })
    TriggerEvent('rex-ranch:server:refreshAnimals')
end)

---------------------------------------------
-- on restart send animals to client from database
---------------------------------------------
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(5000)
        MySQL.query('SELECT * FROM `rex_ranch_animals`', {}, function(animals)
            if animals then
                -- Debug: Check pregnancy status in restart data
                for i, animal in ipairs(animals) do
                    if animal.pregnant == 1 then
                        print('^3[RESTART DEBUG]^7 Animal ' .. animal.animalid .. ' is pregnant (gestation_end_time: ' .. tostring(animal.gestation_end_time) .. ')')
                    end
                end
                
                TriggerClientEvent('rex-ranch:client:spawnAnimals', -1, animals)
                print('^2[REX-RANCH]^7 Sent ' .. #animals .. ' animals entries to clients.')
            end
        end)
    end
end)

---------------------------------------------
-- feed animal system
---------------------------------------------
RegisterNetEvent('rex-ranch:server:feedAnimal', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    -- Handle both string and object parameters for backwards compatibility
    local animalid
    if type(data) == 'table' and data.animalid then
        animalid = data.animalid
    elseif type(data) == 'string' or type(data) == 'number' then
        animalid = tostring(data)
    else
        animalid = nil
    end
    
    if not Player or not animalid then return end
    
    -- Check if player has animal feed in inventory
    local hasFood = Player.Functions.GetItemByName(Config.FeedItem)
    if not hasFood or hasFood.amount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You need ' .. Config.FeedItem .. ' to feed the animals!'})
        return
    end
    
    -- First verify animal exists and get current stats for debugging
    local animalData = MySQL.query.await('SELECT animalid, hunger, health, thirst FROM rex_ranch_animals WHERE animalid = ?', {animalid})
    if not animalData or #animalData == 0 then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Animal not found!'})
        if Config.Debug then
            print('^1[DEBUG]^7 Player ' .. src .. ' tried to feed non-existent animal ' .. animalid)
        end
        return
    end
    
    local animal = animalData[1]
    if Config.Debug then
        print('^3[DEBUG]^7 Feeding animal ' .. animalid .. ' - Current hunger: ' .. (animal.hunger or 'null') .. ', health: ' .. (animal.health or 'null') .. ', thirst: ' .. (animal.thirst or 'null'))
    end
    
    -- Update animal hunger
    local updateSuccess, updateError = pcall(function()
        return MySQL.update.await('UPDATE rex_ranch_animals SET hunger = 100 WHERE animalid = ?', {animalid})
    end)
    
    if updateSuccess and updateError and updateError > 0 then
        Player.Functions.RemoveItem(Config.FeedItem, 1)
        if RSGCore.Shared.Items[Config.FeedItem] then
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.FeedItem], 'remove', 1)
        end
        TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'Animal has been fed!'})
        
        -- Send immediate update to client
        TriggerClientEvent('rex-ranch:client:refreshSingleAnimal', src, animalid, {hunger = 100})
        
        TriggerEvent('rex-ranch:server:refreshAnimals')
        if Config.Debug then
            print('^2[DEBUG]^7 Player ' .. src .. ' successfully fed animal ' .. animalid .. ' (updated ' .. updateError .. ' rows)')
        end
    else
        if Config.Debug then
            print('^1[ERROR]^7 Failed to update hunger for animal ' .. animalid .. ' - Success: ' .. tostring(updateSuccess) .. ', Rows affected: ' .. tostring(updateError))
        end
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Failed to feed animal! Please try again.'})
    end
end)

---------------------------------------------
-- water animal system
---------------------------------------------
RegisterNetEvent('rex-ranch:server:waterAnimal', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    -- Handle both string and object parameters for backwards compatibility
    local animalid
    if type(data) == 'table' and data.animalid then
        animalid = data.animalid
    elseif type(data) == 'string' or type(data) == 'number' then
        animalid = tostring(data)
    else
        animalid = nil
    end
    
    if not Player or not animalid then return end
    
    -- Check if player has water bucket in inventory
    local hasWater = Player.Functions.GetItemByName(Config.WaterItem)
    if not hasWater or hasWater.amount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You need a ' .. Config.WaterItem .. ' to water the animals!'})
        return
    end
    
    -- First verify animal exists and get current stats for debugging
    local animalData = MySQL.query.await('SELECT animalid, thirst, health, hunger FROM rex_ranch_animals WHERE animalid = ?', {animalid})
    if not animalData or #animalData == 0 then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Animal not found!'})
        if Config.Debug then
            print('^1[DEBUG]^7 Player ' .. src .. ' tried to water non-existent animal ' .. animalid)
        end
        return
    end
    
    local animal = animalData[1]
    if Config.Debug then
        print('^3[DEBUG]^7 Watering animal ' .. animalid .. ' - Current thirst: ' .. (animal.thirst or 'null') .. ', health: ' .. (animal.health or 'null') .. ', hunger: ' .. (animal.hunger or 'null'))
    end
    
    -- Update animal thirst
    local updateSuccess, updateError = pcall(function()
        return MySQL.update.await('UPDATE rex_ranch_animals SET thirst = 100 WHERE animalid = ?', {animalid})
    end)
    
    if updateSuccess and updateError and updateError > 0 then
        Player.Functions.RemoveItem(Config.WaterItem, 1)
        if RSGCore.Shared.Items[Config.WaterItem] then
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.WaterItem], 'remove', 1)
        end
        TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'Animal has been watered!'})
        
        -- Send immediate update to client
        TriggerClientEvent('rex-ranch:client:refreshSingleAnimal', src, animalid, {thirst = 100})
        
        TriggerEvent('rex-ranch:server:refreshAnimals')
        if Config.Debug then
            print('^2[DEBUG]^7 Player ' .. src .. ' successfully watered animal ' .. animalid .. ' (updated ' .. updateError .. ' rows)')
        end
    else
        if Config.Debug then
            print('^1[ERROR]^7 Failed to update thirst for animal ' .. animalid .. ' - Success: ' .. tostring(updateSuccess) .. ', Rows affected: ' .. tostring(updateError))
        end
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Failed to water animal! Please try again.'})
    end
end)

---------------------------------------------
-- collect animal product system
---------------------------------------------
RegisterNetEvent('rex-ranch:server:collectProduct', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    -- Handle both string and object parameters for backwards compatibility
    local animalid
    if type(data) == 'table' and data.animalid then
        animalid = data.animalid
    elseif type(data) == 'string' or type(data) == 'number' then
        animalid = tostring(data)
    else
        animalid = nil
    end
    
    if not Player or not animalid then
        if Config.Debug then
            print('^1[COLLECT ERROR]^7 Missing player or animalid - Player: ' .. tostring(Player) .. ', AnimalID: ' .. tostring(animalid))
        end
        return
    end
    
    -- Get animal data with comprehensive error handling
    local success, errorMsg = pcall(function()
        MySQL.query('SELECT model, product_ready, health, hunger, thirst FROM rex_ranch_animals WHERE animalid = ?', {animalid}, function(result)
            if not result or #result == 0 then
                TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Animal not found!'})
                if Config.Debug then
                    print('^1[COLLECT ERROR]^7 Animal ' .. animalid .. ' not found in database')
                end
                return
            end
        
        local animal = result[1]
        
        if Config.Debug then
            print('^3[COLLECT DEBUG]^7 Animal ' .. animalid .. ' collection attempt - product_ready: ' .. tostring(animal.product_ready))
        end
        
        if not animal.product_ready or animal.product_ready == 0 then
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'No product ready to collect!'})
            if Config.Debug then
                print('^3[COLLECT DEBUG]^7 Animal ' .. animalid .. ' has no product ready (product_ready: ' .. tostring(animal.product_ready) .. ')')
            end
            return
        end
        
        -- Get product config
        local productConfig = Config.AnimalProducts[animal.model]
        if not productConfig then
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'This animal does not produce anything!'})
            if Config.Debug then
                print('^1[COLLECT ERROR]^7 No product config found for animal model: ' .. tostring(animal.model))
            end
            return
        end
        
        if Config.Debug then
            print('^3[COLLECT DEBUG]^7 Attempting to give player ' .. src .. ' ' .. productConfig.amount .. 'x ' .. productConfig.product)
        end
        
        -- Give product to player with error handling
        local itemAdded = Player.Functions.AddItem(productConfig.product, productConfig.amount)
        if itemAdded then
            if RSGCore.Shared.Items[productConfig.product] then
                TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[productConfig.product], 'add', productConfig.amount)
            end
            
            -- Reset product ready status with proper error handling
            local resetSuccess, resetError = pcall(function()
                return MySQL.update.await('UPDATE rex_ranch_animals SET product_ready = 0 WHERE animalid = ?', {animalid})
            end)
            
            if resetSuccess and resetError and resetError > 0 then
                TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'Collected ' .. productConfig.amount .. ' ' .. productConfig.product .. '!'})
                
                -- Update client cache immediately
                TriggerClientEvent('rex-ranch:client:refreshSingleAnimal', src, animalid, {product_ready = 0})
                
                -- Trigger full refresh to update all clients
                TriggerEvent('rex-ranch:server:refreshAnimals')
                
                if Config.Debug then
                    print('^2[COLLECT SUCCESS]^7 Player ' .. src .. ' successfully collected ' .. productConfig.amount .. 'x ' .. productConfig.product .. ' from animal ' .. animalid)
                end
            else
                if Config.Debug then
                    print('^1[COLLECT ERROR]^7 Failed to reset product_ready status for animal ' .. animalid .. ' - Success: ' .. tostring(resetSuccess) .. ', Result: ' .. tostring(resetError))
                end
                TriggerClientEvent('ox_lib:notify', src, {type = 'warning', description = 'Product collected but status update failed!'})
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Failed to add item to inventory!'})
            if Config.Debug then
                print('^1[COLLECT ERROR]^7 Failed to add ' .. productConfig.product .. ' to player ' .. src .. ' inventory')
            end
        end
        end)
    end)
    
    if not success then
        print('^1[ERROR]^7 Database error in collectProduct: ' .. tostring(errorMsg))
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Database error occurred!'})
    end
end)

---------------------------------------------
-- get animal breeding status
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-ranch:server:getAnimalBreedingStatus', function(src, cb, animalid)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not animalid then 
        cb(false)
        return 
    end
    
    MySQL.query('SELECT breeding_ready_time, pregnant, gestation_end_time, gender, age, health, hunger, thirst FROM rex_ranch_animals WHERE animalid = ?', {animalid}, function(result)
        if not result or #result == 0 then
            cb(false)
            return
        end
        
        local animal = result[1]
        local currentTime = os.time()
        local breedingStatus = {
            canBreed = true,
            cooldownActive = false,
            cooldownHours = 0,
            isPregnant = animal.pregnant == 1,
            pregnancyDescription = '',
            breedingIssues = {}
        }
        
        -- Check breeding cooldown
        if animal.breeding_ready_time and animal.breeding_ready_time > currentTime then
            breedingStatus.canBreed = false
            breedingStatus.cooldownActive = true
            breedingStatus.cooldownHours = math.ceil((animal.breeding_ready_time - currentTime) / 3600)
            table.insert(breedingStatus.breedingIssues, 'Breeding cooldown: ' .. breedingStatus.cooldownHours .. 'h remaining')
        end
        
        -- Check pregnancy status
        if animal.pregnant == 1 and animal.gestation_end_time then
            local timeRemaining = animal.gestation_end_time - currentTime
            if timeRemaining > 0 then
                local hoursRemaining = math.floor(timeRemaining / 3600)
                local daysRemaining = math.floor(hoursRemaining / 24)
                local remainingHours = hoursRemaining % 24
                
                if daysRemaining > 0 then
                    breedingStatus.pregnancyDescription = 'Due in ' .. daysRemaining .. 'd ' .. remainingHours .. 'h'
                else
                    breedingStatus.pregnancyDescription = 'Due in ' .. hoursRemaining .. ' hours'
                end
            else
                breedingStatus.pregnancyDescription = 'Ready to give birth!'
            end
        end
        
        -- Check age requirements
        local animalAge = animal.age or 0
        if Config.MinAgeForBreeding and animalAge < Config.MinAgeForBreeding then
            breedingStatus.canBreed = false
            table.insert(breedingStatus.breedingIssues, 'Too young (need ' .. Config.MinAgeForBreeding .. ' days)')
        elseif Config.MaxBreedingAge and animalAge > Config.MaxBreedingAge then
            breedingStatus.canBreed = false
            table.insert(breedingStatus.breedingIssues, 'Too old (max ' .. Config.MaxBreedingAge .. ' days)')
        end
        
        -- Check health requirements
        if Config.RequireHealthForBreeding and (animal.health or 100) < Config.RequireHealthForBreeding then
            breedingStatus.canBreed = false
            table.insert(breedingStatus.breedingIssues, 'Health too low (need ' .. Config.RequireHealthForBreeding .. '%)')
        end
        
        if Config.RequireHungerForBreeding and (animal.hunger or 100) < Config.RequireHungerForBreeding then
            breedingStatus.canBreed = false
            table.insert(breedingStatus.breedingIssues, 'Hunger too low (need ' .. Config.RequireHungerForBreeding .. '%)')
        end
        
        if Config.RequireThirstForBreeding and (animal.thirst or 100) < Config.RequireThirstForBreeding then
            breedingStatus.canBreed = false
            table.insert(breedingStatus.breedingIssues, 'Thirst too low (need ' .. Config.RequireThirstForBreeding .. '%)')
        end
        
        cb(breedingStatus)
    end)
end)

---------------------------------------------
-- get pregnancy progress
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-ranch:server:getPregnancyProgress', function(src, cb, animalid)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not animalid then 
        cb({isPregnant = false})
        return 
    end
    
    MySQL.query('SELECT pregnant, gestation_end_time, born, model FROM rex_ranch_animals WHERE animalid = ?', {animalid}, function(result)
        if not result or #result == 0 then
            cb({isPregnant = false})
            return
        end
        
        local animal = result[1]
        
        -- Check if animal is actually pregnant
        if not (animal.pregnant == 1 or animal.pregnant == true) or not animal.gestation_end_time then
            cb({isPregnant = false})
            return
        end
        
        local currentTime = os.time()
        local gestationEndTime = animal.gestation_end_time
        
        -- Get gestation period from config
        local breedingConfig = Config.BreedingConfig[animal.model]
        if not breedingConfig then
            cb({isPregnant = false})
            return
        end
        
        local gestationPeriod = breedingConfig.gestationPeriod
        local gestationStartTime = gestationEndTime - gestationPeriod
        
        -- Calculate progress
        local timeElapsed = currentTime - gestationStartTime
        local progressPercent = math.max(0, math.min(100, (timeElapsed / gestationPeriod) * 100))
        
        -- Calculate time remaining
        local timeRemaining = gestationEndTime - currentTime
        local description = ''
        
        if timeRemaining > 0 then
            local hoursRemaining = math.floor(timeRemaining / 3600)
            local daysRemaining = math.floor(hoursRemaining / 24)
            local remainingHours = hoursRemaining % 24
            
            if daysRemaining > 0 then
                description = 'Due in ' .. daysRemaining .. 'd ' .. remainingHours .. 'h (' .. math.floor(progressPercent) .. '% complete)'
            else
                description = 'Due in ' .. hoursRemaining .. ' hours (' .. math.floor(progressPercent) .. '% complete)'
            end
        else
            description = 'Ready to give birth! (100% complete)'
            progressPercent = 100
        end
        
        cb({
            isPregnant = true,
            progressPercent = progressPercent,
            description = description,
            timeRemaining = timeRemaining,
            daysRemaining = math.floor(timeRemaining / (24 * 3600)),
            hoursRemaining = math.floor(timeRemaining / 3600)
        })
    end)
end)

---------------------------------------------
-- get animal production status
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-ranch:server:getAnimalProductionStatus', function(src, cb, animalid)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not animalid then 
        cb(false)
        return 
    end
    
    MySQL.query('SELECT model, product_ready, last_production, born, health, hunger, thirst FROM rex_ranch_animals WHERE animalid = ?', {animalid}, function(result)
        if not result or #result == 0 then
            cb(false)
            return
        end
        
        local animal = result[1]
        local productConfig = Config.AnimalProducts[animal.model]
        if not productConfig then
            cb(false)
            return
        end
        
        local currentTime = os.time()
        local animalAge = math.floor((currentTime - animal.born) / (24 * 60 * 60))
        local lastProduction = animal.last_production or 0
        local timeUntilNext = math.max(0, productConfig.productionTime - (currentTime - lastProduction))
        
        -- Check if animal meets production requirements
        local canProduce = animalAge >= Config.MinAgeForProduction and
            (animal.health or 100) >= productConfig.requiresHealth and
            (animal.hunger or 100) >= productConfig.requiresHunger and
            (animal.thirst or 100) >= productConfig.requiresThirst
            
        -- Handle different data types for product_ready (boolean, integer, string)
        local hasProduct = false
        if animal.product_ready == 1 or animal.product_ready == '1' or animal.product_ready == true or animal.product_ready == 'true' then
            hasProduct = true
        end
        
        local responseData = {
            hasProduct = hasProduct,
            productName = productConfig.product,
            productAmount = productConfig.amount,
            canProduce = canProduce,
            timeUntilNext = timeUntilNext,
            animalModel = animal.model
        }
        
        if Config.Debug then
            print('^3[SERVER PRODUCTION DEBUG]^7 getAnimalProductionStatus callback for animal ' .. animalid .. ':')
            print('^3[SERVER PRODUCTION DEBUG]^7 - animalAge: ' .. animalAge .. ' (min: ' .. Config.MinAgeForProduction .. ')')
            print('^3[SERVER PRODUCTION DEBUG]^7 - health: ' .. (animal.health or 100) .. '% (min: ' .. productConfig.requiresHealth .. '%)')
            print('^3[SERVER PRODUCTION DEBUG]^7 - hunger: ' .. (animal.hunger or 100) .. '% (min: ' .. productConfig.requiresHunger .. '%)')
            print('^3[SERVER PRODUCTION DEBUG]^7 - thirst: ' .. (animal.thirst or 100) .. '% (min: ' .. productConfig.requiresThirst .. '%)')
            print('^3[SERVER PRODUCTION DEBUG]^7 - product_ready: ' .. tostring(animal.product_ready))
            print('^3[SERVER PRODUCTION DEBUG]^7 - last_production: ' .. (animal.last_production or 0))
            print('^3[SERVER PRODUCTION DEBUG]^7 - timeUntilNext: ' .. timeUntilNext)
            print('^3[SERVER PRODUCTION DEBUG]^7 - canProduce: ' .. tostring(canProduce))
            print('^3[SERVER PRODUCTION DEBUG]^7 - hasProduct: ' .. tostring(responseData.hasProduct))
        end
        
        cb(responseData)
    end)
end)

---------------------------------------------
-- animal cron functions
---------------------------------------------
-- Initialize cron job with better error handling
CreateThread(function()
    -- Wait for server to be fully loaded
    Wait(5000)
    
    if not lib or not lib.cron then
        print('^1[REX-RANCH ERROR]^7 ox_lib cron not available! Make sure ox_lib is started before rex-ranch.')
        return
    end
    
    print('^2[REX-RANCH]^7 Initializing animal survival cronjob with schedule: ' .. Config.AnimalCronJob)
    
    lib.cron.new(Config.AnimalCronJob, function ()
        if Config.Debug then
            print('^2[REX-RANCH CRON]^7 Starting animal update cycle at ' .. os.date('%Y-%m-%d %H:%M:%S'))
        end
        
        -- Run in separate thread to avoid blocking cron
        CreateThread(function()
            ProcessAnimalSurvival()
        end)
    end)
end)

---------------------------------------------
-- Cronjob heartbeat monitoring
---------------------------------------------
local lastCronRun = 0
local cronFailures = 0
local MAX_FAILURES = 3 -- Threshold for critical alerts or recovery actions

CreateThread(function()
    while true do
        Wait(300000) -- Check every 5 minutes
        local currentTime = os.time()
        local timeSinceLastRun = currentTime - lastCronRun
        
        -- Determine expected interval based on cron configuration
        local expectedInterval = 15 -- Default for testing (15 seconds)
        if Config.AnimalCronJob == '*/15 * * * *' then
            expectedInterval = 900 -- 15 minutes for production
        elseif Config.AnimalCronJob == '0 * * * *' then
            expectedInterval = 3600 -- 1 hour for production
        end
        
        -- Check for missed runs
        if lastCronRun > 0 and timeSinceLastRun > (expectedInterval * 2) then
            cronFailures = cronFailures + 1
            print('^1[REX-RANCH WARNING]^7 Animal survival cronjob has not run in ' .. math.floor(timeSinceLastRun / 60) .. ' minutes!')
            print('^1[REX-RANCH WARNING]^7 Last successful run: ' .. os.date('%Y-%m-%d %H:%M:%S', lastCronRun))
            print('^1[REX-RANCH WARNING]^7 Use /testanimalsurvival to manually trigger survival logic')
            
            -- Optional: Trigger critical alert or recovery after repeated failures
            if cronFailures >= MAX_FAILURES then
                print('^1[REX-RANCH CRITICAL]^7 Cronjob has failed ' .. cronFailures .. ' times! Consider restarting the system or notifying an admin.')
                -- Example: Trigger a server event or notification
                -- TriggerEvent('rex-ranch:notifyAdmins', 'Animal survival cronjob failure detected!')
            end
        else
            cronFailures = 0 -- Reset failure count if cronjob is running as expected
        end
    end
end)

---------------------------------------------
-- Non-blocking animal survival processing
---------------------------------------------
function ProcessAnimalSurvival()
    lastCronRun = os.time() -- Update heartbeat
    
    local success, cronError = pcall(function()
        MySQL.query('SELECT animalid, model, born, health, thirst, hunger, last_production, product_ready, gender, pregnant, gestation_end_time, ranchid, pos_x, pos_y, pos_z, pos_w FROM rex_ranch_animals', {}, function(animals)
            if not animals or #animals == 0 then
                if Config.Debug then
                    print('^3[REX-RANCH CRON]^7 No animals found in database or query returned empty')
                end
                return
            end
            
            if Config.Debug then
                print('^2[REX-RANCH CRON]^7 Processing ' .. #animals .. ' animals')
            end

        local scaleTable = {
            [0] = 0.50,
            [1] = 0.60,
            [2] = 0.70,
            [3] = 0.80,
            [4] = 0.90,
            [5] = 1.00
        }

        local animalsToRemove = {}
        local batchUpdates = {} -- Collect updates for batch processing

        for _, animal in ipairs(animals) do
            -- Comprehensive validation of animal data
            if not animal.animalid or not animal.born or not animal.pos_x or not animal.pos_y or not animal.pos_z then
                if Config.Debug then
                    print('^1[ERROR]^7 Invalid animal data: missing critical fields for animalid ' .. (animal.animalid or 'unknown'))
                    print('^1[ERROR]^7 Fields: born=' .. tostring(animal.born) .. ', pos_x=' .. tostring(animal.pos_x) .. ', pos_y=' .. tostring(animal.pos_y) .. ', pos_z=' .. tostring(animal.pos_z))
                end
                goto continue
            end

            local animalAge = math.floor((os.time() - animal.born) / (24 * 60 * 60))
            if animalAge < 0 then
                if Config.Debug then
                    print('^1[ERROR]^7 Invalid birth date for animalid ' .. animal.animalid)
                end
                goto continue
            end

            -- Prepare batch update data instead of individual queries
            local scale = scaleTable[math.min(animalAge, 5)] or 1.00
            
            -- Check for breeding/pregnancy events if enabled
            if Config.BreedingEnabled and animal.pregnant == 1 and animal.gestation_end_time then
                local currentTime = os.time()
                
                -- Check if gestation period is complete
                if currentTime >= animal.gestation_end_time then
                    local breedingConfig = Config.BreedingConfig[animal.model]
                    if breedingConfig then
                        local success, breedingError = pcall(function()
                        -- Determine number of offspring
                        local offspringCount = math.random(breedingConfig.offspringCount.min, breedingConfig.offspringCount.max)
                        
                        -- Spawn offspring near the mother
                        for i = 1, offspringCount do
                            local offspringId = CreateAnimalId()
                            if not offspringId then
                                print('^1[BREEDING ERROR]^7 Failed to generate offspring ID for mother ' .. animal.animalid)
                                goto skipOffspring
                            end
                            
                            local offspringGender = math.random() < 0.5 and 'male' or 'female'
                            
                            -- Validate parent position data
                            if not animal.pos_x or not animal.pos_y or not animal.pos_z or
                               type(animal.pos_x) ~= 'number' or type(animal.pos_y) ~= 'number' or type(animal.pos_z) ~= 'number' then
                                if Config.Debug then
                                    print('^1[BREEDING ERROR]^7 Invalid position data for mother ' .. animal.animalid)
                                    print('^1[BREEDING ERROR]^7 Position: x=' .. tostring(animal.pos_x) .. ', y=' .. tostring(animal.pos_y) .. ', z=' .. tostring(animal.pos_z))
                                end
                                goto skipOffspring
                            end
                            
                            -- Add some random variation to spawn position
                            local spawnVariation = 5.0
                            local randomX = animal.pos_x + math.random(-spawnVariation, spawnVariation)
                            local randomY = animal.pos_y + math.random(-spawnVariation, spawnVariation)
                            
                            -- Determine offspring model (for bull breeding, offspring should be cows)
                            local offspringModel = animal.model
                            if animal.model == 'a_c_bull_01' then
                                offspringModel = 'a_c_cow'  -- Bulls can't give birth, but if somehow they did, offspring would be cows
                            end
                            
                            -- Insert offspring into database with error handling (non-blocking)
                            MySQL.insert('INSERT INTO rex_ranch_animals (ranchid, animalid, model, pos_x, pos_y, pos_z, pos_w, health, hunger, thirst, scale, age, born, gender, pregnant, breeding_ready_time, mother_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                                animal.ranchid,
                                offspringId,
                                offspringModel,
                                randomX,
                                randomY,
                                animal.pos_z,
                                animal.pos_w or 0,
                                100, -- health
                                100, -- hunger
                                100, -- thirst
                                0.5, -- scale (young animal)
                                0,   -- age
                                currentTime, -- born
                                offspringGender,
                                0,   -- not pregnant
                                0,   -- can breed when old enough
                                animal.animalid -- mother_id
                            }, function(insertResult)
                                -- insertResult can be a table with insertId or a number
                                local success = false
                                if type(insertResult) == 'table' then
                                    success = insertResult.insertId ~= nil or insertResult.affectedRows > 0
                                elseif type(insertResult) == 'number' then
                                    success = insertResult > 0
                                end
                                
                                if not success then
                                    if Config.Debug then
                                        print('^1[BREEDING ERROR]^7 Failed to insert offspring ' .. offspringId .. ' for mother ' .. animal.animalid)
                                    end
                                else
                                    if Config.Debug then
                                        print('^2[BREEDING SUCCESS]^7 Successfully inserted offspring ' .. offspringId .. ' for mother ' .. animal.animalid)
                                    end
                                end
                            end)
                            
                            ::skipOffspring::
                        end
                        
                        -- Reset mother's pregnancy status
                        MySQL.update('UPDATE rex_ranch_animals SET pregnant = 0, gestation_end_time = NULL WHERE animalid = ?', {animal.animalid}, function(updateResult)
                            -- updateResult can be a table with affectedRows or a number
                            local rowsAffected = 0
                            if type(updateResult) == 'table' then
                                rowsAffected = updateResult.affectedRows or updateResult.changedRows or 0
                            elseif type(updateResult) == 'number' then
                                rowsAffected = updateResult
                            end
                            
                            if rowsAffected > 0 then
                                -- Update client-side pregnancy data
                                if Config.UpdateClientsOnCron then
                                    TriggerClientEvent('rex-ranch:client:refreshSingleAnimal', -1, animal.animalid, {
                                        pregnant = 0,
                                        gestation_end_time = nil
                                    })
                                end
                            end
                        end)
                        
                        if Config.Debug then
                            print('^2[BREEDING]^7 Animal ' .. animal.animalid .. ' gave birth to ' .. offspringCount .. ' offspring')
                        end
                        
                        if Config.ServerNotify then
                            print('^2[REX-RANCH BREEDING]^7 ' .. offspringCount .. ' new ' .. animal.model .. '(s) born at ranch ' .. animal.ranchid)
                        end
                        
                        -- Refresh animals after breeding to show new offspring
                        SetTimeout(2000, function()
                            TriggerEvent('rex-ranch:server:refreshAnimals')
                        end)
                        end)
                        
                        if not success then
                            if Config.Debug then
                                print('^1[BREEDING ERROR]^7 Error during offspring creation for animal ' .. animal.animalid .. ': ' .. tostring(breedingError))
                            end
                        end
                    end
                end
            end
            
            -- Check for production if enabled
            if Config.ProductionEnabled and Config.AnimalProducts[animal.model] then
                local productConfig = Config.AnimalProducts[animal.model]
                local currentTime = os.time()
                local lastProduction = animal.last_production or 0
                
                -- Check if animal is old enough and meets requirements
                if animalAge >= Config.MinAgeForProduction and
                   (animal.health or 100) >= productConfig.requiresHealth and
                   (animal.hunger or 100) >= productConfig.requiresHunger and
                   (animal.thirst or 100) >= productConfig.requiresThirst then
                    
                    -- Check if enough time has passed for production
                    if (currentTime - lastProduction) >= productConfig.productionTime then
                        if Config.Debug then
                            print('^3[PRODUCTION DEBUG]^7 Animal ' .. animal.animalid .. ' meets production requirements:')
                            print('^3[PRODUCTION DEBUG]^7 Age: ' .. animalAge .. ' (min: ' .. Config.MinAgeForProduction .. ')')
                            print('^3[PRODUCTION DEBUG]^7 Health: ' .. (animal.health or 100) .. '% (min: ' .. productConfig.requiresHealth .. '%)')
                            print('^3[PRODUCTION DEBUG]^7 Hunger: ' .. (animal.hunger or 100) .. '% (min: ' .. productConfig.requiresHunger .. '%)')
                            print('^3[PRODUCTION DEBUG]^7 Thirst: ' .. (animal.thirst or 100) .. '% (min: ' .. productConfig.requiresThirst .. '%)')
                            print('^3[PRODUCTION DEBUG]^7 Time since last production: ' .. (currentTime - lastProduction) .. 's (required: ' .. productConfig.productionTime .. 's)')
                        end
                        
                        -- Use a more reliable update with better error handling
                        local success, updateError = pcall(function()
                            return MySQL.update.await('UPDATE rex_ranch_animals SET last_production = ?, product_ready = 1 WHERE animalid = ?', {
                                currentTime, animal.animalid
                            })
                        end)
                        
                        if success and updateError and updateError > 0 then
                            if Config.Debug then
                                print('^2[PRODUCTION SUCCESS]^7 Animal ' .. animal.animalid .. ' (' .. animal.model .. ') produced ' .. productConfig.product .. ' (ready for collection)')
                            end
                            
                            -- Update client-side production data immediately
                            if Config.UpdateClientsOnCron then
                                TriggerClientEvent('rex-ranch:client:refreshSingleAnimal', -1, animal.animalid, {
                                    last_production = currentTime,
                                    product_ready = 1
                                })
                            end
                            
                            if Config.ServerNotify then
                                print('^2[REX-RANCH PRODUCTION]^7 ' .. productConfig.product .. ' ready for collection from animal ' .. animal.animalid .. ' at ranch ' .. animal.ranchid)
                            end
                        else
                            if Config.Debug then
                                print('^1[PRODUCTION ERROR]^7 Failed to update production status for animal ' .. animal.animalid .. ' - Success: ' .. tostring(success) .. ', Result: ' .. tostring(updateError))
                            end
                        end
                    else
                        if Config.Debug then
                            local remainingTime = productConfig.productionTime - (currentTime - lastProduction)
                            print('^3[PRODUCTION DEBUG]^7 Animal ' .. animal.animalid .. ' not ready for production. Time remaining: ' .. remainingTime .. 's')
                        end
                    end
                else
                    if Config.Debug then
                        local issues = {}
                        if animalAge < Config.MinAgeForProduction then
                            table.insert(issues, 'Too young (' .. animalAge .. 'd, need ' .. Config.MinAgeForProduction .. 'd)')
                        end
                        if (animal.health or 100) < productConfig.requiresHealth then
                            table.insert(issues, 'Low health (' .. (animal.health or 100) .. '%, need ' .. productConfig.requiresHealth .. '%)')
                        end
                        if (animal.hunger or 100) < productConfig.requiresHunger then
                            table.insert(issues, 'Low hunger (' .. (animal.hunger or 100) .. '%, need ' .. productConfig.requiresHunger .. '%)')
                        end
                        if (animal.thirst or 100) < productConfig.requiresThirst then
                            table.insert(issues, 'Low thirst (' .. (animal.thirst or 100) .. '%, need ' .. productConfig.requiresThirst .. '%)')
                        end
                        
                        if #issues > 0 then
                            print('^3[PRODUCTION DEBUG]^7 Animal ' .. animal.animalid .. ' cannot produce: ' .. table.concat(issues, ', '))
                        end
                    end
                end
            end
            
            -- Reduce hunger and thirst
            local newHunger = math.max(0, (animal.hunger or 100) - Config.HungerDecayRate)
            local newThirst = math.max(0, (animal.thirst or 100) - Config.ThirstDecayRate)
            local currentHealth = animal.health or 100
            local newHealth = currentHealth
            
            -- Check if animal is starving or dehydrated
            if newHunger <= Config.MinSurvivalStats or newThirst <= Config.MinSurvivalStats then
                newHealth = math.max(0, currentHealth - Config.HealthDecayRate)
                if Config.Debug then
                    print('^3[DEBUG]^7 Animal ' .. animal.animalid .. ' is starving/dehydrated. Health: ' .. newHealth)
                end
            end
            
            -- Mark animal for removal if health reaches zero
            if newHealth <= 0 then
                table.insert(animalsToRemove, animal.animalid)
                if Config.ServerNotify then
                    print('^1[REX-RANCH]^7 Animal ' .. animal.animalid .. ' has died and will be removed from the database.')
                end
            else
                -- Collect updates for batch processing including scale and age
                table.insert(batchUpdates, {
                    animalid = animal.animalid,
                    hunger = newHunger,
                    thirst = newThirst,
                    health = newHealth,
                    scale = scale,
                    age = animalAge
                })
                if Config.Debug then
                    print('^2[DEBUG]^7 Prepared update for animal ' .. animal.animalid .. ' - Hunger: ' .. newHunger .. ', Thirst: ' .. newThirst .. ', Health: ' .. newHealth)
                end
            end
            
            ::continue::
        end
        
        -- Process batch updates for living animals using individual updates for reliability
        if #batchUpdates > 0 then
            local updateSuccess = 0
            local updateFailed = 0
            
            for _, update in ipairs(batchUpdates) do
                -- Validate update data
                if not update.animalid then
                    if Config.Debug then
                        print('^1[ERROR]^7 Skipping update with missing animalid')
                    end
                    updateFailed = updateFailed + 1
                    goto continue_update
                end
                
                -- Use individual updates for better reliability (non-blocking)
                MySQL.update('UPDATE rex_ranch_animals SET hunger = ?, thirst = ?, health = ?, scale = ?, age = ? WHERE animalid = ?', {
                    update.hunger or 0,
                    update.thirst or 0,
                    update.health or 0,
                    update.scale or 1.00,
                    update.age or 0,
                    update.animalid
                }, function(result)
                    -- result can be a table with affectedRows or a number
                    local rowsAffected = 0
                    if type(result) == 'table' then
                        rowsAffected = result.affectedRows or result.changedRows or 0
                    elseif type(result) == 'number' then
                        rowsAffected = result
                    end
                    
                    if rowsAffected > 0 then
                        updateSuccess = updateSuccess + 1
                        if Config.Debug then
                            print('^2[DEBUG]^7 Updated animal ' .. update.animalid .. ' - Hunger: ' .. (update.hunger or 0) .. ', Thirst: ' .. (update.thirst or 0) .. ', Health: ' .. (update.health or 0) .. ', Age: ' .. (update.age or 0) .. ' days')
                        end
                        
                        -- Update client-side data for this specific animal
                        if Config.UpdateClientsOnCron then
                            TriggerClientEvent('rex-ranch:client:refreshSingleAnimal', -1, update.animalid, {
                                hunger = update.hunger,
                                thirst = update.thirst,
                                health = update.health,
                                scale = update.scale,
                                age = update.age
                            })
                        end
                    else
                        updateFailed = updateFailed + 1
                        if Config.Debug then
                            print('^1[ERROR]^7 Update returned 0 rows affected for animal ' .. update.animalid)
                        end
                    end
                end)
                
                ::continue_update::
            end
            
            if Config.Debug then
                print('^2[DEBUG]^7 Processed ' .. #batchUpdates .. ' animal updates: ' .. updateSuccess .. ' successful, ' .. updateFailed .. ' failed')
            end
        end
        
        -- Clean up expired breeding cooldowns (separate simple query)
        local currentTime = os.time()
        MySQL.execute('UPDATE rex_ranch_animals SET breeding_ready_time = 0 WHERE breeding_ready_time > 0 AND breeding_ready_time <= ?', {currentTime})
        
        -- Remove dead animals from database and client
        if #animalsToRemove > 0 then
            if Config.Debug then
                print('^1[REX-RANCH]^7 Removing ' .. #animalsToRemove .. ' dead animals from database and game world')
                for _, id in ipairs(animalsToRemove) do
                    print('^1[REX-RANCH DEBUG]^7 Dead animal ID: ' .. tostring(id))
                end
            end
            
            -- Immediately remove animals from clients (don't wait for database)
            for _, animalid in ipairs(animalsToRemove) do
                if Config.Debug then
                    print('^1[REX-RANCH]^7 Immediately removing animal ' .. animalid .. ' from all clients')
                end
                TriggerClientEvent('rex-ranch:client:removeAnimal', -1, animalid)
            end
            
            -- Then remove from database
            for _, animalid in ipairs(animalsToRemove) do
                MySQL.execute('DELETE FROM rex_ranch_animals WHERE animalid = ?', {animalid}, function(deleteResult)
                    -- deleteResult can be a table with affectedRows or a number
                    local rowsAffected = 0
                    if type(deleteResult) == 'table' then
                        rowsAffected = deleteResult.affectedRows or deleteResult.changedRows or 0
                    elseif type(deleteResult) == 'number' then
                        rowsAffected = deleteResult
                    end
                    
                    if rowsAffected > 0 then
                        if Config.Debug then
                            print('^2[REX-RANCH]^7 Successfully removed animal ' .. animalid .. ' from database')
                        end
                    else
                        if Config.Debug then
                            print('^1[REX-RANCH ERROR]^7 Failed to remove animal ' .. animalid .. ' from database')
                        end
                        -- If database removal fails, we should still keep the client removal
                        -- The animal is already gone from client, database cleanup can be retried
                    end
                end)
            end
            
            -- Refresh animals on client after removals (delayed)
            SetTimeout(1000, function()
                TriggerEvent('rex-ranch:server:refreshAnimals')
            end)
            
            if Config.ServerNotify then
                print('^1[REX-RANCH]^7 Removed ' .. #animalsToRemove .. ' dead animals from the game world')
            end
        end
        
        -- Print completion summary
        if Config.Debug then
            if #animalsToRemove > 0 then
                print('^2[REX-RANCH]^7 Animal survival check completed. ' .. #animals .. ' animals processed, ' .. #animalsToRemove .. ' animals died.')
            else
                print('^2[REX-RANCH]^7 Animal survival check completed. ' .. #animals .. ' animals updated.')
            end
            
            if #batchUpdates > 0 and Config.UpdateClientsOnCron then
                print('^2[REX-RANCH]^7 Updated client data for ' .. #batchUpdates .. ' animals')
            end
        end
        
        if Config.Debug then
            print('^2[REX-RANCH CRON]^7 Animal update cycle completed successfully')
        end
        
        -- Refresh all animal data on clients after cronjob completion
        -- This ensures any missed individual updates are caught
        if Config.RefreshAfterCron then
            SetTimeout(500, function()
                if Config.Debug then
                    print('^2[REX-RANCH CRON]^7 Refreshing all animal data on clients')
                end
                TriggerEvent('rex-ranch:server:refreshAnimals')
            end)
        end
    end) -- Close MySQL.query callback
    end) -- Close pcall function
    
    if not success then
        cronFailures = cronFailures + 1
        print('^1[REX-RANCH CRON ERROR]^7 Animal cron job failed (failure #' .. cronFailures .. '): ' .. tostring(cronError))
        
        -- If we have too many failures, something is seriously wrong
        if cronFailures >= 5 then
            print('^1[REX-RANCH CRITICAL]^7 Animal survival cronjob has failed ' .. cronFailures .. ' times!')
            print('^1[REX-RANCH CRITICAL]^7 This may indicate a database connection issue or resource conflict.')
        end
    else
        cronFailures = 0 -- Reset failure counter on success
    end
end

---------------------------------------------
-- Helper function to validate breeding requirements
---------------------------------------------
local function ValidateBreeding(animal1, animal2)
    if not Config.BreedingEnabled then
        return false, 'Breeding is disabled'
    end
    
    -- Check if animals are different
    if animal1.animalid == animal2.animalid then
        return false, 'Cannot breed animal with itself'
    end
    
    -- Check if animals are same model type (with special case for bull/cow breeding)
    local compatibleBreeding = false
    if animal1.model == animal2.model then
        compatibleBreeding = true
    elseif (animal1.model == 'a_c_bull_01' and animal2.model == 'a_c_cow') or (animal1.model == 'a_c_cow' and animal2.model == 'a_c_bull_01') then 
        compatibleBreeding = true
    end
    
    if not compatibleBreeding then
        return false, 'Animals must be the same species (or bull with cow)'
    end
    
    -- Check if breeding is enabled for this animal type
    if not Config.BreedingConfig[animal1.model] or not Config.BreedingConfig[animal1.model].enabled then
        return false, 'This animal type cannot breed'
    end
    
    -- Check if animals are different genders
    if animal1.gender == animal2.gender then
        return false, 'Animals must be different genders'
    end
    
    -- Check if animals are from same ranch
    if animal1.ranchid ~= animal2.ranchid then
        return false, 'Animals must be from the same ranch'
    end
    
    local currentTime = os.time()
    
    -- Check ages
    local age1 = math.floor((currentTime - animal1.born) / (24 * 60 * 60))
    local age2 = math.floor((currentTime - animal2.born) / (24 * 60 * 60))
    
    if age1 < Config.MinAgeForBreeding or age2 < Config.MinAgeForBreeding then
        return false, 'Animals must be at least ' .. Config.MinAgeForBreeding .. ' days old to breed'
    end
    
    if age1 > Config.MaxBreedingAge or age2 > Config.MaxBreedingAge then
        return false, 'Animals are too old to breed (max age: ' .. Config.MaxBreedingAge .. ' days)'
    end
    
    -- Check health requirements
    local health1 = animal1.health or 100
    local health2 = animal2.health or 100
    if health1 < Config.RequireHealthForBreeding or health2 < Config.RequireHealthForBreeding then
        return false, 'Animals need at least ' .. Config.RequireHealthForBreeding .. '% health to breed'
    end
    
    -- Check hunger requirements
    local hunger1 = animal1.hunger or 100
    local hunger2 = animal2.hunger or 100
    if hunger1 < Config.RequireHungerForBreeding or hunger2 < Config.RequireHungerForBreeding then
        return false, 'Animals need at least ' .. Config.RequireHungerForBreeding .. '% hunger to breed'
    end
    
    -- Check thirst requirements
    local thirst1 = animal1.thirst or 100
    local thirst2 = animal2.thirst or 100
    if thirst1 < Config.RequireThirstForBreeding or thirst2 < Config.RequireThirstForBreeding then
        return false, 'Animals need at least ' .. Config.RequireThirstForBreeding .. '% thirst to breed'
    end
    
    -- Check breeding cooldown
    if animal1.breeding_ready_time and animal1.breeding_ready_time > currentTime then
        local waitTime = math.ceil((animal1.breeding_ready_time - currentTime) / 3600)
        return false, 'First animal must wait ' .. waitTime .. ' hours before breeding again'
    end
    
    if animal2.breeding_ready_time and animal2.breeding_ready_time > currentTime then
        local waitTime = math.ceil((animal2.breeding_ready_time - currentTime) / 3600)
        return false, 'Second animal must wait ' .. waitTime .. ' hours before breeding again'
    end
    
    -- Check if female is already pregnant and ensure bulls can't be pregnant
    local female = animal1.gender == 'female' and animal1 or animal2
    local male = animal1.gender == 'male' and animal1 or animal2
    
    -- Bulls cannot get pregnant
    if male.model == 'a_c_bull_01' and male.pregnant and male.pregnant == 1 then
        return false, 'Bulls cannot be pregnant - database error detected'
    end
    
    if female.pregnant and female.pregnant == 1 then
        return false, 'Female is already pregnant'
    end
    
    -- Check breeding season (optional)
    local breedingConfig = Config.BreedingConfig[animal1.model]
    if breedingConfig.breedingSeasonStart ~= breedingConfig.breedingSeasonEnd then
        local dayOfYear = tonumber(os.date('%j', currentTime))
        if dayOfYear < breedingConfig.breedingSeasonStart or dayOfYear > breedingConfig.breedingSeasonEnd then
            return false, 'Not in breeding season for this animal type'
        end
    end
    
    -- Check distance between animals with comprehensive validation
    if not animal1.pos_x or not animal1.pos_y or not animal1.pos_z or 
       not animal2.pos_x or not animal2.pos_y or not animal2.pos_z or
       type(animal1.pos_x) ~= 'number' or type(animal1.pos_y) ~= 'number' or type(animal1.pos_z) ~= 'number' or
       type(animal2.pos_x) ~= 'number' or type(animal2.pos_y) ~= 'number' or type(animal2.pos_z) ~= 'number' then
        return false, 'Invalid position data for one or both animals'
    end
    
    local distance = math.sqrt(
        (animal1.pos_x - animal2.pos_x)^2 + 
        (animal1.pos_y - animal2.pos_y)^2 + 
        (animal1.pos_z - animal2.pos_z)^2
    )
    
    if distance > Config.BreedingDistance then
        return false, 'Animals are too far apart (max distance: ' .. Config.BreedingDistance .. 'm)'
    end
    
    return true, 'All breeding requirements met'
end

---------------------------------------------
-- Function to perform automatic breeding checks
---------------------------------------------
local function CheckAutomaticBreeding()
    if not Config.AutomaticBreedingEnabled or not Config.BreedingEnabled then
        return
    end
    
    MySQL.query('SELECT * FROM rex_ranch_animals WHERE (pregnant = 0 OR pregnant IS NULL OR pregnant = false)', {}, function(animals)
        if not animals or #animals < 2 then
            return -- Need at least 2 animals to breed
        end
        
        -- Group animals by ranch and gender
        local animalsByRanch = {}
        for _, animal in ipairs(animals) do
            if not animalsByRanch[animal.ranchid] then
                animalsByRanch[animal.ranchid] = { males = {}, females = {} }
            end
            
            if animal.gender == 'male' then
                table.insert(animalsByRanch[animal.ranchid].males, animal)
            elseif animal.gender == 'female' then
                table.insert(animalsByRanch[animal.ranchid].females, animal)
            end
        end
        
        -- Check each ranch for potential breeding pairs
        for ranchid, ranchAnimals in pairs(animalsByRanch) do
            -- Check for a_c_bull_01 (male) and a_c_cow (female) pairings specifically
            for _, bull in ipairs(ranchAnimals.males) do
                if bull.model == 'a_c_bull_01' then
                    for _, cow in ipairs(ranchAnimals.females) do
                        if cow.model == 'a_c_cow' then
                            -- Check breeding compatibility and distance
                            local isValid, reason = ValidateBreeding(bull, cow)
                            
                            if isValid then
                                -- Check automatic breeding distance (shorter than manual)
                                local distance = math.sqrt(
                                    (bull.pos_x - cow.pos_x)^2 + 
                                    (bull.pos_y - cow.pos_y)^2 + 
                                    (bull.pos_z - cow.pos_z)^2
                                )
                                
                                if distance <= Config.AutomaticBreedingMaxDistance then
                                    -- Perform automatic breeding
                                    local currentTime = os.time()
                                    local breedingConfig = Config.BreedingConfig['a_c_cow'] -- Use cow config for offspring
                                    local gestationEndTime = currentTime + breedingConfig.gestationPeriod
                                    local nextBreedingTime = currentTime + Config.BreedingCooldown
                                    
                                    -- Set cow as pregnant
                                    local pregnancySuccess = MySQL.update.await('UPDATE rex_ranch_animals SET pregnant = 1, gestation_end_time = ? WHERE animalid = ?', 
                                        {gestationEndTime, cow.animalid})
                                    
                                    if pregnancySuccess and pregnancySuccess > 0 then
                                        -- Set breeding cooldown for both animals
                                        MySQL.update('UPDATE rex_ranch_animals SET breeding_ready_time = ?, breeding_attempts = breeding_attempts + 1 WHERE animalid IN (?, ?)', 
                                            {nextBreedingTime, bull.animalid, cow.animalid})
                                        
                                        if Config.AutomaticBreedingNotifications and Config.ServerNotify then
                                            local gestationDays = math.floor(breedingConfig.gestationPeriod / (24 * 60 * 60))
                                            print('^2[AUTOMATIC BREEDING]^7 Bull #' .. bull.animalid .. ' bred with Cow #' .. cow.animalid .. ' at ranch ' .. ranchid .. '. Offspring expected in ' .. gestationDays .. ' days.')
                                        end
                                        
                                        -- Send pregnancy notification to ranch owner if online
                                        if Config.AutomaticBreedingNotifications then
                                            local Players = RSGCore.Functions.GetPlayers()
                                            for _, playerId in pairs(Players) do
                                                local Player = RSGCore.Functions.GetPlayer(playerId)
                                                if Player and Player.PlayerData.job.name == ranchid then
                                                    TriggerClientEvent('ox_lib:notify', playerId, {
                                                        type = 'info',
                                                        title = 'Automatic Breeding',
                                                        description = 'Cow #' .. cow.animalid .. ' is now pregnant! (Auto-breeding)'
                                                    })
                                                end
                                            end
                                        end
                                        
                                        if Config.Debug then
                                            print('^2[AUTO BREEDING]^7 Successfully bred bull ' .. bull.animalid .. ' with cow ' .. cow.animalid .. ' at distance ' .. math.floor(distance * 10) / 10 .. 'm')
                                        end
                                        
                                        -- Only breed one pair per bull per check to avoid overwhelming
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            -- Also check for same-species breeding (cow with cow if there are males)
            for _, male in ipairs(ranchAnimals.males) do
                for _, female in ipairs(ranchAnimals.females) do
                    if male.model == female.model and male.model == 'a_c_cow' then
                        -- Check breeding compatibility and distance
                        local isValid, reason = ValidateBreeding(male, female)
                        
                        if isValid then
                            local distance = math.sqrt(
                                (male.pos_x - female.pos_x)^2 + 
                                (male.pos_y - female.pos_y)^2 + 
                                (male.pos_z - female.pos_z)^2
                            )
                            
                            if distance <= Config.AutomaticBreedingMaxDistance then
                                -- Perform automatic breeding
                                local currentTime = os.time()
                                local breedingConfig = Config.BreedingConfig[male.model]
                                local gestationEndTime = currentTime + breedingConfig.gestationPeriod
                                local nextBreedingTime = currentTime + Config.BreedingCooldown
                                
                                -- Set female as pregnant
                                local pregnancySuccess = MySQL.update.await('UPDATE rex_ranch_animals SET pregnant = 1, gestation_end_time = ? WHERE animalid = ?', 
                                    {gestationEndTime, female.animalid})
                                
                                if pregnancySuccess and pregnancySuccess > 0 then
                                    -- Set breeding cooldown for both animals
                                    MySQL.update('UPDATE rex_ranch_animals SET breeding_ready_time = ?, breeding_attempts = breeding_attempts + 1 WHERE animalid IN (?, ?)', 
                                        {nextBreedingTime, male.animalid, female.animalid})
                                    
                                    if Config.AutomaticBreedingNotifications and Config.ServerNotify then
                                        local gestationDays = math.floor(breedingConfig.gestationPeriod / (24 * 60 * 60))
                                        print('^2[AUTOMATIC BREEDING]^7 ' .. male.model .. ' #' .. male.animalid .. ' bred with #' .. female.animalid .. ' at ranch ' .. ranchid .. '. Offspring expected in ' .. gestationDays .. ' days.')
                                    end
                                    
                                    -- Send pregnancy notification to ranch owner if online
                                    if Config.AutomaticBreedingNotifications then
                                        local Players = RSGCore.Functions.GetPlayers()
                                        for _, playerId in pairs(Players) do
                                            local Player = RSGCore.Functions.GetPlayer(playerId)
                                            if Player and Player.PlayerData.job.name == ranchid then
                                                TriggerClientEvent('ox_lib:notify', playerId, {
                                                    type = 'info',
                                                    title = 'Automatic Breeding',
                                                    description = 'Female #' .. female.animalid .. ' is now pregnant! (Auto-breeding)'
                                                })
                                            end
                                        end
                                    end
                                    
                                    if Config.Debug then
                                        print('^2[AUTO BREEDING]^7 Successfully bred ' .. male.model .. ' ' .. male.animalid .. ' with ' .. female.animalid .. ' at distance ' .. math.floor(distance * 10) / 10 .. 'm')
                                    end
                                    
                                    -- Only breed one pair per male per check
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

---------------------------------------------
-- automatic breeding cron job
---------------------------------------------
-- Run automatic breeding checks based on config interval
CreateThread(function()
    while true do
        Wait(Config.AutomaticBreedingCheckInterval * 1000) -- Convert seconds to milliseconds
        if Config.AutomaticBreedingEnabled then
            CheckAutomaticBreeding()
        end
    end
end)

---------------------------------------------
-- animal selling system
---------------------------------------------

-- Helper function to calculate sale price based on age
local function CalculateSalePrice(animalModel, age)
    local basePrice = Config.BaseSellPrices[animalModel]
    if not basePrice then return 0 end
    
    local multiplier = 1.0
    
    if age < Config.PrimeAgeStart then
        multiplier = Config.AgePricing.young
    elseif age >= Config.PrimeAgeStart and age <= Config.PrimeAgeEnd then
        multiplier = Config.AgePricing.prime
    elseif age > Config.PrimeAgeEnd and age < Config.OldAgeStart then
        multiplier = Config.AgePricing.adult
    else -- age >= Config.OldAgeStart
        multiplier = Config.AgePricing.old
    end
    
    return math.floor(basePrice * multiplier)
end

-- Helper function to get age category name
local function GetAgeCategory(age)
    if age < Config.PrimeAgeStart then
        return 'Young'
    elseif age >= Config.PrimeAgeStart and age <= Config.PrimeAgeEnd then
        return 'Prime'
    elseif age > Config.PrimeAgeEnd and age < Config.OldAgeStart then
        return 'Adult'
    else
        return 'Old'
    end
end

---------------------------------------------
-- Get nearby animals available for sale at current sale point
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-ranch:server:getNearbyAnimalsForSale', function(src, cb, ranchid, salePointCoords)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not ranchid then 
        cb({})
        return 
    end
    
    -- If physical animal requirement is disabled, get all animals
    if not Config.RequireAnimalPresent then
        MySQL.query('SELECT animalid, model, age, health, hunger, thirst, born FROM rex_ranch_animals WHERE ranchid = ?', {ranchid}, function(result)
            if not result or #result == 0 then
                cb({})
                return
            end
            
            local animalsForSale = {}
            local currentTime = os.time()
            
            for _, animal in ipairs(result) do
                local actualAge = math.floor((currentTime - animal.born) / (24 * 60 * 60))
                
                if actualAge >= Config.MinAgeToSell then
                    local salePrice = CalculateSalePrice(animal.model, actualAge)
                    local ageCategory = GetAgeCategory(actualAge)
                    
                    table.insert(animalsForSale, {
                        animalid = animal.animalid,
                        model = animal.model,
                        age = actualAge,
                        ageCategory = ageCategory,
                        health = animal.health or 100,
                        hunger = animal.hunger or 100,
                        thirst = animal.thirst or 100,
                        salePrice = salePrice,
                        isNearby = true
                    })
                end
            end
            
            cb(animalsForSale)
        end)
        return
    end
    
    -- Get animals from database and check which ones are nearby
    MySQL.query('SELECT animalid, model, age, health, hunger, thirst, born, pos_x, pos_y, pos_z FROM rex_ranch_animals WHERE ranchid = ?', {ranchid}, function(result)
        if not result or #result == 0 then
            cb({})
            return
        end
        
        local animalsForSale = {}
        local currentTime = os.time()
        
        for _, animal in ipairs(result) do
            local actualAge = math.floor((currentTime - animal.born) / (24 * 60 * 60))
            
            if actualAge >= Config.MinAgeToSell then
                -- Check if animal is near the sale point
                local animalPos = vector3(animal.pos_x, animal.pos_y, animal.pos_z)
                local distance = #(salePointCoords - animalPos)
                local isNearby = distance <= Config.AnimalSaleDistance
                
                local salePrice = CalculateSalePrice(animal.model, actualAge)
                local ageCategory = GetAgeCategory(actualAge)
                
                table.insert(animalsForSale, {
                    animalid = animal.animalid,
                    model = animal.model,
                    age = actualAge,
                    ageCategory = ageCategory,
                    health = animal.health or 100,
                    hunger = animal.hunger or 100,
                    thirst = animal.thirst or 100,
                    salePrice = salePrice,
                    isNearby = isNearby,
                    distance = math.floor(distance * 10) / 10
                })
            end
        end
        
        cb(animalsForSale)
    end)
end)

---------------------------------------------
-- Sell animal
---------------------------------------------
RegisterNetEvent('rex-ranch:server:sellAnimal', function(animalid, expectedPrice, salePointCoords)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not animalid then return end
    
    -- Get animal data to verify it exists and calculate actual price
    MySQL.query('SELECT model, born, ranchid, pos_x, pos_y, pos_z FROM rex_ranch_animals WHERE animalid = ?', {animalid}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Animal not found!'})
            return
        end
        
        local animal = result[1]
        local currentTime = os.time()
        local actualAge = math.floor((currentTime - animal.born) / (24 * 60 * 60))
        local actualPrice = CalculateSalePrice(animal.model, actualAge)
        
        -- Verify the price matches (prevent client tampering)
        -- Use exact matching to prevent any price manipulation
        if actualPrice ~= expectedPrice then
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Price verification failed!'})
            if Config.Debug then
                print('^1[SECURITY]^7 Price tampering attempt by player ' .. src .. ': expected ' .. actualPrice .. ', got ' .. expectedPrice)
            end
            return
        end
        
        -- Check if player has access to this ranch's animals
        local PlayerData = Player.PlayerData
        if PlayerData.job.name ~= animal.ranchid then
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You can only sell animals from your own ranch!'})
            return
        end
        
        -- Check if animal is close enough to sale point (if proximity is required)
        if Config.RequireAnimalPresent and salePointCoords then
            local animalPos = vector3(animal.pos_x, animal.pos_y, animal.pos_z)
            local distance = #(salePointCoords - animalPos)
            
            if distance > Config.AnimalSaleDistance then
                TriggerClientEvent('ox_lib:notify', src, {
                    type = 'error', 
                    description = 'Animal is too far from sale point! Distance: ' .. math.floor(distance * 10) / 10 .. 'm (max: ' .. Config.AnimalSaleDistance .. 'm)'
                })
                return
            end
        end
        
        -- Remove animal from database
        MySQL.execute('DELETE FROM rex_ranch_animals WHERE animalid = ?', {animalid}, function(result)
            local affectedRows = result
            if type(result) == 'table' then
                affectedRows = result.affectedRows or 0
            end
            
            if affectedRows > 0 then
                -- Give money to player
                Player.Functions.AddMoney('cash', actualPrice)
                
                -- Get animal display name
                local animalName = 'Animal'
                if animal.model == 'a_c_cow' then
                    animalName = 'Cow'
                elseif animal.model == 'a_c_sheep_01' then
                    animalName = 'Sheep'
                elseif animal.model == 'a_c_pig_01' then
                    animalName = 'Pig'
                elseif animal.model == 'a_c_horse_americanpaint_greyovero' then
                    animalName = 'Horse'
                end
                
                local ageCategory = GetAgeCategory(actualAge)
                
                TriggerClientEvent('ox_lib:notify', src, {
                    type = 'success', 
                    description = 'Sold ' .. ageCategory .. ' ' .. animalName .. ' for $' .. actualPrice
                })
                
                -- Remove the specific animal entity immediately on all clients
                TriggerClientEvent('rex-ranch:client:removeAnimal', -1, animalid)
                
                -- Refresh animals on client
                TriggerEvent('rex-ranch:server:refreshAnimals')
                
                if Config.Debug then
                    print('^2[DEBUG]^7 Player ' .. src .. ' sold animal ' .. animalid .. ' (' .. animalName .. ', age: ' .. actualAge .. ') for $' .. actualPrice)
                end
            else
                TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Failed to sell animal!'})
            end
        end)
    end)
end)

---------------------------------------------
-- sell all animals at once
---------------------------------------------
RegisterNetEvent('rex-ranch:server:sellAllAnimals', function(animals, salePointCoords)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then
        return
    end
    
    if not animals or #animals == 0 then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'No animals to sell!'})
        return
    end
    
    local PlayerData = Player.PlayerData
    local playerjob = PlayerData.job.name
    local soldAnimals = 0
    local totalEarned = 0
    local failedSales = 0
    local animalCounts = {}
    local soldAnimalIds = {}
    
    -- Process each animal
    for i, animal in ipairs(animals) do
        if animal and animal.animalid then
            
            -- Get current animal data from database to verify it still exists and get current stats
            local success, result = pcall(function()
                return MySQL.query.await('SELECT model, born, ranchid, pos_x, pos_y, pos_z FROM rex_ranch_animals WHERE animalid = ?', {animal.animalid})
            end)
            
            if success and result and #result > 0 then
                local dbAnimal = result[1]
                
                -- Verify ownership
                if dbAnimal.ranchid == playerjob then
                    local currentTime = os.time()
                    local actualAge = math.floor((currentTime - dbAnimal.born) / (24 * 60 * 60))
                    local actualPrice = CalculateSalePrice(dbAnimal.model, actualAge)
                    
                    -- Check proximity if required
                    local canSell = true
                    if Config.RequireAnimalPresent and salePointCoords then
                        local animalPos = vector3(dbAnimal.pos_x, dbAnimal.pos_y, dbAnimal.pos_z)
                        local distance = #(salePointCoords - animalPos)
                        if distance > Config.AnimalSaleDistance then
                            canSell = false
                        end
                    end
                    
                    if canSell then
                        -- Remove from database
                        local deleteSuccess = MySQL.execute.await('DELETE FROM rex_ranch_animals WHERE animalid = ?', {animal.animalid})
                        
                        if deleteSuccess and deleteSuccess > 0 then
                            -- Add to totals
                            soldAnimals = soldAnimals + 1
                            totalEarned = totalEarned + actualPrice
                            table.insert(soldAnimalIds, animal.animalid)
                            
                            -- Count by type for summary
                            local animalName = 'Animal'
                            if dbAnimal.model == 'a_c_cow' then
                                animalName = 'Cow'
                            elseif dbAnimal.model == 'a_c_sheep_01' then
                                animalName = 'Sheep'
                            elseif dbAnimal.model == 'a_c_pig_01' then
                                animalName = 'Pig'
                            elseif dbAnimal.model == 'a_c_horse_americanpaint_greyovero' then
                                animalName = 'Horse'
                            end
                            animalCounts[animalName] = (animalCounts[animalName] or 0) + 1
                        else
                            failedSales = failedSales + 1
                        end
                    else
                        failedSales = failedSales + 1
                    end
                else
                    failedSales = failedSales + 1
                end
            else
                failedSales = failedSales + 1
            end
        else
            failedSales = failedSales + 1
        end
    end
    
    -- Give money to player
    if totalEarned > 0 then
        Player.Functions.AddMoney('cash', totalEarned)
    end
    
    -- Remove sold animal entities from all clients
    for _, animalid in ipairs(soldAnimalIds) do
        TriggerClientEvent('rex-ranch:client:removeAnimal', -1, animalid)
    end
    
    -- Refresh animals for all clients
    if #soldAnimalIds > 0 then
        TriggerEvent('rex-ranch:server:refreshAnimals')
    end
    
    -- Send result notification
    if soldAnimals > 0 then
        -- Build summary
        local summaryParts = {}
        for animalName, count in pairs(animalCounts) do
            if count == 1 then
                table.insert(summaryParts, '1 ' .. animalName)
            else
                table.insert(summaryParts, count .. ' ' .. animalName .. 's')
            end
        end
        local summary = table.concat(summaryParts, ', ')
        
        local message = 'Sold ' .. soldAnimals .. ' animals for $' .. totalEarned
        if failedSales > 0 then
            message = message .. ' (' .. failedSales .. ' failed)'
        end
        
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = message .. '\n' .. summary
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Failed to sell any animals! Check if they still exist and are close enough.'
        })
    end
end)

---------------------------------------------
-- buy animal from buy point
---------------------------------------------
RegisterNetEvent('rex-ranch:server:buyAnimal', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not data then return end

    -- Validate required fields
    if not data.animalType or not data.price or not data.ranchid or not data.spawnpoint then
        print('^1[BUY DEBUG]^7 Invalid animal purchase data from player ' .. src)
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Invalid purchase data!'})
        return
    end
    
    -- Validate animal model
    local validAnimals = {'a_c_cow', 'a_c_sheep_01', 'a_c_pig_01', 'a_c_horse_americanpaint_greyovero', 'a_c_bull_01'}
    local isValidAnimal = false
    for _, validAnimal in ipairs(validAnimals) do
        if data.animalType == validAnimal then
            isValidAnimal = true
            break
        end
    end
    if not isValidAnimal then
        print('^1[BUY SECURITY]^7 Invalid animal model from player ' .. src .. ': ' .. tostring(data.animalType))
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Invalid animal type!'})
        return
    end
    
    -- Check if player has the job for this ranch
    local PlayerData = Player.PlayerData
    if PlayerData.job.name ~= data.ranchid then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You can only buy animals for your own ranch!'})
        return
    end
    
    -- Check current animal count directly
    local success, result = pcall(function()
        return MySQL.query.await("SELECT COUNT(*) as count FROM rex_ranch_animals WHERE ranchid = ?", { data.ranchid })
    end)
    
    local animalCount = 0
    if success and result and result[1] then
        animalCount = result[1].count or 0
    end
    
    if animalCount >= Config.MaxRanchAnimals then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Your ranch is full! Maximum ' .. Config.MaxRanchAnimals .. ' animals allowed.'})
        return
    end
    
    -- Check if player has enough money
    local playerCash = Player.Functions.GetMoney('cash')
    if playerCash < data.price then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You need $' .. data.price .. ' but only have $' .. playerCash})
        return
    end
    
    -- All checks passed, process the purchase
    local animalid = CreateAnimalId()
    if not animalid then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Failed to generate animal ID. Please try again.'})
        return
    end
    local born = os.time()
    
    -- Add some random variation to spawn position to prevent animals spawning in same spot
    local spawnVariation = (Config.BuyPointSpawnDistance or 8.0) / 2
    local randomX = data.spawnpoint.x + math.random(-spawnVariation, spawnVariation)
    local randomY = data.spawnpoint.y + math.random(-spawnVariation, spawnVariation)
    
    -- Determine gender based on config ratios
    local gender = 'female' -- default
    if Config.GenderRatios and Config.GenderRatios[data.animalType] then
        local maleChance = Config.GenderRatios[data.animalType]
        if math.random() < maleChance then
            gender = 'male'
        end
    end
    
    -- Add animal to database with gender
    local dbSuccess, dbResult = pcall(function()
        return MySQL.insert.await('INSERT INTO rex_ranch_animals (ranchid, animalid, model, pos_x, pos_y, pos_z, pos_w, health, hunger, thirst, scale, age, born, gender, pregnant, breeding_ready_time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            data.ranchid,
            animalid,
            data.animalType,
            randomX,
            randomY,
            data.spawnpoint.z,
            data.spawnpoint.w,
            100, -- health
            100, -- hunger
            100, -- thirst
            0.5, -- scale (young animal)
            0,   -- age
            born,
            gender,
            0,   -- not pregnant
            0    -- can breed immediately when old enough
        })
    end)
    
    if dbSuccess and dbResult then
        -- Take money from player
        Player.Functions.RemoveMoney('cash', data.price)
        
        -- Send success notification
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = 'Purchased ' .. (data.animalName or 'animal') .. ' for $' .. data.price .. '!\nAnimal is ready for pickup near the ' .. (data.buyPointName or 'dealer') .. '.'
        })
        
        -- Refresh animals on client
        TriggerEvent('rex-ranch:server:refreshAnimals')
        
        if Config.Debug then
            print('^2[BUY DEBUG]^7 Player ' .. src .. ' bought ' .. data.animalType .. ' (ID: ' .. animalid .. ') for $' .. data.price .. ' at ' .. (data.buyPointName or 'unknown location'))
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Failed to add animal to ranch! Please try again.'})
        if Config.Debug then
            print('^1[BUY DEBUG]^7 Database error for player ' .. src .. ': ' .. tostring(dbResult))
        end
    end
end)

---------------------------------------------
-- herding system server events
---------------------------------------------
RegisterNetEvent('rex-ranch:server:startHerding', function(animalIds, herdType)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Log herding activity for debugging
    if Config.Debug then
        print('^2[REX-RANCH HERDING]^7 Player ' .. src .. ' started herding ' .. #animalIds .. ' animals (' .. herdType .. ' herding)')
    end
    
    -- Could add additional server-side validation or logging here
    -- For example: check if player has permission, log to database, etc.
end)

RegisterNetEvent('rex-ranch:server:stopHerding', function(animalIds)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Log herding completion for debugging
    if Config.Debug then
        print('^2[REX-RANCH HERDING]^7 Player ' .. src .. ' stopped herding ' .. #animalIds .. ' animals')
    end
    
    -- Could add additional cleanup or logging here
end)


---------------------------------------------
-- animal breeding system
---------------------------------------------

-- Get available animals for breeding
RSGCore.Functions.CreateCallback('rex-ranch:server:getAvailableAnimalsForBreeding', function(src, cb, ranchid, animalid)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not ranchid then 
        cb({})
        return 
    end
    
    -- Get the selected animal first
    local success, error = pcall(function()
        MySQL.query('SELECT * FROM rex_ranch_animals WHERE animalid = ? AND ranchid = ?', {animalid, ranchid}, function(selectedResult)
            if not selectedResult or #selectedResult == 0 then
                cb({})
                return
            end
        
        local selectedAnimal = selectedResult[1]
        
        -- Get animals from same ranch that can breed with the selected animal
        -- If selected is male, get females; if selected is female, get males
        local targetGender = selectedAnimal.gender == 'male' and 'female' or 'male'
        
        -- Support cross-breeding between bulls and cows
        local query = ''
        local params = {}
        
        if selectedAnimal.model == 'a_c_bull_01' then
            query = 'SELECT * FROM rex_ranch_animals WHERE ranchid = ? AND (model = ? OR model = ?) AND gender = ? AND animalid != ? AND (pregnant = 0 OR pregnant IS NULL OR pregnant = false)'
            params = {ranchid, selectedAnimal.model, 'a_c_cow', targetGender, animalid}
        elseif selectedAnimal.model == 'a_c_cow' then
            query = 'SELECT * FROM rex_ranch_animals WHERE ranchid = ? AND (model = ? OR model = ?) AND gender = ? AND animalid != ? AND (pregnant = 0 OR pregnant IS NULL OR pregnant = false)'
            params = {ranchid, selectedAnimal.model, 'a_c_bull_01', targetGender, animalid}
        else
            -- Same species breeding for other animals
            query = 'SELECT * FROM rex_ranch_animals WHERE ranchid = ? AND model = ? AND gender = ? AND animalid != ? AND (pregnant = 0 OR pregnant IS NULL OR pregnant = false)'
            params = {ranchid, selectedAnimal.model, targetGender, animalid}
        end
        
        MySQL.query(query, params, function(result)
            if not result or #result == 0 then
                cb({})
                return
            end
            
            local availableAnimals = {}
            local currentTime = os.time()
            
            for _, animal in ipairs(result) do
                local isValid, reason = ValidateBreeding(selectedAnimal, animal)
                local age = math.floor((currentTime - animal.born) / (24 * 60 * 60))
                local distance = math.sqrt(
                    (selectedAnimal.pos_x - animal.pos_x)^2 + 
                    (selectedAnimal.pos_y - animal.pos_y)^2 + 
                    (selectedAnimal.pos_z - animal.pos_z)^2
                )
                
                table.insert(availableAnimals, {
                    animalid = animal.animalid,
                    model = animal.model,
                    gender = animal.gender,
                    age = age,
                    health = animal.health or 100,
                    hunger = animal.hunger or 100,
                    thirst = animal.thirst or 100,
                    pregnant = animal.pregnant or 0,
                    distance = math.floor(distance * 10) / 10,
                    canBreed = isValid,
                    breedingIssue = not isValid and reason or nil
                })
            end
            
            cb(availableAnimals)
        end)
        end)
    end)
    
    if not success then
        if Config.Debug then
            print('^1[BREEDING ERROR]^7 Database error in getAvailableAnimalsForBreeding: ' .. tostring(error))
        end
        cb({})
    end
end)

-- Start breeding process
RegisterNetEvent('rex-ranch:server:startBreeding', function(animal1id, animal2id)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Get both animals from database
    MySQL.query('SELECT * FROM rex_ranch_animals WHERE animalid IN (?, ?)', {animal1id, animal2id}, function(result)
        if not result or #result ~= 2 then
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Animals not found!'})
            return
        end
        
        local animal1 = result[1]
        local animal2 = result[2]
        
        -- Ensure we have the right animals
        if animal1.animalid == animal2id then
            animal1, animal2 = animal2, animal1
        end
        
        -- Validate breeding
        local isValid, reason = ValidateBreeding(animal1, animal2)
        if not isValid then
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = reason})
            return
        end
        
        -- Check job access
        local PlayerData = Player.PlayerData
        if PlayerData.job.name ~= animal1.ranchid then
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You can only breed animals from your own ranch!'})
            return
        end
        
        -- Determine male and female
        local male = animal1.gender == 'male' and animal1 or animal2
        local female = animal1.gender == 'female' and animal1 or animal2
        
        -- Get breeding config (use cow config for bull/cow breeding)
        local breedingModel = animal1.model
        if (animal1.model == 'a_c_bull_01' and animal2.model == 'a_c_cow') or
           (animal1.model == 'a_c_cow' and animal2.model == 'a_c_bull_01') then
            breedingModel = 'a_c_cow'  -- Use cow breeding config and offspring will be cows
        end
        local breedingConfig = Config.BreedingConfig[breedingModel]
        local currentTime = os.time()
        local gestationEndTime = currentTime + breedingConfig.gestationPeriod
        local nextBreedingTime = currentTime + Config.BreedingCooldown
        
        -- Set female as pregnant first
        local pregnancySuccess = MySQL.update.await('UPDATE rex_ranch_animals SET pregnant = 1, gestation_end_time = ? WHERE animalid = ?', 
            {gestationEndTime, female.animalid})
        
        if pregnancySuccess and pregnancySuccess > 0 then
            -- Only set breeding cooldown if pregnancy was successful
            MySQL.update('UPDATE rex_ranch_animals SET breeding_ready_time = ?, breeding_attempts = breeding_attempts + 1 WHERE animalid IN (?, ?)', 
                {nextBreedingTime, male.animalid, female.animalid})
        
            -- Send success notification
            local animalName = 'animals'
            if animal1.model == 'a_c_cow' or animal1.model == 'a_c_bull_01' or 
               animal2.model == 'a_c_cow' or animal2.model == 'a_c_bull_01' then
                animalName = 'cattle'
            elseif animal1.model == 'a_c_sheep_01' then
                animalName = 'sheep'
            elseif animal1.model == 'a_c_pig_01' then
                animalName = 'pigs'
            elseif animal1.model == 'a_c_horse_americanpaint_greyovero' then
                animalName = 'horses'
            end
        
        local gestationDays = math.floor(breedingConfig.gestationPeriod / (24 * 60 * 60))
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = 'Breeding successful! Offspring expected in ' .. gestationDays .. ' days.'
        })
        
        -- Additional pregnancy notification
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'info',
            title = 'Animal Pregnant',
            description = 'Female animal #' .. female.animalid .. ' is now pregnant!'
        })
        
        -- Refresh animals on all clients
        TriggerEvent('rex-ranch:server:refreshAnimals')
        
        -- Also send immediate update to the breeding player for both animals
        TriggerClientEvent('rex-ranch:client:updateAnimalStatus', src, female.animalid, {
            pregnant = 1,
            gestation_end_time = gestationEndTime,
            breeding_ready_time = nextBreedingTime
        })
        TriggerClientEvent('rex-ranch:client:updateAnimalStatus', src, male.animalid, {
            breeding_ready_time = nextBreedingTime
        })
        
            if Config.Debug then
                print('^2[BREEDING]^7 Player ' .. src .. ' bred ' .. male.animalid .. ' (male) with ' .. female.animalid .. ' (female)')
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Breeding failed! Please try again.'})
            if Config.Debug then
                print('^1[BREEDING ERROR]^7 Failed to set pregnancy for animal ' .. female.animalid)
            end
        end
    end)
end)
