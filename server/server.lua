local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------------------
-- helper function to check if player is ranch staff
---------------------------------------------
local function isPlayerRanchStaff(Player)
    if not Player or not Player.PlayerData.job then
        return false
    end
    
    local playerjob = Player.PlayerData.job.name
    
    -- Check if player's job matches any ranch job access
    for _, ranchData in pairs(Config.RanchLocations) do
        if playerjob == ranchData.jobaccess then
            return true
        end
    end
    
    return false
end

---------------------------------------------
-- New Spawn Management System
---------------------------------------------
local SpawnController = {
    activeSpawns = {},      -- [animalId] = {playerId, spawnTime}
    spawnRequests = {},     -- Track pending spawn requests
    config = {
        maxSpawnsPerPlayer = 10,    -- Max animals a single player can have spawned
        spawnTimeout = 30000,       -- Timeout for spawn requests (30s)
        cleanupInterval = 60000     -- Cleanup interval (1 minute)
    }
}

-- Initialize spawn controller
function SpawnController:Initialize()
    -- Start cleanup thread
    CreateThread(function()
        while true do
            self:CleanupStaleData()
            Wait(self.config.cleanupInterval)
        end
    end)
    
    if Config.Debug then
        print('^2[SPAWN CONTROLLER]^7 Initialized new server spawn management')
    end
end

-- Check if a player can spawn an animal
function SpawnController:CanPlayerSpawn(playerId, animalId)
    -- Check if animal is already spawned by someone else
    if self.activeSpawns[animalId] then
        local spawnData = self.activeSpawns[animalId]
        if spawnData.playerId ~= playerId then
            -- Check if owner is still online
            local ownerPlayer = RSGCore.Functions.GetPlayer(spawnData.playerId)
            if ownerPlayer then
                return false, "Animal already spawned by another player"
            else
                -- Owner disconnected, clear spawn
                self.activeSpawns[animalId] = nil
            end
        end
    end
    
    -- Check player spawn limit
    local playerSpawnCount = 0
    for _, spawnData in pairs(self.activeSpawns) do
        if spawnData.playerId == playerId then
            playerSpawnCount = playerSpawnCount + 1
        end
    end
    
    if playerSpawnCount >= self.config.maxSpawnsPerPlayer then
        return false, "Too many animals spawned"
    end
    
    return true, "OK"
end

-- Register an animal spawn
function SpawnController:RegisterSpawn(playerId, animalId)
    self.activeSpawns[animalId] = {
        playerId = playerId,
        spawnTime = os.time()
    }
    
    if Config.Debug then
        print('^2[SPAWN CONTROLLER]^7 Registered spawn - Player: ' .. playerId .. ', Animal: ' .. animalId)
    end
end

-- Unregister an animal spawn
function SpawnController:UnregisterSpawn(animalId)
    if self.activeSpawns[animalId] then
        if Config.Debug then
            print('^3[SPAWN CONTROLLER]^7 Unregistered spawn - Animal: ' .. animalId)
        end
        self.activeSpawns[animalId] = nil
    end
end

-- Get spawn count for player
function SpawnController:GetPlayerSpawnCount(playerId)
    local count = 0
    for _, spawnData in pairs(self.activeSpawns) do
        if spawnData.playerId == playerId then
            count = count + 1
        end
    end
    return count
end

-- Cleanup stale data
function SpawnController:CleanupStaleData()
    local currentTime = os.time()
    local cleanedCount = 0
    
    -- Clean up stale spawn requests (requests that were never completed)
    for animalId, requestData in pairs(self.spawnRequests) do
        if (currentTime - requestData.timestamp) > (self.config.spawnTimeout / 1000) then
            self.spawnRequests[animalId] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    -- Clean up spawns for disconnected players
    local playersToCheck = {}
    for animalId, spawnData in pairs(self.activeSpawns) do
        local playerId = spawnData.playerId
        if not playersToCheck[playerId] then
            local player = RSGCore.Functions.GetPlayer(playerId)
            playersToCheck[playerId] = player ~= nil
        end
        
        if not playersToCheck[playerId] then
            self.activeSpawns[animalId] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    if Config.Debug and cleanedCount > 0 then
        print('^3[SPAWN CONTROLLER]^7 Cleaned up ' .. cleanedCount .. ' stale spawn entries')
    end
end

-- Clear all spawns for a player
function SpawnController:ClearPlayerSpawns(playerId)
    local clearedCount = 0
    for animalId, spawnData in pairs(self.activeSpawns) do
        if spawnData.playerId == playerId then
            self.activeSpawns[animalId] = nil
            clearedCount = clearedCount + 1
        end
    end
    
    if Config.Debug and clearedCount > 0 then
        print('^3[SPAWN CONTROLLER]^7 Cleared ' .. clearedCount .. ' spawns for disconnected player ' .. playerId)
    end
end

-- Initialize the spawn controller
SpawnController:Initialize()

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
-- get gender-specific breeding cooldown
---------------------------------------------
local function GetBreedingCooldown(gender)
    if Config.GenderSpecificCooldowns and Config.GenderSpecificCooldowns[gender] then
        return Config.GenderSpecificCooldowns[gender]
    end
    
    -- Fallback to default cooldown
    return Config.BreedingCooldown or 172800
