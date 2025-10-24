# Rex Ranch - Exports Documentation

This document lists all available exports for the rex-ranch resource that can be used by other resources.

**IMPORTANT:** All animal interaction exports respect the rule that **only ranch staff are allowed to target and interact with animals**.

---

## Server-Side Exports

### `isPlayerRanchStaff`
Check if a player is employed at any ranch.

**Usage:**
```lua
local isStaff, ranchId = exports['rex-ranch']:isPlayerRanchStaff(playerId)
```

**Parameters:**
- `playerId` (number) - The server ID of the player

**Returns:**
- `isStaff` (boolean) - True if player is ranch staff, false otherwise
- `ranchId` (string) - The ranch ID where the player works (only if isStaff is true)

**Example:**
```lua
local isStaff, ranchId = exports['rex-ranch']:isPlayerRanchStaff(source)
if isStaff then
    print('Player works at ranch: ' .. ranchId)
end
```

---

### `getPlayerRanchId`
Get the ranch ID where a player is employed.

**Usage:**
```lua
local ranchId = exports['rex-ranch']:getPlayerRanchId(playerId)
```

**Parameters:**
- `playerId` (number) - The server ID of the player

**Returns:**
- `ranchId` (string|nil) - The ranch ID or nil if not employed

---

### `getRanchAnimalCount`
Get the total number of animals at a specific ranch.

**Usage:**
```lua
local count = exports['rex-ranch']:getRanchAnimalCount(ranchid)
```

**Parameters:**
- `ranchid` (string) - The ranch identifier

**Returns:**
- `count` (number) - Number of animals at the ranch

**Example:**
```lua
local count = exports['rex-ranch']:getRanchAnimalCount('emeraldranch')
print('Emerald Ranch has ' .. count .. ' animals')
```

---

### `getRanchAnimals`
Get all animals belonging to a specific ranch.

**Usage:**
```lua
local animals = exports['rex-ranch']:getRanchAnimals(ranchid)
```

**Parameters:**
- `ranchid` (string) - The ranch identifier

**Returns:**
- `animals` (table) - Array of animal data objects

**Example:**
```lua
local animals = exports['rex-ranch']:getRanchAnimals('emeraldranch')
for _, animal in ipairs(animals) do
    print('Animal ID: ' .. animal.animalid .. ', Model: ' .. animal.model)
end
```

---

### `getAnimalData`
Get data for a specific animal by its ID.

**Usage:**
```lua
local animalData = exports['rex-ranch']:getAnimalData(animalid)
```

**Parameters:**
- `animalid` (number) - The unique animal identifier

**Returns:**
- `animalData` (table|nil) - Animal data object or nil if not found

**Example:**
```lua
local animal = exports['rex-ranch']:getAnimalData(123456)
if animal then
    print('Animal health: ' .. animal.health)
    print('Animal hunger: ' .. animal.hunger)
    print('Animal thirst: ' .. animal.thirst)
end
```

---

### `addAnimalToRanch`
Add a new animal to a ranch. Automatically generates a unique animal ID and sets default stats.

**Usage:**
```lua
local animalid = exports['rex-ranch']:addAnimalToRanch(ranchid, model, gender, pos_x, pos_y, pos_z, pos_w)
```

**Parameters:**
- `ranchid` (string) - The ranch identifier
- `model` (string) - The animal model (e.g., 'a_c_cow', 'a_c_bull_01')
- `gender` (string|nil) - 'male' or 'female' (auto-determined if nil)
- `pos_x` (number|nil) - X coordinate (default 0)
- `pos_y` (number|nil) - Y coordinate (default 0)
- `pos_z` (number|nil) - Z coordinate (default 0)
- `pos_w` (number|nil) - Heading (default 0)

**Returns:**
- `animalid` (number|false) - The new animal ID or false on failure

**Example:**
```lua
local animalid = exports['rex-ranch']:addAnimalToRanch('emeraldranch', 'a_c_cow', 'female', 1400.0, 290.0, 88.0, 0.0)
if animalid then
    print('Created new cow with ID: ' .. animalid)
end
```

---

### `removeAnimalFromRanch`
Remove an animal from the database and despawn it for all clients.

**Usage:**
```lua
local success = exports['rex-ranch']:removeAnimalFromRanch(animalid)
```

**Parameters:**
- `animalid` (number) - The unique animal identifier

**Returns:**
- `success` (boolean) - True if successfully removed, false otherwise

**Example:**
```lua
local success = exports['rex-ranch']:removeAnimalFromRanch(123456)
if success then
    print('Animal removed successfully')
end
```

---

### `updateAnimalStats`
Update specific stats for an animal (health, hunger, thirst, age).

**Usage:**
```lua
local success = exports['rex-ranch']:updateAnimalStats(animalid, stats)
```

**Parameters:**
- `animalid` (number) - The unique animal identifier
- `stats` (table) - Table containing stats to update
  - `health` (number) - Health value (0-100)
  - `hunger` (number) - Hunger value (0-100)
  - `thirst` (number) - Thirst value (0-100)
  - `age` (number) - Age in days

**Returns:**
- `success` (boolean) - True if successfully updated, false otherwise

