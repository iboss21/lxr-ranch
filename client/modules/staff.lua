--[[ ═══════════════════════════════════════════════════════════════════════════
     🐺 LXR-RANCH — The Land of Wolves
     ═══════════════════════════════════════════════════════════════════════════
     Developer   : iBoss21 | Brand : The Lux Empire
     https://www.wolves.land | https://discord.gg/CrKcWdfd3A
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / The Lux Empire — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]
local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------------------
-- Open Staff Management Menu
---------------------------------------------
RegisterNetEvent('lxr-ranch:client:openStaffManagement', function(ranchid)
    if not ranchid then return end
    
    -- Request staff data from server
    RSGCore.Functions.TriggerCallback('lxr-ranch:server:getStaffList', function(staffData)
        if not staffData then
            lib.notify({type = 'error', description = 'Failed to load staff data!'})
            return
        end
        
        -- Build staff management menu
        local options = {
            {
                title = '👥 View All Staff',
                description = 'View all employees at this ranch',
                icon = 'fa-solid fa-users',
                onSelect = function()
                    OpenStaffListMenu(ranchid, staffData)
                end
            },
            {
                title = '➕ Hire Employee',
                description = 'Hire a new employee for the ranch',
                icon = 'fa-solid fa-user-plus',
                onSelect = function()
                    OpenHireMenu(ranchid)
                end
            },
        }
        
        lib.registerContext({
            id = 'staff_management_menu',
            title = '🏢 Staff Management',
            options = options
        })
        lib.showContext('staff_management_menu')
    end, ranchid)
end)

---------------------------------------------
-- Staff List Menu
---------------------------------------------
function OpenStaffListMenu(ranchid, staffData)
    local options = {}
    
    if not staffData or #staffData.employees == 0 then
        table.insert(options, {
            title = 'No employees found',
            description = 'This ranch has no employees yet',
            icon = 'fa-solid fa-info-circle',
            disabled = true
        })
    else
        for _, employee in ipairs(staffData.employees) do
            local gradeLabel = employee.grade_label or 'Unknown'
            local onlineStatus = employee.is_online and '🟢 Online' or '⚫ Offline'
            
            table.insert(options, {
                title = employee.name,
                description = gradeLabel .. ' | ' .. onlineStatus,
                icon = 'fa-solid fa-user',
                onSelect = function()
                    OpenEmployeeActionsMenu(ranchid, employee)
                end
            })
        end
    end
    
    table.insert(options, {
        title = '⬅️ Back',
        icon = 'fa-solid fa-arrow-left',
        onSelect = function()
            TriggerEvent('lxr-ranch:client:openStaffManagement', ranchid)
        end
    })
    
    lib.registerContext({
        id = 'staff_list_menu',
        title = '👥 Staff List (' .. #staffData.employees .. '/' .. Config.StaffManagement.MaxEmployeesPerRanch .. ')',
        options = options
    })
    lib.showContext('staff_list_menu')
end

---------------------------------------------
-- Employee Actions Menu
---------------------------------------------
function OpenEmployeeActionsMenu(ranchid, employee)
    local options = {
        {
            title = '📊 View Details',
            description = 'View employee information',
            icon = 'fa-solid fa-info-circle',
            onSelect = function()
                OpenEmployeeDetailsMenu(ranchid, employee)
            end
        },
        {
            title = '⬆️ Promote',
            description = 'Promote employee to next grade',
            icon = 'fa-solid fa-arrow-up',
            onSelect = function()
                TriggerServerEvent('lxr-ranch:server:promoteEmployee', ranchid, employee.citizenid)
                Wait(500)
                TriggerEvent('lxr-ranch:client:openStaffManagement', ranchid)
            end
        },
        {
            title = '⬇️ Demote',
            description = 'Demote employee to previous grade',
            icon = 'fa-solid fa-arrow-down',
            onSelect = function()
                TriggerServerEvent('lxr-ranch:server:demoteEmployee', ranchid, employee.citizenid)
                Wait(500)
                TriggerEvent('lxr-ranch:client:openStaffManagement', ranchid)
            end
        },
        {
            title = '❌ Fire Employee',
            description = 'Remove employee from ranch',
            icon = 'fa-solid fa-user-times',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Confirm Termination',
                    content = 'Are you sure you want to fire ' .. employee.name .. '?',
                    centered = true,
                    cancel = true
                })
                
                if confirm == 'confirm' then
                    TriggerServerEvent('lxr-ranch:server:fireEmployee', ranchid, employee.citizenid)
                    Wait(500)
                    TriggerEvent('lxr-ranch:client:openStaffManagement', ranchid)
                end
            end
        },
        {
            title = '⬅️ Back',
            icon = 'fa-solid fa-arrow-left',
            onSelect = function()
                TriggerEvent('lxr-ranch:client:openStaffManagement', ranchid)
            end
        }
    }
    
    lib.registerContext({
        id = 'employee_actions_menu',
        title = '👤 ' .. employee.name,
        options = options
    })
    lib.showContext('employee_actions_menu')