end

---------------------------------------------
-- select offspring model based on breeding config probabilities
---------------------------------------------
local function SelectOffspringModel(parentModel)
    local breedingConfig = Config.BreedingConfig[parentModel]
    if not breedingConfig or not breedingConfig.offspringModels then
        -- Fallback: return same model as parent
        return parentModel
    end
    
    local offspringModels = breedingConfig.offspringModels
    if #offspringModels == 0 then
        return parentModel
    end
    
    -- Calculate total chance for normalization
    local totalChance = 0
    for _, offspring in ipairs(offspringModels) do
        totalChance = totalChance + offspring.chance
    end
    
    if totalChance == 0 then
        return parentModel
    end
    
    -- Generate random number and select model
    local randomValue = math.random() * totalChance
    local currentChance = 0
    
    for _, offspring in ipairs(offspringModels) do
        currentChance = currentChance + offspring.chance
        if randomValue <= currentChance then
            if Config.Debug then
                print('^3[BREEDING DEBUG]^7 Selected offspring model: ' .. offspring.model .. ' (chance: ' .. offspring.chance .. '/' .. totalChance .. ')')
            end
            return offspring.model
        end
    end
    
    -- Fallback: return the first model
    if Config.Debug then
        print('^1[BREEDING ERROR]^7 Failed to select offspring model, using first option: ' .. offspringModels[1].model)
    end
    return offspringModels[1].model
end

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
-- New Spawn Event Handlers
---------------------------------------------

