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
    local maxAttempts = 100 -- Prevent infinite loops
    local attempts = 0
    
    while not UniqueFound and attempts < maxAttempts do
        attempts = attempts + 1
        animalid = math.random(111111, 999999)
        
        local success, result = pcall(function()
            return MySQL.query.await("SELECT COUNT(*) as count FROM rex_ranch_animals WHERE animalid = ?", { animalid })
        end)
        
        if success and result and result[1] and result[1].count == 0 then
            UniqueFound = true
        elseif not success then
            print("^1[ERROR]^7 Database error in CreateAnimalId: " .. tostring(result))
            break
        end
    end
    
    if not UniqueFound then
        -- Fallback: use timestamp + random for uniqueness
        animalid = tostring(os.time()) .. math.random(100, 999)
        print("^3[WARNING]^7 Used fallback animal ID generation: " .. animalid)
    end
    
    return animalid
end

---------------------------------------------
-- count amount of animals the ranch owns
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-ranch:server:countanimals', function(source, cb, ranchid)
    local src = source
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
        print("^1[ERROR]^7 Failed to query animal count for ranchid: " .. tostring(ranchid))
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
        print('^1[ERROR]^7 Critical error in refreshAnimals: ' .. tostring(error))
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
    
    -- Update animal hunger
    local success = MySQL.update.await('UPDATE rex_ranch_animals SET hunger = 100 WHERE animalid = ?', {animalid})
    if success and success > 0 then
        Player.Functions.RemoveItem(Config.FeedItem, 1)
        if RSGCore.Shared.Items[Config.FeedItem] then
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.FeedItem], 'remove', 1)
        end
        TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'Animal has been fed!'})
        
        -- Send immediate update to client
        TriggerClientEvent('rex-ranch:client:refreshSingleAnimal', src, animalid, {hunger = 100})
        
        TriggerEvent('rex-ranch:server:refreshAnimals')
        if Config.Debug then
            print('^2[DEBUG]^7 Player ' .. src .. ' fed animal ' .. animalid)
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Animal not found!'})
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
    
    -- Update animal thirst
    local success = MySQL.update.await('UPDATE rex_ranch_animals SET thirst = 100 WHERE animalid = ?', {animalid})
    if success and success > 0 then
        Player.Functions.RemoveItem(Config.WaterItem, 1)
        if RSGCore.Shared.Items[Config.WaterItem] then
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.WaterItem], 'remove', 1)
        end
        TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'Animal has been watered!'})
        
        -- Send immediate update to client
        TriggerClientEvent('rex-ranch:client:refreshSingleAnimal', src, animalid, {thirst = 100})
        
        TriggerEvent('rex-ranch:server:refreshAnimals')
        if Config.Debug then
            print('^2[DEBUG]^7 Player ' .. src .. ' watered animal ' .. animalid)
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Animal not found!'})
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
    
    if not Player or not animalid then return end
    
    -- Get animal data
    MySQL.query('SELECT model, product_ready FROM rex_ranch_animals WHERE animalid = ?', {animalid}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Animal not found!'})
            return
        end
        
        local animal = result[1]
        if not animal.product_ready or animal.product_ready == 0 then
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'No product ready to collect!'})
            return
        end
        
        -- Get product config
        local productConfig = Config.AnimalProducts[animal.model]
        if not productConfig then
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'This animal does not produce anything!'})
            return
        end
        
        -- Give product to player
        Player.Functions.AddItem(productConfig.product, productConfig.amount)
        if RSGCore.Shared.Items[productConfig.product] then
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[productConfig.product], 'add', productConfig.amount)
        end
        
        -- Reset product ready status
        MySQL.update('UPDATE rex_ranch_animals SET product_ready = 0 WHERE animalid = ?', {animalid})
        
        TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'Collected ' .. productConfig.amount .. ' ' .. productConfig.product .. '!'})
        
        if Config.Debug then
            print('^2[DEBUG]^7 Player ' .. src .. ' collected ' .. productConfig.product .. ' from animal ' .. animalid)
        end
    end)
end)

---------------------------------------------
-- get animal production status
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-ranch:server:getAnimalProductionStatus', function(source, cb, animalid)
    local src = source
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
        
        cb({
            hasProduct = animal.product_ready == 1,
            productName = productConfig.product,
            productAmount = productConfig.amount,
            canProduce = canProduce,
            timeUntilNext = timeUntilNext,
            animalModel = animal.model
        })
    end)
end)