end

---------------------------------------------
-- Employee Details Menu
---------------------------------------------
function OpenEmployeeDetailsMenu(ranchid, employee)
    local options = {
        {
            title = 'Name',
            description = employee.name,
            icon = 'fa-solid fa-id-card',
            disabled = true
        },
        {
            title = 'Position',
            description = employee.grade_label or 'Unknown',
            icon = 'fa-solid fa-briefcase',
            disabled = true
        },
        {
            title = 'Status',
            description = employee.is_online and 'Online' or 'Offline',
            icon = employee.is_online and 'fa-solid fa-circle-check' or 'fa-solid fa-circle-xmark',
            disabled = true
        },
        {
            title = '⬅️ Back',
            icon = 'fa-solid fa-arrow-left',
            onSelect = function()
                OpenEmployeeActionsMenu(ranchid, employee)
            end
        }
    }
    
    lib.registerContext({
        id = 'employee_details_menu',
        title = '📋 Employee Details',
        options = options
    })
    lib.showContext('employee_details_menu')
end

---------------------------------------------
-- Hire Employee Menu
---------------------------------------------
function OpenHireMenu(ranchid)
    -- Get nearby players
    RSGCore.Functions.TriggerCallback('lxr-ranch:server:getNearbyPlayers', function(nearbyPlayers)
        if not nearbyPlayers or #nearbyPlayers == 0 then
            lib.notify({type = 'error', description = 'No nearby players found!'})
            return
        end
        
        local options = {}
        
        for _, player in ipairs(nearbyPlayers) do
            table.insert(options, {
                title = player.name,
                description = 'ID: ' .. player.id .. ' | Distance: ' .. math.floor(player.distance) .. 'm',
                icon = 'fa-solid fa-user',
                onSelect = function()
                    OpenHireConfirmDialog(ranchid, player)
                end
            })
        end
        
        table.insert(options, {
            title = '⬅️ Back',
            icon = 'fa-solid fa-arrow-left',
            onSelect = function()
                TriggerEvent('lxr-ranch:client:openStaffManagement', ranchid)
            end
        })
        
        lib.registerContext({
            id = 'hire_menu',
            title = '➕ Hire Employee',
            options = options
        })
        lib.showContext('hire_menu')
    end)
end

---------------------------------------------
-- Hire Confirmation Dialog
---------------------------------------------
function OpenHireConfirmDialog(ranchid, player)
    local input = lib.inputDialog('Hire ' .. player.name, {
        {
            type = 'select',
            label = 'Starting Grade',
            description = 'Select the starting position',
            required = true,
            options = {
                {value = 0, label = 'Trainee'},
                {value = 1, label = 'Ranch Hand'},
                {value = 2, label = 'Manager'},
            }
        }
    })
    
    if input then
        TriggerServerEvent('lxr-ranch:server:hireEmployee', ranchid, player.id, input[1])
        Wait(500)
        TriggerEvent('lxr-ranch:client:openStaffManagement', ranchid)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 wolves.land — The Land of Wolves
-- © 2026 iBoss21 / The Lux Empire — All Rights Reserved
-- ═══════════════════════════════════════════════════════════════════════════════