-- Handle spawn requests from clients
RegisterNetEvent('rex-ranch:server:requestAnimalSpawn', function(animalId, animalData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not isPlayerRanchStaff(Player) then
        TriggerClientEvent('rex-ranch:client:spawnAnimalDenied', src, animalId, 'Not authorized')
        return
    end
    
    -- Check if spawn is allowed
    local canSpawn, reason = SpawnController:CanPlayerSpawn(src, animalId)
    if not canSpawn then
        TriggerClientEvent('rex-ranch:client:spawnAnimalDenied', src, animalId, reason)
        return
    end
    
    -- Register the spawn and grant permission
    SpawnController:RegisterSpawn(src, animalId)
    TriggerClientEvent('rex-ranch:client:spawnAnimalGranted', src, animalId, animalData)
    
    if Config.Debug then
        print('^2[SPAWN CONTROLLER]^7 Granted spawn permission for animal ' .. animalId .. ' to player ' .. src)
    end
end)

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
-- Handle player disconnects
---------------------------------------------
AddEventHandler('playerDropped', function(reason)
    local src = source
    SpawnController:ClearPlayerSpawns(src)
end)

---------------------------------------------
-- feed animal system
---------------------------------------------
RegisterNetEvent('rex-ranch:server:feedAnimal', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    -- Validate player is ranch staff
    if not Player or not isPlayerRanchStaff(Player) then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You must be ranch staff to feed animals!'})
        return
    end
    
    -- Handle both string and object parameters for backwards compatibility
    local animalid
    if type(data) == 'table' and data.animalid then
        animalid = data.animalid
    elseif type(data) == 'string' or type(data) == 'number' then
        animalid = tostring(data)
    else
        animalid = nil
    end
    
    if not animalid then return end
    
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
    
    -- Validate player is ranch staff
    if not Player or not isPlayerRanchStaff(Player) then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You must be ranch staff to water animals!'})
        return
    end
    
    -- Handle both string and object parameters for backwards compatibility
    local animalid
    if type(data) == 'table' and data.animalid then
        animalid = data.animalid
    elseif type(data) == 'string' or type(data) == 'number' then
        animalid = tostring(data)
    else
        animalid = nil
    end
    
    if not animalid then return end
    
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
    
    -- Validate player is ranch staff
    if not Player or not isPlayerRanchStaff(Player) then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You must be ranch staff to collect from animals!'})
        return
    end
    
    -- Handle both string and object parameters for backwards compatibility
    local animalid
    if type(data) == 'table' and data.animalid then
        animalid = data.animalid
    elseif type(data) == 'string' or type(data) == 'number' then
        animalid = tostring(data)
    else
        animalid = nil
    end
    
    if not animalid then
        if Config.Debug then
            print('^1[COLLECT ERROR]^7 Missing animalid - AnimalID: ' .. tostring(animalid))
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
-- animal production status callback
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-ranch:server:getAnimalProductionStatus', function(src, cb, animalid)
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if Config.Debug then
        print('^3[PRODUCTION DEBUG]^7 Production status request for animal ' .. tostring(animalid) .. ' from player ' .. src)
    end
    
    if not Player or not animalid or not isPlayerRanchStaff(Player) then
        if Config.Debug then
            print('^1[PRODUCTION DEBUG]^7 Request denied - Player: ' .. tostring(Player ~= nil) .. ', AnimalID: ' .. tostring(animalid) .. ', IsStaff: ' .. tostring(Player and isPlayerRanchStaff(Player)))
        end
        cb(false)
        return 
    end
    
    MySQL.query('SELECT model, product_ready, health, hunger, thirst FROM rex_ranch_animals WHERE animalid = ?', {animalid}, function(result)
        if Config.Debug then
            print('^3[PRODUCTION DEBUG]^7 Database query result for animal ' .. animalid .. ': ' .. (result and #result or 'nil/0') .. ' rows')
        end
        
        if not result or #result == 0 then
            if Config.Debug then
                print('^1[PRODUCTION DEBUG]^7 No animal found with ID: ' .. animalid)
            end
            cb(false)
            return
        end
        
        local animal = result[1]
        if Config.Debug then
            print('^3[PRODUCTION DEBUG]^7 Found animal - Model: ' .. tostring(animal.model) .. ', Product Ready: ' .. tostring(animal.product_ready))
        end
        
        local productConfig = Config.AnimalProducts[animal.model]
        if not productConfig then
            if Config.Debug then
                print('^1[PRODUCTION DEBUG]^7 No product config found for model: ' .. tostring(animal.model))
            end
            cb(false)
            return
        end
        
        if Config.Debug then
            print('^2[PRODUCTION DEBUG]^7 Product config found - Product: ' .. productConfig.product .. ', Amount: ' .. productConfig.amount)
        end
        
        local hasProduct = animal.product_ready == 1
        
        -- Check production requirements using Config values
        local meetsHealthReq = (animal.health or 0) >= (productConfig.requiresHealth or 60)
        local meetsHungerReq = (animal.hunger or 0) >= (productConfig.requiresHunger or 40)
        local meetsThirstReq = (animal.thirst or 0) >= (productConfig.requiresThirst or 40)
        local canProduce = meetsHealthReq and meetsHungerReq and meetsThirstReq
        
        if Config.Debug then
            print('^3[PRODUCTION DEBUG]^7 Animal ' .. animalid .. ' production check:')
            print('^3[PRODUCTION DEBUG]^7 - Health: ' .. (animal.health or 0) .. '/' .. (productConfig.requiresHealth or 60) .. ' (meets: ' .. tostring(meetsHealthReq) .. ')')
            print('^3[PRODUCTION DEBUG]^7 - Hunger: ' .. (animal.hunger or 0) .. '/' .. (productConfig.requiresHunger or 40) .. ' (meets: ' .. tostring(meetsHungerReq) .. ')')
            print('^3[PRODUCTION DEBUG]^7 - Thirst: ' .. (animal.thirst or 0) .. '/' .. (productConfig.requiresThirst or 40) .. ' (meets: ' .. tostring(meetsThirstReq) .. ')')
            print('^3[PRODUCTION DEBUG]^7 - Can Produce: ' .. tostring(canProduce) .. ', Has Product: ' .. tostring(hasProduct))
        end
        
        local productionData = {
            hasProduct = hasProduct,
            canProduce = canProduce,
            productName = productConfig.product,
            productAmount = productConfig.amount,
            timeUntilNext = 0
        }
        
        -- For now, simplified logic without last_product_time tracking
        -- If animal can produce but doesn't have product, show production interval
        if not hasProduct and canProduce then
            local productionInterval = productConfig.productionTime or 3600 -- Use productionTime from Config
            -- Since we don't track last production time, just show the full interval
            productionData.timeUntilNext = productionInterval
            
            if Config.Debug then
                print('^3[PRODUCTION DEBUG]^7 Animal can produce but no product ready - showing full interval: ' .. productionInterval .. ' seconds')
            end
        end
        
        cb(productionData)
    end)
end)

---------------------------------------------
-- Debug/Admin Commands
---------------------------------------------
-- Set animal product ready status (for testing)
RegisterCommand('setproductready', function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not isPlayerRanchStaff(Player) then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You must be ranch staff to use this command!'})
        return
    end
    
    local animalid = tonumber(args[1])
    local status = tonumber(args[2]) or 1  -- Default to 1 (ready)
    
    if not animalid then
        TriggerClientEvent('ox_lib:notify', src, {type = 'info', description = 'Usage: /setproductready [animalid] [status] (status: 0=not ready, 1=ready)'})
        return
    end
    
    -- Validate status
    if status ~= 0 and status ~= 1 then
        status = 1
    end
    
    MySQL.update('UPDATE rex_ranch_animals SET product_ready = ? WHERE animalid = ?', {status, animalid}, function(affectedRows)
        if affectedRows and affectedRows > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'success', 
                description = 'Set animal ' .. animalid .. ' product status to ' .. (status == 1 and 'ready' or 'not ready')
            })
            
            -- Refresh animals for all clients
            TriggerEvent('rex-ranch:server:refreshAnimals')
            
            if Config.Debug then
                print('^2[ADMIN COMMAND]^7 Player ' .. src .. ' set animal ' .. animalid .. ' product_ready to ' .. status)
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Animal ' .. animalid .. ' not found!'})
        end
    end)
end, false)

---------------------------------------------
-- Animal Overview Callback
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-ranch:server:getAnimalOverview', function(src, cb, ranchid)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then 
        cb({animals = {}, summary = {}})
        return 
    end
    
    if not ranchid then
        -- Get all animals if no specific ranch
        MySQL.query('SELECT * FROM rex_ranch_animals ORDER BY ranchid, model', {}, function(result)
            if not result then
                cb({animals = {}, summary = {}})
                return
            end
            
            local processedData = processAnimalOverviewData(result)
            cb(processedData)
        end)
    else
        -- Get animals for specific ranch
        MySQL.query('SELECT * FROM rex_ranch_animals WHERE ranchid = ? ORDER BY model', {ranchid}, function(result)
            if not result then
                cb({animals = {}, summary = {}})
                return
            end
            
            local processedData = processAnimalOverviewData(result)
            cb(processedData)
        end)
    end
end)

