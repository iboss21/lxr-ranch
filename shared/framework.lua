--[[
    ██╗     ██╗  ██╗██████╗       ██████╗  █████╗ ███╗   ██╗ ██████╗██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗      ██╔══██╗██╔══██╗████╗  ██║██╔════╝██║  ██║
    ██║      ╚███╔╝ ██████╔╝█████╗██████╔╝███████║██╔██╗ ██║██║     ███████║
    ██║      ██╔██╗ ██╔══██╗╚════╝██╔══██╗██╔══██║██║╚██╗██║██║     ██╔══██║
    ███████╗██╔╝ ██╗██║  ██║      ██║  ██║██║  ██║██║ ╚████║╚██████╗██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝

    🐺 LXR Core - Framework Bridge

    Multi-framework compatibility bridge for lxr-ranch. Auto-detects and
    normalizes API calls across LXR Core, RSG Core, VORP Core, and Standalone
    environments, providing a single unified interface for all resource logic.
    Safe to load on both server and client sides.

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Server:      The Land of Wolves 🐺
    Tagline:     Georgian RP 🇬🇪 | მგლების მიწა - რჩეულთა ადგილი!
    Description: ისტორია ცოცხლდება აქ! (History Lives Here!)
    Type:        Serious Hardcore Roleplay
    Access:      Discord & Whitelisted

    Developer:   iBoss21 / The Lux Empire
    Website:     https://www.wolves.land
    Discord:     https://discord.gg/CrKcWdfd3A
    GitHub:      https://github.com/iBoss21
    Store:       https://theluxempire.tebex.io
    Server:      https://servers.redm.net/servers/detail/8gj7eb

    ═══════════════════════════════════════════════════════════════════════════════
    CREDITS
    ═══════════════════════════════════════════════════════════════════════════════

    Script Author: iBoss21 / The Lux Empire for The Land of Wolves
    Original Concept: LXR Ranch (Community Contribution)

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ INITIALIZATION ████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Framework = {}

local isServer = IsDuplicityVersion()
local CoreObject = nil
local detectedFramework = nil

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ FRAMEWORK DETECTION ███████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

--- Check if a given resource is started
--- @param resourceName string
--- @return boolean
local function IsResourceStarted(resourceName)
    local state = GetResourceState(resourceName)
    return state == 'started' or state == 'starting'
end

--- Attempt auto-detection of the active framework in priority order
--- @return string frameworkName
local function AutoDetectFramework()
    if IsResourceStarted('lxr-core') then
        return 'lxr-core'
    elseif IsResourceStarted('rsg-core') then
        return 'rsg-core'
    elseif IsResourceStarted('vorp_core') then
        return 'vorp_core'
    end
    return 'standalone'
end

--- Resolve framework from Config or auto-detect
--- @return string frameworkName
local function ResolveFramework()
    local configured = Config and Config.Framework or 'auto'

    if configured == 'auto' or configured == nil then
        return AutoDetectFramework()
    end

    -- Validate manual setting
    local valid = { ['lxr-core'] = true, ['rsg-core'] = true, ['vorp_core'] = true, ['standalone'] = true }
    if valid[configured] then
        if configured ~= 'standalone' and not IsResourceStarted(configured) then
            print('^1[lxr-ranch] WARNING: Configured framework "' .. configured .. '" is not running! Falling back to auto-detect.^0')
            return AutoDetectFramework()
        end
        return configured
    end

    print('^1[lxr-ranch] WARNING: Unknown framework "' .. tostring(configured) .. '" in Config.Framework. Falling back to auto-detect.^0')
    return AutoDetectFramework()
end

detectedFramework = ResolveFramework()
Framework.name = detectedFramework

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ CORE OBJECT LOADING ███████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

if detectedFramework == 'lxr-core' then
    local ok, result = pcall(function()
        return exports['lxr-core']:GetCoreObject()
    end)
    if ok and result then
        CoreObject = result
        print('^2[lxr-ranch] Framework bridge loaded: LXR Core ^0')
    else
        print('^1[lxr-ranch] ERROR: Failed to get LXR Core object. Falling back to standalone.^0')
        detectedFramework = 'standalone'
        Framework.name = 'standalone'
    end
elseif detectedFramework == 'rsg-core' then
    local ok, result = pcall(function()
        return exports['rsg-core']:GetCoreObject()
    end)
    if ok and result then
        CoreObject = result
        print('^2[lxr-ranch] Framework bridge loaded: RSG Core ^0')
    else
        print('^1[lxr-ranch] ERROR: Failed to get RSG Core object. Falling back to standalone.^0')
        detectedFramework = 'standalone'
        Framework.name = 'standalone'
    end
elseif detectedFramework == 'vorp_core' then
    print('^2[lxr-ranch] Framework bridge loaded: VORP Core ^0')
elseif detectedFramework == 'standalone' then
    print('^3[lxr-ranch] Framework bridge loaded: Standalone (limited functionality) ^0')
end

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SERVER-SIDE FUNCTIONS ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

if isServer then

    -- ═══════════════════════════════════════════════════════════════════════════
    -- GetPlayer — Returns the framework player object for a given source
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.GetPlayer(source)
            if not CoreObject then return nil end
            local ok, player = pcall(function()
                return CoreObject.Functions.GetPlayer(source)
            end)
            return ok and player or nil
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.GetPlayer(source)
            local ok, user = pcall(function()
                return exports.vorp_core:getUser(source)
            end)
            if ok and user then
                return user.getUsedCharacter
            end
            return nil
        end
    else
        function Framework.GetPlayer(source)
            return { source = source }
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- GetIdentifier — Returns the citizen ID / character identifier
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.GetIdentifier(source)
            local player = Framework.GetPlayer(source)
            if player and player.PlayerData then
                return player.PlayerData.citizenid
            end
            return nil
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.GetIdentifier(source)
            local character = Framework.GetPlayer(source)
            if character then
                return character.identifier
            end
            return nil
        end
    else
        function Framework.GetIdentifier(source)
            return tostring(source)
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- GetPlayerName — Returns formatted first + last name
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.GetPlayerName(source)
            local player = Framework.GetPlayer(source)
            if player and player.PlayerData and player.PlayerData.charinfo then
                local charinfo = player.PlayerData.charinfo
                return (charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or '')
            end
            return 'Unknown'
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.GetPlayerName(source)
            local character = Framework.GetPlayer(source)
            if character then
                return (character.firstname or 'Unknown') .. ' ' .. (character.lastname or '')
            end
            return 'Unknown'
        end
    else
        function Framework.GetPlayerName(source)
            return GetPlayerName(source) or 'Unknown'
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- GetJob — Returns { name, grade, label } for the player's job
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.GetJob(source)
            local player = Framework.GetPlayer(source)
            if player and player.PlayerData and player.PlayerData.job then
                local job = player.PlayerData.job
                return {
                    name  = job.name or 'unemployed',
                    grade = job.grade and job.grade.level or 0,
                    label = job.grade and job.grade.name or 'None'
                }
            end
            return { name = 'unemployed', grade = 0, label = 'None' }
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.GetJob(source)
            local character = Framework.GetPlayer(source)
            if character then
                return {
                    name  = character.job or 'unemployed',
                    grade = character.jobGrade or 0,
                    label = character.jobLabel or 'None'
                }
            end
            return { name = 'unemployed', grade = 0, label = 'None' }
        end
    else
        function Framework.GetJob(source)
            return { name = 'unemployed', grade = 0, label = 'None' }
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- SetJob — Sets the player's job and grade
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.SetJob(source, jobName, grade)
            local player = Framework.GetPlayer(source)
            if player and player.Functions and player.Functions.SetJob then
                return player.Functions.SetJob(jobName, grade)
            end
            return false
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.SetJob(source, jobName, grade)
            local character = Framework.GetPlayer(source)
            if character and character.setJob then
                character.setJob(jobName)
                character.setJobGrade(grade)
                return true
            end
            return false
        end
    else
        function Framework.SetJob(source, jobName, grade)
            print(('[lxr-ranch] Standalone: SetJob called for %s -> %s grade %s'):format(source, jobName, grade))
            return false
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- AddItem — Adds an item to the player's inventory
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.AddItem(source, item, count)
            local player = Framework.GetPlayer(source)
            if player and player.Functions and player.Functions.AddItem then
                return player.Functions.AddItem(item, count or 1)
            end
            return false
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.AddItem(source, item, count)
            local ok, result = pcall(function()
                return exports.vorp_inventory:addItem(source, item, count or 1)
            end)
            return ok and result
        end
    else
        function Framework.AddItem(source, item, count)
            print(('[lxr-ranch] Standalone: AddItem %s x%d to player %s'):format(item, count or 1, source))
            return false
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- RemoveItem — Removes an item from the player's inventory
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.RemoveItem(source, item, count)
            local player = Framework.GetPlayer(source)
            if player and player.Functions and player.Functions.RemoveItem then
                return player.Functions.RemoveItem(item, count or 1)
            end
            return false
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.RemoveItem(source, item, count)
            local ok, result = pcall(function()
                return exports.vorp_inventory:subItem(source, item, count or 1)
            end)
            return ok and result
        end
    else
        function Framework.RemoveItem(source, item, count)
            print(('[lxr-ranch] Standalone: RemoveItem %s x%d from player %s'):format(item, count or 1, source))
            return false
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- HasItem — Check if a player has a specific item (returns boolean)
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.HasItem(source, item, count)
            local player = Framework.GetPlayer(source)
            if player and player.Functions and player.Functions.GetItemByName then
                local itemData = player.Functions.GetItemByName(item)
                if itemData then
                    return (itemData.amount or itemData.count or 0) >= (count or 1)
                end
            end
            return false
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.HasItem(source, item, count)
            local ok, result = pcall(function()
                local itemCount = exports.vorp_inventory:getItemCount(source, item)
                return (itemCount or 0) >= (count or 1)
            end)
            return ok and result or false
        end
    else
        function Framework.HasItem(source, item, count)
            return false
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- GetItemByName — Returns item data for a specific item
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.GetItemByName(source, item)
            local player = Framework.GetPlayer(source)
            if player and player.Functions and player.Functions.GetItemByName then
                return player.Functions.GetItemByName(item)
            end
            return nil
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.GetItemByName(source, item)
            local ok, result = pcall(function()
                return exports.vorp_inventory:getItem(source, item)
            end)
            return ok and result or nil
        end
    else
        function Framework.GetItemByName(source, item)
            return nil
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- AddMoney — Adds money to the player (cash only, no gold)
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.AddMoney(source, amount, moneyType)
            local player = Framework.GetPlayer(source)
            if player and player.Functions and player.Functions.AddMoney then
                return player.Functions.AddMoney(moneyType or 'cash', amount, 'lxr-ranch')
            end
            return false
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.AddMoney(source, amount, moneyType)
            local character = Framework.GetPlayer(source)
            if character and character.addCurrency then
                -- VORP currency IDs: 0 = money, 1 = gold, 2 = rol
                local currencyId = 0
                character.addCurrency(currencyId, amount)
                return true
            end
            return false
        end
    else
        function Framework.AddMoney(source, amount, moneyType)
            print(('[lxr-ranch] Standalone: AddMoney $%s to player %s'):format(amount, source))
            return false
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- RemoveMoney — Removes money from the player
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.RemoveMoney(source, amount, moneyType)
            local player = Framework.GetPlayer(source)
            if player and player.Functions and player.Functions.RemoveMoney then
                return player.Functions.RemoveMoney(moneyType or 'cash', amount, 'lxr-ranch')
            end
            return false
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.RemoveMoney(source, amount, moneyType)
            local character = Framework.GetPlayer(source)
            if character and character.removeCurrency then
                local currencyId = 0
                character.removeCurrency(currencyId, amount)
                return true
            end
            return false
        end
    else
        function Framework.RemoveMoney(source, amount, moneyType)
            print(('[lxr-ranch] Standalone: RemoveMoney $%s from player %s'):format(amount, source))
            return false
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- GetMoney — Returns the player's money amount
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.GetMoney(source, moneyType)
            local player = Framework.GetPlayer(source)
            if player and player.PlayerData and player.PlayerData.money then
                return player.PlayerData.money[moneyType or 'cash'] or 0
            end
            return 0
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.GetMoney(source, moneyType)
            local character = Framework.GetPlayer(source)
            if character then
                return character.money or 0
            end
            return 0
        end
    else
        function Framework.GetMoney(source, moneyType)
            return 0
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- Notify — Sends a notification to the player (server-side)
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.Notify(source, msg, type)
            TriggerClientEvent('ox_lib:notify', source, {
                type        = type or 'inform',
                description = msg
            })
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.Notify(source, msg, type)
            TriggerClientEvent('vorp:TipRight', source, msg, 4000)
        end
    else
        function Framework.Notify(source, msg, type)
            print(('[lxr-ranch] Notify [%s] -> %s: %s'):format(type or 'info', source, msg))
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- GetPlayers — Returns all online player server IDs
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.GetPlayers()
            if CoreObject and CoreObject.Functions and CoreObject.Functions.GetPlayers then
                return CoreObject.Functions.GetPlayers()
            end
            return GetPlayers()
        end
    else
        function Framework.GetPlayers()
            return GetPlayers()
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- GetPlayerByCitizenId — Finds an online player by their citizen ID
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.GetPlayerByCitizenId(citizenid)
            if CoreObject and CoreObject.Functions and CoreObject.Functions.GetPlayerByCitizenId then
                return CoreObject.Functions.GetPlayerByCitizenId(citizenid)
            end
            return nil
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.GetPlayerByCitizenId(citizenid)
            local players = GetPlayers()
            for _, playerId in ipairs(players) do
                local identifier = Framework.GetIdentifier(tonumber(playerId))
                if identifier == citizenid then
                    return Framework.GetPlayer(tonumber(playerId))
                end
            end
            return nil
        end
    else
        function Framework.GetPlayerByCitizenId(citizenid)
            return nil
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- CreateCallback — Registers a server callback
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.CreateCallback(name, cb)
            if CoreObject and CoreObject.Functions and CoreObject.Functions.CreateCallback then
                CoreObject.Functions.CreateCallback(name, cb)
                return true
            end
            return false
        end
    else
        -- Fallback: use ox_lib callbacks for VORP and standalone
        function Framework.CreateCallback(name, cb)
            local ok, _ = pcall(function()
                lib.callback.register(name, cb)
            end)
            if not ok then
                print('^1[lxr-ranch] Failed to register callback: ' .. name .. '. ox_lib may not be available.^0')
            end
            return ok
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- OpenInventory — Opens an inventory stash for the player
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' then
        function Framework.OpenInventory(source, stashName, stashData)
            local ok, _ = pcall(function()
                exports['lxr-inventory']:OpenInventory(source, stashName, stashData)
            end)
            return ok
        end
    elseif detectedFramework == 'rsg-core' then
        function Framework.OpenInventory(source, stashName, stashData)
            local ok, _ = pcall(function()
                exports['rsg-inventory']:OpenInventory(source, stashName, stashData)
            end)
            return ok
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.OpenInventory(source, stashName, stashData)
            local ok, _ = pcall(function()
                exports.vorp_inventory:openStash(source, stashName, stashData)
            end)
            return ok
        end
    else
        function Framework.OpenInventory(source, stashName, stashData)
            print(('[lxr-ranch] Standalone: No inventory system available. Stash "%s" requested by %s'):format(stashName, source))
            return false
        end
    end

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ CLIENT-SIDE FUNCTIONS ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

else

    -- ═══════════════════════════════════════════════════════════════════════════
    -- GetPlayerData — Returns the local player's data table
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.GetPlayerData()
            if CoreObject and CoreObject.Functions and CoreObject.Functions.GetPlayerData then
                return CoreObject.Functions.GetPlayerData()
            end
            return nil
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.GetPlayerData()
            local ok, user = pcall(function()
                return exports.vorp_core:getUser()
            end)
            if ok and user then
                return user.getUsedCharacter
            end
            return nil
        end
    else
        function Framework.GetPlayerData()
            return { source = GetPlayerServerId(PlayerId()) }
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- TriggerCallback — Triggers a server callback from the client
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.TriggerCallback(name, cb, ...)
            if CoreObject and CoreObject.Functions and CoreObject.Functions.TriggerCallback then
                CoreObject.Functions.TriggerCallback(name, cb, ...)
                return true
            end
            return false
        end
    else
        -- Fallback: use ox_lib callbacks for VORP and standalone
        function Framework.TriggerCallback(name, cb, ...)
            local ok, _ = pcall(function()
                local args = {...}
                lib.callback(name, false, function(result)
                    if cb then cb(result) end
                end, table.unpack(args))
            end)
            if not ok then
                print('^1[lxr-ranch] Failed to trigger callback: ' .. name .. '. ox_lib may not be available.^0')
            end
            return ok
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════════
    -- Notify — Shows a notification on the client
    -- ═══════════════════════════════════════════════════════════════════════════

    if detectedFramework == 'lxr-core' or detectedFramework == 'rsg-core' then
        function Framework.Notify(msg, type)
            local ok, _ = pcall(function()
                lib.notify({
                    type        = type or 'inform',
                    description = msg
                })
            end)
            if not ok then
                print('[lxr-ranch] ' .. (msg or ''))
            end
        end
    elseif detectedFramework == 'vorp_core' then
        function Framework.Notify(msg, type)
            TriggerEvent('vorp:TipRight', msg, 4000)
        end
    else
        function Framework.Notify(msg, type)
            print('[lxr-ranch] ' .. (msg or ''))
        end
    end

end

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ UTILITY / SHARED ██████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

--- Returns the detected framework name
--- @return string
function Framework.GetName()
    return detectedFramework
end

--- Returns the raw core object (use with caution)
--- @return table|nil
function Framework.GetCoreObject()
    return CoreObject
end

--- Returns true if the bridge is running server-side
--- @return boolean
function Framework.IsServer()
    return isServer
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 wolves.land — The Land of Wolves
-- © 2026 iBoss21 / The Lux Empire — All Rights Reserved
-- ═══════════════════════════════════════════════════════════════════════════════