---------------------------------------------
-- animal cron system
---------------------------------------------
lib.cron.new(Config.AnimalCronJob, function()
    MySQL.query('SELECT animalid, model, born, health, thirst, hunger, last_production, product_ready FROM rex_ranch_animals', {}, function(animals)
        if not animals or #animals == 0 then
            print('^1[ERROR]^7 No animals found in database or query failed.')
            return
        end

        local scaleTable = {
            [0] = 0.5,
            [1] = 0.6,
            [2] = 0.7,
            [3] = 0.8,
            [4] = 0.9,
            [5] = 1.0
        }

        local animalsToRemove = {}

        for _, animal in ipairs(animals) do
            if not animal.born then
                print('^1[ERROR]^7 Invalid animal data: missing born field for animalid ' .. (animal.animalid or 'unknown'))
                goto continue
            end

            local animalAge = math.floor((os.time() - animal.born) / (24 * 60 * 60))
            if animalAge < 0 then
                print('^1[ERROR]^7 Invalid birth date for animalid ' .. (animal.animalid or 'unknown'))
                goto continue
            end

            -- Prepare batch update data instead of individual queries
            local scale = scaleTable[math.min(animalAge, 5)] or 1.0
            -- Note: This individual update will be replaced with batch processing below
            
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
                        MySQL.update('UPDATE rex_ranch_animals SET last_production = ?, product_ready = 1 WHERE animalid = ?', {
                            currentTime, animal.animalid
                        })
                        
                        if Config.Debug then
                            print('^2[DEBUG]^7 Animal ' .. animal.animalid .. ' (' .. animal.model .. ') produced ' .. productConfig.product)
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
                -- Update animal stats
                MySQL.update('UPDATE rex_ranch_animals SET hunger = ?, thirst = ?, health = ? WHERE animalid = ?', {
                    newHunger, newThirst, newHealth, animal.animalid
                })
                if Config.Debug then
                    print('^2[DEBUG]^7 Updated animal ' .. animal.animalid .. ' - Hunger: ' .. newHunger .. ', Thirst: ' .. newThirst .. ', Health: ' .. newHealth)
                end
            end
            
            ::continue::
        end
        
        -- Remove dead animals from database and client
        for _, animalid in ipairs(animalsToRemove) do
            MySQL.execute('DELETE FROM rex_ranch_animals WHERE animalid = ?', {animalid})
            -- Remove the animal entity from all clients
            TriggerClientEvent('rex-ranch:client:removeAnimal', -1, animalid)
        end
        
        -- Refresh animals on client if any were removed
        if #animalsToRemove > 0 then
            TriggerEvent('rex-ranch:server:refreshAnimals')
        end
        
        if Config.ServerNotify and #animalsToRemove == 0 then
            print('^2[REX-RANCH]^7 Animal survival check completed. ' .. #animals .. ' animals updated.')
        end
    end)
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

-- Get nearby animals available for sale at current sale point
RSGCore.Functions.CreateCallback('rex-ranch:server:getNearbyAnimalsForSale', function(source, cb, ranchid, salePointCoords)
    local src = source
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

-- Sell animal
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
                        local deleteSuccess = MySQL.update.await('DELETE FROM rex_ranch_animals WHERE animalid = ?', {animal.animalid})
                        
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
    local validAnimals = {'a_c_cow', 'a_c_sheep_01', 'a_c_pig_01', 'a_c_horse_americanpaint_greyovero'}
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
    
    -- Check current animal count
    RSGCore.Functions.TriggerCallback('rex-ranch:server:countanimals', function(animalCount)
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
        local born = os.time()
        
        -- Add animal to database
        local success, result = pcall(function()
            return MySQL.Async.insert('INSERT INTO rex_ranch_animals (ranchid, animalid, model, pos_x, pos_y, pos_z, pos_w, health, hunger, thirst, scale, age, born) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                data.ranchid,
                animalid,
                data.animalType,
                data.spawnpoint.x,
                data.spawnpoint.y,
                data.spawnpoint.z,
                data.spawnpoint.w,
                100, -- health
                100, -- hunger
                100, -- thirst
                0.5, -- scale (young animal)
                0,   -- age
                born
            })
        end)
        
        if success and result then
            -- Take money from player
            Player.Functions.RemoveMoney('cash', data.price)
            
            -- Send success notification
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'success',
                description = 'Purchased ' .. (data.animalName or 'animal') .. ' for $' .. data.price .. '!\nDelivered to your ranch.'
            })
            
            -- Refresh animals on client
            TriggerEvent('rex-ranch:server:refreshAnimals')
            
            if Config.Debug then
                print('^2[BUY DEBUG]^7 Player ' .. src .. ' bought ' .. data.animalType .. ' (ID: ' .. animalid .. ') for $' .. data.price .. ' at ' .. (data.buyPointName or 'unknown location'))
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Failed to add animal to ranch! Please try again.'})
            if Config.Debug then
                print('^1[BUY DEBUG]^7 Database error for player ' .. src .. ': ' .. tostring(result))
            end
        end
        
    end, data.ranchid, src)
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
-- debug commands
---------------------------------------------