-- Helper function to process animal overview data
function processAnimalOverviewData(animals)
    local overview = {
        animals = {},
        summary = {
            total = #animals,
            byType = {},
            byGender = {male = 0, female = 0},
            pregnant = 0,
            ready_for_breeding = 0,
            unhealthy = 0,
            hungry = 0,
            thirsty = 0
        }
    }
    
    local currentTime = os.time()
    
    for _, animal in ipairs(animals) do
        -- Basic animal info
        local animalInfo = {
            animalid = animal.animalid,
            ranchid = animal.ranchid,
            model = animal.model,
            gender = animal.gender,
            age = animal.age or 0,
            health = animal.health or 100,
            hunger = animal.hunger or 100,
            thirst = animal.thirst or 100,
            pregnant = (animal.pregnant == 1 or animal.pregnant == true),
            breeding_ready_time = animal.breeding_ready_time,
            gestation_end_time = animal.gestation_end_time,
            pos_x = animal.pos_x,
            pos_y = animal.pos_y,
            pos_z = animal.pos_z
        }
        
        -- Calculate status flags
        animalInfo.is_unhealthy = (animalInfo.health < 70)
        animalInfo.is_hungry = (animalInfo.hunger < 50)
        animalInfo.is_thirsty = (animalInfo.thirst < 50)
        
        -- Check basic breeding readiness (age, pregnancy, cooldown)
        local basicBreedingReady = not animalInfo.pregnant and 
                                  (not animal.breeding_ready_time or animal.breeding_ready_time <= currentTime) and
                                  animalInfo.age >= (Config.MinAgeForBreeding or 5)
        
        -- For males, also check if there are already pregnant females in the ranch (if enabled)
        if basicBreedingReady and animalInfo.gender == 'male' and Config.RestrictMaleBreedingWhenFemalesPregnant then
            -- Count pregnant females in the same ranch
            local pregnantFemales = 0
            for _, otherAnimal in ipairs(animals) do
                if otherAnimal.ranchid == animalInfo.ranchid and 
                   otherAnimal.gender == 'female' and 
                   (otherAnimal.pregnant == 1 or otherAnimal.pregnant == true) then
                    pregnantFemales = pregnantFemales + 1
                end
            end
            animalInfo.breeding_ready = pregnantFemales == 0
            if pregnantFemales > 0 then
                animalInfo.breeding_restriction = 'Cannot breed - ' .. pregnantFemales .. ' female(s) already pregnant'
            end
        else
            animalInfo.breeding_ready = basicBreedingReady
        end
        
        -- Pregnancy status
        if animalInfo.pregnant and animalInfo.gestation_end_time then
            local timeRemaining = animalInfo.gestation_end_time - currentTime
            if timeRemaining > 0 then
                animalInfo.pregnancy_status = 'Due in ' .. math.floor(timeRemaining / (24 * 3600)) .. ' days'
            else
                animalInfo.pregnancy_status = 'Ready to give birth'
            end
        end
        
        table.insert(overview.animals, animalInfo)
        
        -- Update summary statistics
        overview.summary.byType[animal.model] = (overview.summary.byType[animal.model] or 0) + 1
        overview.summary.byGender[animal.gender] = (overview.summary.byGender[animal.gender] or 0) + 1
        
        if animalInfo.pregnant then
            overview.summary.pregnant = overview.summary.pregnant + 1
        end
        
        if animalInfo.breeding_ready then
            overview.summary.ready_for_breeding = overview.summary.ready_for_breeding + 1
        end
        
        if animalInfo.is_unhealthy then
            overview.summary.unhealthy = overview.summary.unhealthy + 1
        end
        
        if animalInfo.is_hungry then
            overview.summary.hungry = overview.summary.hungry + 1
        end
        
        if animalInfo.is_thirsty then
            overview.summary.thirsty = overview.summary.thirsty + 1
        end
    end
    
    return overview
end

---------------------------------------------
-- Breeding System Callbacks
---------------------------------------------