**Example:**
```lua
local success = exports['rex-ranch']:updateAnimalStats(123456, {
    health = 95,
    hunger = 80,
    thirst = 75
})
```

---

### `getStaffCount`
Get the number of ranch staff currently employed at a specific ranch.

**Usage:**
```lua
local staffCount = exports['rex-ranch']:getStaffCount(ranchid)
```

**Parameters:**
- `ranchid` (string) - The ranch identifier

**Returns:**
- `staffCount` (number) - Number of online players employed at the ranch

**Example:**
```lua
local staffCount = exports['rex-ranch']:getStaffCount('emeraldranch')
print('Emerald Ranch currently has ' .. staffCount .. ' staff members online')
```

**Note:** This only counts currently online players. For total staff including offline players, you would need to query your database directly.

---

### `getRanchStatistics`
Get comprehensive statistics for a ranch.

**Usage:**
```lua
local stats = exports['rex-ranch']:getRanchStatistics(ranchid)
```

**Parameters:**
- `ranchid` (string) - The ranch identifier

**Returns:**
- `stats` (table|nil) - Statistics object containing:
  - `total` (number) - Total animal count
  - `byType` (table) - Count by animal model
  - `byGender` (table) - Count by gender (male/female)
  - `pregnant` (number) - Number of pregnant animals
  - `unhealthy` (number) - Animals with health < 70
  - `needsFood` (number) - Animals with hunger < 50
  - `needsWater` (number) - Animals with thirst < 50
  - `producing` (number) - Animals with products ready

**Example:**
```lua
local stats = exports['rex-ranch']:getRanchStatistics('emeraldranch')
if stats then
    print('Total animals: ' .. stats.total)
    print('Cows: ' .. (stats.byType['a_c_cow'] or 0))
    print('Bulls: ' .. (stats.byType['a_c_bull_01'] or 0))
    print('Pregnant: ' .. stats.pregnant)
    print('Unhealthy: ' .. stats.unhealthy)
end
```

---

## Client-Side Exports

### `isLocalPlayerRanchStaff`
Check if the local player is employed at any ranch.

**Usage:**
```lua
local isStaff, ranchId = exports['rex-ranch']:isLocalPlayerRanchStaff()
```

**Returns:**
- `isStaff` (boolean) - True if player is ranch staff
- `ranchId` (string) - The ranch ID where the player works (only if isStaff is true)

---

### `getLocalPlayerRanchId`
Get the ranch ID where the local player is employed.

**Usage:**
```lua
local ranchId = exports['rex-ranch']:getLocalPlayerRanchId()
```

**Returns:**
- `ranchId` (string|nil) - The ranch ID or nil if not employed

---

### `canInteractWithAnimal`
Check if the local player can interact with an animal (enforces staff rule).

**Usage:**
```lua
local canInteract, reason = exports['rex-ranch']:canInteractWithAnimal(animalid)
```

**Parameters:**
- `animalid` (number) - The unique animal identifier

**Returns:**
- `canInteract` (boolean) - True if interaction is allowed
- `reason` (string) - "OK" if allowed, or error message if not

**Example:**
```lua
local canInteract, reason = exports['rex-ranch']:canInteractWithAnimal(123456)
if not canInteract then
    print('Cannot interact: ' .. reason)
end
```

---

### `getRanchLocation`
Get complete location data for a specific ranch.

**Usage:**
```lua
local ranchData = exports['rex-ranch']:getRanchLocation(ranchid)
```

**Parameters:**
- `ranchid` (string) - The ranch identifier

**Returns:**
- `ranchData` (table|nil) - Ranch configuration data

---

### `getAllRanchLocations`
Get all configured ranch locations.

**Usage:**
```lua
local ranches = exports['rex-ranch']:getAllRanchLocations()
```

**Returns:**
- `ranches` (table) - Array of all ranch configurations

---

### `getAllSalePointLocations`
Get all livestock market sale point locations.

**Usage:**
```lua
local salePoints = exports['rex-ranch']:getAllSalePointLocations()
```

**Returns:**
- `salePoints` (table) - Array of sale point configurations

---

### `getAllBuyPointLocations`
Get all livestock dealer buy point locations.

**Usage:**
```lua
local buyPoints = exports['rex-ranch']:getAllBuyPointLocations()
```

**Returns:**
- `buyPoints` (table) - Array of buy point configurations

---

### `getNearestRanch`
Find the nearest ranch to the local player.

**Usage:**
```lua
local ranch, distance = exports['rex-ranch']:getNearestRanch()
```

**Returns:**
- `ranch` (table|nil) - Nearest ranch data
- `distance` (number|nil) - Distance in units

**Example:**
```lua
local ranch, distance = exports['rex-ranch']:getNearestRanch()
if ranch then
    print('Nearest ranch: ' .. ranch.name .. ' (' .. math.floor(distance) .. 'm away)')
end
```

---

### `isNearRanch`
Check if the local player is near any ranch.

**Usage:**
```lua
local isNear, ranch, distance = exports['rex-ranch']:isNearRanch(maxDistance)
```

