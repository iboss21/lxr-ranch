---------------------------------------------
-- water refill system
---------------------------------------------

local RSGCore = exports['rsg-core']:GetCoreObject()

---------------------------------------------
-- setup water source zones
---------------------------------------------
CreateThread(function()
    for k, waterSource in pairs(Config.WaterSourceLocations) do
        -- Create ox_target zone for water source
        exports.ox_target:addSphereZone({
            coords = waterSource.coords,
            radius = 2.0,
            options = {
                {
                    name = 'fill_water_bucket_' .. k,
                    label = waterSource.promptText or 'Fill Water Bucket',
                    icon = 'fa-solid fa-droplet',
                    onSelect = function()
                        TriggerEvent('rex-ranch:client:fillWaterBucket', {args = {waterSource = waterSource}})
                    end,
                    canInteract = function()
                        -- Check if player has empty or partial bucket
                        local hasEmptyBucket = RSGCore.Functions.HasItem(Config.EmptyWaterBucket, 1)
                        local hasPartialBucket = RSGCore.Functions.HasItem(Config.WaterItem, 1)
                        return hasEmptyBucket or hasPartialBucket
                    end
                }
            }
        })
        
        -- Create blip if enabled
        if waterSource.showblip then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, waterSource.coords)
            SetBlipSprite(blip, GetHashKey(waterSource.blipsprite), true)
            SetBlipScale(blip, 0.2)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, waterSource.blipname)
        end
    end
end)

---------------------------------------------
-- fill water bucket event
---------------------------------------------
RegisterNetEvent('rex-ranch:client:fillWaterBucket', function(data)
    local waterSource = data.args.waterSource
    
    if not waterSource then
        lib.notify({type = 'error', description = 'Invalid water source!'})
        return
    end
    
    -- Check if player has empty bucket or partially used bucket
    local hasEmptyBucket = RSGCore.Functions.HasItem(Config.EmptyWaterBucket, 1)
    local hasPartialBucket = RSGCore.Functions.HasItem(Config.WaterItem, 1)
    
    if not hasEmptyBucket and not hasPartialBucket then
        lib.notify({type = 'error', description = 'You need a water bucket to fill!'})
        return
    end
    
    -- Start filling animation
    lib.notify({type = 'info', description = 'Filling water bucket...'})
    
    TaskTurnPedToFaceCoord(cache.ped, waterSource.coords.x, waterSource.coords.y, waterSource.coords.z, 2000)
    Wait(1500)
    FreezeEntityPosition(cache.ped, true)
    TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_BUCKET_FILL_WATER`, 0, true)
    
    -- Wait for animation
    Wait(5000)
    
    ClearPedTasks(cache.ped)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    FreezeEntityPosition(cache.ped, false)
    
    -- Trigger server to refill bucket
    TriggerServerEvent('rex-ranch:server:fillWaterBucket')
end)