-- Get detailed breeding status including cooldowns
RSGCore.Functions.CreateCallback('rex-ranch:server:getBreedingStatus', function(src, cb, animalid)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not animalid then 
        cb({status = 'error', message = 'Invalid request'})
        return 
    end
    
    MySQL.query('SELECT model, gender, age, pregnant, breeding_ready_time, health, hunger, thirst, born FROM rex_ranch_animals WHERE animalid = ?', {animalid}, function(result)
        if not result or #result == 0 then
            cb({status = 'error', message = 'Animal not found'})
            return
        end
        
        local animal = result[1]
        local currentTime = os.time()
        local animalAge = animal.age or math.floor((currentTime - (animal.born or currentTime)) / (24 * 60 * 60))
        
        if Config.Debug then
            print('^3[BREEDING DEBUG]^7 Breeding status check for animal ' .. animalid .. ' - Age: ' .. animalAge .. ', Gender: ' .. tostring(animal.gender))
        end
        
        -- Check if breeding is enabled
        if not Config.BreedingEnabled then
            cb({status = 'disabled', message = 'Breeding system is disabled'})
            return
        end
        
        -- Check pregnancy status
        local isPregnant = (animal.pregnant == 1 or animal.pregnant == true or animal.pregnant == 'true')
        if isPregnant then
            cb({status = 'pregnant', message = 'Animal is pregnant'})
            return
        end
        
        -- Check age requirements
        if Config.MinAgeForBreeding and animalAge < Config.MinAgeForBreeding then
            cb({status = 'too_young', message = 'Too young to breed (need ' .. Config.MinAgeForBreeding .. ' days, currently ' .. animalAge .. ' days)'})
            return
        end
        
        if Config.MaxBreedingAge and animalAge > Config.MaxBreedingAge then
            cb({status = 'too_old', message = 'Too old to breed (max ' .. Config.MaxBreedingAge .. ' days, currently ' .. animalAge .. ' days)'})
            return
        end
        
        -- Check health requirements
        local healthReq = Config.RequireHealthForBreeding or 70
        local hungerReq = Config.RequireHungerForBreeding or 50
        local thirstReq = Config.RequireThirstForBreeding or 50
        
        if (animal.health or 100) < healthReq or (animal.hunger or 100) < hungerReq or (animal.thirst or 100) < thirstReq then
            local issues = {}
            if (animal.health or 100) < healthReq then table.insert(issues, 'health too low') end
            if (animal.hunger or 100) < hungerReq then table.insert(issues, 'hunger too low') end
            if (animal.thirst or 100) < thirstReq then table.insert(issues, 'thirst too low') end
            
            cb({status = 'requirements_not_met', message = 'Requirements not met: ' .. table.concat(issues, ', ')})
            return
        end
        
        -- Check breeding cooldown
        if animal.breeding_ready_time and animal.breeding_ready_time > currentTime then
            local timeRemaining = animal.breeding_ready_time - currentTime
            local hoursRemaining = math.ceil(timeRemaining / 3600)
            cb({
                status = 'cooldown', 
                message = 'Breeding cooldown active (' .. hoursRemaining .. 'h remaining)',
                timeRemaining = timeRemaining
            })
            return
        end
        
        -- Check if male and there are already pregnant females in the ranch (if enabled)
        if animal.gender == 'male' and Config.RestrictMaleBreedingWhenFemalesPregnant then
            -- Get ranch ID from the animal
            MySQL.query('SELECT ranchid FROM rex_ranch_animals WHERE animalid = ?', {animalid}, function(ranchResult)
                if ranchResult and #ranchResult > 0 then
                    local ranchid = ranchResult[1].ranchid
                    
                    -- Check for pregnant females in the same ranch
                    MySQL.query('SELECT COUNT(*) as pregnant_count FROM rex_ranch_animals WHERE ranchid = ? AND gender = ? AND pregnant = 1', 
                                {ranchid, 'female'}, function(pregnantResult)
                        if pregnantResult and #pregnantResult > 0 and pregnantResult[1].pregnant_count > 0 then
                            cb({
                                status = 'restricted', 
                                message = 'Cannot breed - there are already ' .. pregnantResult[1].pregnant_count .. ' pregnant female(s) in this ranch'
                            })
                            return
                        else
                            -- Animal is ready to breed
                            cb({status = 'ready', message = 'Ready for breeding'})
                            return
                        end
                    end)
                else
                    -- Animal is ready to breed (fallback if ranch not found)
                    cb({status = 'ready', message = 'Ready for breeding'})
                    return
                end
            end)
        else
            -- Female animals don't have this restriction
            cb({status = 'ready', message = 'Ready for breeding'})
        end
    end)
end)