**Parameters:**
- `maxDistance` (number|nil) - Maximum distance to check (default: 50.0)

**Returns:**
- `isNear` (boolean) - True if near a ranch
- `ranch` (table|nil) - Ranch data if near
- `distance` (number|nil) - Distance to ranch if near

---

### `getAnimalProductInfo`
Get production configuration for an animal model.

**Usage:**
```lua
local productInfo = exports['rex-ranch']:getAnimalProductInfo(animalModel)
```

**Parameters:**
- `animalModel` (string) - Animal model (e.g., 'a_c_cow')

**Returns:**
- `productInfo` (table|nil) - Product configuration

**Example:**
```lua
local info = exports['rex-ranch']:getAnimalProductInfo('a_c_cow')
if info then
    print('Product: ' .. info.product)
    print('Production time: ' .. info.productionTime .. ' seconds')
end
```

---

### `getBreedingConfig`
Get breeding configuration for an animal model.

**Usage:**
```lua
local breedingConfig = exports['rex-ranch']:getBreedingConfig(animalModel)
```

**Parameters:**
- `animalModel` (string) - Animal model (e.g., 'a_c_cow')

**Returns:**
- `breedingConfig` (table|nil) - Breeding configuration

---

### `hasPermission`
Check if the local player has a specific permission based on their job grade.

**Usage:**
```lua
local hasPermission = exports['rex-ranch']:hasPermission(permissionName)
```

**Parameters:**
- `permissionName` (string) - Permission to check (e.g., 'canBuy', 'canSell', 'canManageStaff')

**Returns:**
- `hasPermission` (boolean) - True if player has permission

**Example:**
```lua
if exports['rex-ranch']:hasPermission('canBuy') then
    -- Show buy menu
end
```

---

### `getPlayerJobGrade`
Get the local player's current job grade level.

**Usage:**
```lua
local grade = exports['rex-ranch']:getPlayerJobGrade()
```

**Returns:**
- `grade` (number) - Job grade level (0-3)

---

### `getNearestWaterSource`
Find the nearest water source to the local player.

**Usage:**
```lua
local waterSource, distance = exports['rex-ranch']:getNearestWaterSource()
```

**Returns:**
- `waterSource` (table|nil) - Water source data
- `distance` (number|nil) - Distance to water source

---

## Usage Examples

### Example 1: Custom Admin Command to Heal All Ranch Animals
```lua
-- Server-side
RegisterCommand('healranch', function(source, args)
    local ranchid = args[1]
    if not ranchid then
        TriggerClientEvent('chat:addMessage', source, { args = { 'Usage: /healranch [ranchid]' } })
        return
    end
    
    local animals = exports['rex-ranch']:getRanchAnimals(ranchid)
    local healedCount = 0
    
    for _, animal in ipairs(animals) do
        local success = exports['rex-ranch']:updateAnimalStats(animal.animalid, {
            health = 100,
            hunger = 100,
            thirst = 100
        })
        
        if success then
            healedCount = healedCount + 1
        end
    end
    
    TriggerClientEvent('chat:addMessage', source, { 
        args = { 'Healed ' .. healedCount .. ' animals at ' .. ranchid } 
    })
end, true)
```

### Example 2: Display Ranch Stats Command
```lua
-- Server-side
RegisterCommand('ranchstats', function(source, args)
    local ranchid = exports['rex-ranch']:getPlayerRanchId(source)
    
    if not ranchid then
        TriggerClientEvent('chat:addMessage', source, { 
            args = { 'You must be employed at a ranch!' } 
        })
        return
    end
    
    local stats = exports['rex-ranch']:getRanchStatistics(ranchid)
    
    if stats then
        TriggerClientEvent('chat:addMessage', source, { 
            args = { '=== Ranch Statistics ===' } 
        })
        TriggerClientEvent('chat:addMessage', source, { 
            args = { 'Total Animals: ' .. stats.total } 
        })
        TriggerClientEvent('chat:addMessage', source, { 
            args = { 'Pregnant: ' .. stats.pregnant } 
        })
        TriggerClientEvent('chat:addMessage', source, { 
            args = { 'Needs Care: ' .. (stats.unhealthy + stats.needsFood + stats.needsWater) } 
        })
    end
end)
```

### Example 3: Client-Side Ranch Proximity Check
```lua
-- Client-side
CreateThread(function()
    while true do
        Wait(5000) -- Check every 5 seconds
        
        local isNear, ranch, distance = exports['rex-ranch']:isNearRanch(100.0)
        
        if isNear then
            print('You are near ' .. ranch.name .. ' (' .. math.floor(distance) .. 'm)')
        end
    end
end)
```

---

## Important Notes

1. **Staff Rule Enforcement**: All animal interaction exports enforce the rule that only ranch staff can interact with animals. Always check `isPlayerRanchStaff()` or `canInteractWithAnimal()` before performing actions.

2. **Database Updates**: Server exports that modify the database automatically trigger client updates via the existing sync system.

3. **Performance**: Use exports responsibly - avoid calling them in tight loops or very frequently as they may involve database queries.

4. **Error Handling**: Always check return values for nil/false before using them, as exports may fail if invalid data is provided.
