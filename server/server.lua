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
    while not UniqueFound do
        animalid = math.random(111111, 999999)
        local query = "%" .. animalid .. "%"
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM rex_ranch_animals WHERE animalid LIKE ?", { query })
        if result == 0 then
            UniqueFound = true
        end
    end
    return animalid
end

---------------------------------------------
-- ranch buy livestock and add to database
---------------------------------------------
RegisterNetEvent('rex-ranch:server:buylivestock', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player and not data then return end

    local playercash = Player.Functions.GetMoney('cash')
    if playercash < data.cowbuy then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You don\'t have enough cash to do that!.'})
        return 
    end

    local animalid = CreateAnimalId()
    local born = os.time()

    MySQL.Async.insert('INSERT INTO rex_ranch_animals (ranchid, animalid, model, pos_x, pos_y, pos_z, pos_w, health, born) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        data.ranchid,
        animalid,
        data.animal,
        data.spawnpoint.x,
        data.spawnpoint.y,
        data.spawnpoint.z,
        data.spawnpoint.w,
        100,
        born
    })
    Player.Functions.RemoveMoney('cash', tonumber(data.cowbuy))
    TriggerEvent('rex-ranch:server:refreshAnimals')

end)

---------------------------------------------
-- send animals to client side from database
---------------------------------------------
RegisterNetEvent('rex-ranch:server:refreshAnimals', function()
    MySQL.query('SELECT * FROM `rex_ranch_animals`', {}, function(animals)
        if animals and #animals > 0 then
            TriggerClientEvent('rex-ranch:client:spawnAnimals', -1, animals)
            if Config.Debug then
                print('^2[DEBUG]^7 Successfully sent ' .. #animals .. ' animals entries to clients (manual trigger).')
            end
        else
            if Config.Debug then
                print('^1[ERROR]^7 No animals found in database or query failed (manual trigger).')
            end
        end
    end)
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