-- Get pregnancy progress
RSGCore.Functions.CreateCallback('rex-ranch:server:getPregnancyProgress', function(src, cb, animalid)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not animalid or not isPlayerRanchStaff(Player) then 
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

-- Get available animals for breeding
RSGCore.Functions.CreateCallback('rex-ranch:server:getAvailableAnimalsForBreeding', function(src, cb, ranchid, animalid)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not ranchid or not animalid or not isPlayerRanchStaff(Player) then 
        cb(false)
        return 
    end
    
    -- Get the animal we want to breed
    MySQL.query('SELECT model, gender, age FROM rex_ranch_animals WHERE animalid = ? AND ranchid = ?', {animalid, ranchid}, function(mainResult)
        if not mainResult or #mainResult == 0 then
            cb(false)
            return
        end
        
        local mainAnimal = mainResult[1]
        local targetGender = mainAnimal.gender == 'male' and 'female' or 'male'
        
        -- Check if the main animal is male and there are already pregnant females (if enabled)
        if mainAnimal.gender == 'male' and Config.RestrictMaleBreedingWhenFemalesPregnant then
            MySQL.query('SELECT COUNT(*) as pregnant_count FROM rex_ranch_animals WHERE ranchid = ? AND gender = ? AND pregnant = 1', 
                        {ranchid, 'female'}, function(pregnantCheck)
                if pregnantCheck and #pregnantCheck > 0 and pregnantCheck[1].pregnant_count > 0 then
                    -- Return empty list - male cannot breed when females are already pregnant
                    cb({})
                    return
                end
                
                -- Continue with normal breeding partner search
                findBreedingPartners()
            end)
        else
            -- Female animals can breed normally
            findBreedingPartners()
        end
        
        function findBreedingPartners()
            -- Find compatible animals of opposite gender
            MySQL.query('SELECT animalid, model, gender, age, health, hunger, thirst, pregnant, breeding_ready_time, pos_x, pos_y, pos_z FROM rex_ranch_animals WHERE ranchid = ? AND gender = ? AND animalid != ?', 
                        {ranchid, targetGender, animalid}, function(result)
                if not result or #result == 0 then
                    cb({})
                    return
                end
                
                local availableAnimals = {}
                local currentTime = os.time()
                
                for _, animal in ipairs(result) do
                    local canBreed = true
                    local breedingIssue = ''
                    
                    -- Check pregnancy
                    if animal.pregnant == 1 then
                        canBreed = false
                        breedingIssue = 'Pregnant'
                    end
                    
                    -- Check breeding cooldown
                    if canBreed and animal.breeding_ready_time and animal.breeding_ready_time > currentTime then
                        canBreed = false
                        local hoursRemaining = math.ceil((animal.breeding_ready_time - currentTime) / 3600)
                        breedingIssue = 'Cooldown (' .. hoursRemaining .. 'h)'
                    end
                    
                    -- Check age requirements
                    if canBreed then
                        local animalAge = animal.age or 0
                        if Config.MinAgeForBreeding and animalAge < Config.MinAgeForBreeding then
                            canBreed = false
                            breedingIssue = 'Too young'
                        elseif Config.MaxBreedingAge and animalAge > Config.MaxBreedingAge then
                            canBreed = false
                            breedingIssue = 'Too old'
                        end
                    end
                    
                    -- Check health/hunger/thirst requirements
                    if canBreed then
                        local healthReq = Config.RequireHealthForBreeding or 70
                        local hungerReq = Config.RequireHungerForBreeding or 50
                        local thirstReq = Config.RequireThirstForBreeding or 50
                        
                        if (animal.health or 100) < healthReq or (animal.hunger or 100) < hungerReq or (animal.thirst or 100) < thirstReq then
                            canBreed = false
                            breedingIssue = 'Poor condition'
                        end
                    end
                    
                    -- Calculate distance (simplified - assumes animals are at their database positions)
                    local distance = 0
                    if animal.pos_x and animal.pos_y and animal.pos_z then
                        distance = math.floor(math.random(5, 50)) -- Placeholder distance for now
                    end
                    
                    table.insert(availableAnimals, {
                        animalid = animal.animalid,
                        gender = animal.gender,
                        age = animal.age or 0,
                        health = animal.health or 100,
                        canBreed = canBreed,
                        breedingIssue = breedingIssue,
                        distance = distance
                    })
                end
                
                cb(availableAnimals)
            end)
        end
    end)
end)

---------------------------------------------
-- get nearby animals for sale
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-ranch:server:getNearbyAnimalsForSale', function(src, cb, ranchid, salePointCoords)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not ranchid then 
        cb({})
        return 
    end
    
    -- Get all animals from this ranch that are old enough to sell
    local success, result = pcall(function()
        return MySQL.query.await(
            'SELECT animalid, model, gender, age, health, hunger, thirst, pos_x, pos_y, pos_z FROM rex_ranch_animals WHERE ranchid = ? AND age >= ?',
            { ranchid, Config.MinAgeToSell }
        )
    end)
    
    if not success or not result then
        cb({})
        return
    end
    
    local animals = {}
    local salePointVec = vector3(salePointCoords.x, salePointCoords.y, salePointCoords.z)
    
    for _, animal in ipairs(result) do
        -- Calculate sale price based on age
        local baseSellPrice = Config.BaseSellPrices[animal.model] or 100
        local ageMultiplier = 1.0
        local ageCategory = 'Adult'
        
        -- Determine age category and apply multiplier
        if animal.age < Config.PrimeAgeStart then
            ageMultiplier = Config.AgePricing.young
            ageCategory = 'Young'
        elseif animal.age >= Config.PrimeAgeStart and animal.age <= Config.PrimeAgeEnd then
            ageMultiplier = Config.AgePricing.prime
            ageCategory = 'Prime'
        elseif animal.age > Config.PrimeAgeEnd and animal.age < Config.OldAgeStart then
            ageMultiplier = Config.AgePricing.adult
            ageCategory = 'Adult'
        elseif animal.age >= Config.OldAgeStart then
            ageMultiplier = Config.AgePricing.old
            ageCategory = 'Old'
        end
        
        local salePrice = math.floor(baseSellPrice * ageMultiplier)
        
        -- Check if animal is nearby
        local animalVec = vector3(animal.pos_x, animal.pos_y, animal.pos_z)
        local distance = #(salePointVec - animalVec)
        local isNearby = distance <= Config.AnimalSaleDistance
        
        table.insert(animals, {
            animalid = animal.animalid,
            model = animal.model,
            gender = animal.gender,
            age = animal.age,
            ageCategory = ageCategory,
            health = animal.health,
            hunger = animal.hunger,
            thirst = animal.thirst,
            salePrice = salePrice,
            distance = math.floor(distance),
            isNearby = isNearby
        })
    end
    
    cb(animals)
end)

---------------------------------------------
-- sell single animal
---------------------------------------------
RegisterNetEvent('rex-ranch:server:sellAnimal', function(animalid, salePrice, salePointCoords)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Player not found!'})
        return
    end
    
    -- Verify player is ranch staff
    if not isPlayerRanchStaff(Player) then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You must be ranch staff to sell animals!'})
        return
    end
    
    if not animalid or not salePrice then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Invalid animal or price!'})
        return
    end
    
    -- Get animal data from database
    local animalResult = MySQL.query.await('SELECT animalid, ranchid, age, model FROM rex_ranch_animals WHERE animalid = ?', {animalid})
    
    if not animalResult or #animalResult == 0 then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Animal not found!'})
        if Config.Debug then
            print('^1[SELL ANIMAL ERROR]^7 Animal ' .. animalid .. ' not found in database')
        end
        return
    end
    
    local animal = animalResult[1]
    
    -- Verify animal is old enough to sell
    if animal.age < Config.MinAgeToSell then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'This animal is too young to sell! Must be at least ' .. Config.MinAgeToSell .. ' days old.'
        })
        return
    end
    
    -- Verify proximity if required
    if Config.RequireAnimalPresent then
        -- Would need to check animal position vs sale point - for now assume it passed the client check
    end
    
    -- Delete animal from database
    local deleteSuccess, deleteError = pcall(function()
        return MySQL.update.await('DELETE FROM rex_ranch_animals WHERE animalid = ?', {animalid})
    end)
    
    if not deleteSuccess or not deleteError or deleteError == 0 then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Failed to complete sale!'})
        if Config.Debug then
            print('^1[SELL ANIMAL ERROR]^7 Failed to delete animal ' .. animalid .. ' from database')
        end
        return
    end
    
    -- Give money to player
    Player.Functions.AddMoney('cash', salePrice)
    
    -- Notify player
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = 'Sold ' .. (animal.model == 'a_c_bull_01' and 'Bull' or 'Cow') .. ' for $' .. salePrice .. '!'
    })
    
    if Config.ServerNotify then
        TriggerClientEvent('ox_lib:notify', -1, {
            type = 'info',
            description = 'An animal has been sold at the livestock market!'
        })
    end
    
    -- Remove from clients and refresh
    TriggerClientEvent('rex-ranch:client:removeAnimal', -1, animalid)
    TriggerEvent('rex-ranch:server:refreshAnimals')
    
    if Config.Debug then
        print('^2[SELL ANIMAL SUCCESS]^7 Player ' .. src .. ' sold animal ' .. animalid .. ' for $' .. salePrice)
    end
end)

---------------------------------------------
-- sell all animals
---------------------------------------------
RegisterNetEvent('rex-ranch:server:sellAllAnimals', function(animals, salePointCoords)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Player not found!'})
        return
    end
    
    -- Verify player is ranch staff
    if not isPlayerRanchStaff(Player) then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You must be ranch staff to sell animals!'})
        return
    end
    
    if not animals or #animals == 0 then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'No animals to sell!'})
        return
    end
    
    local totalValue = 0
    local successCount = 0
    local failedAnimals = {}
    
    -- Process each animal
    for _, animal in ipairs(animals) do
        if animal.animalid and animal.salePrice then
            -- Get animal data from database to verify
            local animalResult = MySQL.query.await('SELECT animalid, age FROM rex_ranch_animals WHERE animalid = ?', {animal.animalid})
            
            if animalResult and #animalResult > 0 then
                local dbAnimal = animalResult[1]
                
                -- Verify age requirement
                if dbAnimal.age >= Config.MinAgeToSell then
                    -- Delete animal
                    local deleteSuccess, deleteError = pcall(function()
                        return MySQL.update.await('DELETE FROM rex_ranch_animals WHERE animalid = ?', {animal.animalid})
                    end)
                    
                    if deleteSuccess and deleteError and deleteError > 0 then
                        totalValue = totalValue + animal.salePrice
                        successCount = successCount + 1
                        TriggerClientEvent('rex-ranch:client:removeAnimal', -1, animal.animalid)
                    else
                        table.insert(failedAnimals, animal.animalid)
                    end
                else
                    table.insert(failedAnimals, animal.animalid)
                end
            else
                table.insert(failedAnimals, animal.animalid)
            end
        end
    end
    
    -- Give total money to player
    if totalValue > 0 then
        Player.Functions.AddMoney('cash', totalValue)
    end
    
    -- Notify player
    if successCount == #animals then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = 'Sold all ' .. successCount .. ' animals for a total of $' .. totalValue .. '!'
        })
    elseif successCount > 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'warning',
            description = 'Sold ' .. successCount .. ' out of ' .. #animals .. ' animals for $' .. totalValue .. '!'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Failed to sell any animals!'
        })
    end
    
    if Config.ServerNotify and successCount > 0 then
        TriggerClientEvent('ox_lib:notify', -1, {
            type = 'info',
            description = successCount .. ' animal(s) have been sold at the livestock market!'
        })
    end
    
    -- Refresh all clients
    TriggerEvent('rex-ranch:server:refreshAnimals')
    
    if Config.Debug then
        print('^2[SELL ANIMALS SUCCESS]^7 Player ' .. src .. ' sold ' .. successCount .. ' animals for $' .. totalValue)
        if #failedAnimals > 0 then
            print('^3[SELL ANIMALS WARNING]^7 Failed to sell ' .. #failedAnimals .. ' animals')
        end
    end
end)

---------------------------------------------
-- buy animal system
---------------------------------------------
RegisterNetEvent('rex-ranch:server:buyAnimal', function(purchaseData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Player not found!'})
        return
    end
    
    -- Verify player is ranch staff
    if not isPlayerRanchStaff(Player) then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You must be ranch staff to buy animals!'})
        return
    end
    
    -- Validate purchase data
    if not purchaseData or not purchaseData.animalType or not purchaseData.price or not purchaseData.ranchid then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Invalid purchase data!'})
        if Config.Debug then
            print('^1[BUY ANIMAL ERROR]^7 Invalid purchase data from player ' .. src)
        end
        return
    end
    
    local playerMoney = Player.PlayerData.money.cash
    
    -- Check if player has enough money
    if playerMoney < purchaseData.price then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'You need $' .. purchaseData.price .. ' but only have $' .. playerMoney
        })
        return
    end
    
    -- Check animal count for the ranch
    local countResult = MySQL.query.await('SELECT COUNT(*) as count FROM rex_ranch_animals WHERE ranchid = ?', {purchaseData.ranchid})
    if not countResult or not countResult[1] then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Error checking ranch capacity!'})
        if Config.Debug then
            print('^1[BUY ANIMAL ERROR]^7 Failed to count animals for ranch ' .. purchaseData.ranchid)
        end
        return
    end
    
    local currentCount = countResult[1].count or 0
    if currentCount >= Config.MaxRanchAnimals then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Your ranch is at maximum capacity (' .. Config.MaxRanchAnimals .. ' animals)'
        })
        return
    end
    
    -- Create unique animal ID
    local animalid = CreateAnimalId()
    if not animalid then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Failed to create animal ID!'})
        if Config.Debug then
            print('^1[BUY ANIMAL ERROR]^7 Failed to create unique animal ID for player ' .. src)
        end
        return
    end
    
    -- Determine gender based on config
    local gender = 'female'
    if Config.GenderRatios and Config.GenderRatios[purchaseData.animalType] then
        local maleChance = Config.GenderRatios[purchaseData.animalType]
        gender = (math.random() < maleChance) and 'male' or 'female'
    end
    
    -- Get spawn point for the animal
    local spawnPos = purchaseData.spawnpoint or vector4(0, 0, 0, 0)
    
    -- Current time for database
    local currentTime = os.time()
    
    -- Insert animal into database
    local success, error = pcall(function()
        return MySQL.insert.await('INSERT INTO rex_ranch_animals (animalid, ranchid, model, gender, age, health, hunger, thirst, pos_x, pos_y, pos_z, pos_w, pregnant, born) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            animalid,
            purchaseData.ranchid,
            purchaseData.animalType,
            gender,
            0,  -- age starts at 0
            100,  -- health
            100,  -- hunger
            100,  -- thirst
            spawnPos.x,
            spawnPos.y,
            spawnPos.z,
            spawnPos.w or 0,
            0,  -- not pregnant
            currentTime  -- born timestamp
        })
    end)
    
    if not success or not error or error == 0 then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Failed to purchase animal!'})
        if Config.Debug then
            print('^1[BUY ANIMAL ERROR]^7 Database insert failed: ' .. tostring(error))
        end
        return
    end
    
    -- Deduct money from player
    Player.Functions.RemoveMoney('cash', purchaseData.price)
    
    -- Notify player of successful purchase
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = 'Successfully purchased ' .. purchaseData.animalName .. ' for $' .. purchaseData.price .. '!'
    })
    
    if Config.ServerNotify then
        TriggerClientEvent('ox_lib:notify', -1, {
            type = 'info',
            description = 'A new animal has been purchased at ' .. (purchaseData.buyPointName or 'the livestock dealer') .. '!'
        })
    end
    
    -- Refresh animals for all clients
    TriggerEvent('rex-ranch:server:refreshAnimals')
    
    if Config.Debug then
        print('^2[BUY ANIMAL SUCCESS]^7 Player ' .. src .. ' purchased ' .. purchaseData.animalName .. ' (ID: ' .. animalid .. ') for $' .. purchaseData.price)
    end
end)

-- Start breeding process
RegisterNetEvent('rex-ranch:server:startBreeding', function(animal1id, animal2id)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not isPlayerRanchStaff(Player) then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You must be ranch staff to breed animals!'})
        return
    end
    
    if Config.Debug then
        print('^3[BREEDING DEBUG]^7 Breeding request from player ' .. src .. ' for animals ' .. animal1id .. ' and ' .. animal2id)
    end
    
    -- This would need full breeding implementation
    -- For now, just send a notification
    TriggerClientEvent('ox_lib:notify', src, {type = 'info', description = 'Breeding system is being implemented - feature coming soon!'})
end)
