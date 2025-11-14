# Rex Ranch - Complete Documentation

## Overview

**Rex Ranch** is a comprehensive RedM (Red Dead Redemption 2) ranch management system built for the RSG Framework. It provides a complete simulation of ranching operations including animal management, breeding, production, herding, staff management, and livestock trading.

**Version:** 0.0.24  
**Framework:** RSG-Core  
**Dependencies:** ox_lib, oxmysql

---

## Table of Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Core Features](#core-features)
4. [Ranch Locations](#ranch-locations)
5. [Database Schema](#database-schema)
6. [API & Exports](#api--exports)
7. [Events](#events)
8. [Commands](#commands)
9. [Staff System](#staff-system)
10. [Animal Management](#animal-management)
11. [Breeding System](#breeding-system)
12. [Production System](#production-system)
13. [Troubleshooting](#troubleshooting)

---

## Installation

### Prerequisites
- RSG-Core framework
- ox_lib dependency
- oxmysql for database operations
- RedM server running Red Dead Redemption 2

### Setup Steps

1. **Add to Server Configuration**
   ```
   ensure rsg-core
   ensure ox_lib
   ensure rex-ranch
   ```

2. **Import Database**
   ```bash
   # Execute the SQL file in your database
   mysql < installation/rex-ranch.sql
   ```

3. **Add Items to Shared**
   ```lua
   -- Add contents of installation/shared_items.lua to your items config
   ```

4. **Add Jobs to Shared**
   ```lua
   -- Add contents of installation/shared_jobs.lua to your jobs config
   ```

5. **Enable in fxmanifest.lua**
   Ensure `lua54` is set to `'yes'` for Lua 5.4 support.

---

## Configuration

All configuration is handled through `/shared/config.lua`. Below are the key sections:

### Debug Settings
```lua
Config.Debug = false  -- Enable debug logging
```

### Animal ID Settings
```lua
Config.ANIMAL_ID_MIN = 100000
Config.ANIMAL_ID_MAX = 999999
Config.MAX_ID_LENGTH = 20
```

### NPC Settings
```lua
Config.DistanceSpawn = 50.0    -- Distance to spawn NPCs
Config.FadeIn = true            -- Fade in NPCs when spawning
```

### Ranch Settings
```lua
Config.StorageMinJobGrade = 1                  -- Min grade for storage access
Config.RanchStorageMaxWeight = 10000000        -- Max weight capacity
Config.RanchStorageMaxSlots = 100              -- Max item slots
Config.AnimalDistanceSpawn = 50.0              -- Distance to spawn animals
Config.AnimalFadeIn = true                     -- Fade in animations
Config.ServerNotify = true                     -- Show server notifications
Config.AnimalCronJob = '*/15 * * * *'          -- Cron job interval (15 mins)
Config.MaxRanchAnimals = 10                    -- Max animals per ranch
Config.UpdateClientsOnCron = true              -- Update clients after cron
Config.RefreshAfterCron = true                 -- Full refresh after cron
```

### Animal Survival Stats
```lua
Config.HungerDecayRate = 1                -- Hunger reduction per cycle
Config.ThirstDecayRate = 1                -- Thirst reduction per cycle
Config.HealthDecayRate = 1                -- Health loss when starving
Config.MinSurvivalStats = 0               -- Min stat before health decays
Config.HealthRegenerationRate = 2         -- Health recovery per cycle
Config.MinStatsForRegeneration = 80       -- Min hunger/thirst for recovery
Config.ImmediateHealthBoost = 5           -- Health boost from feeding
```

### Animal Wandering
```lua
Config.AnimalWanderingEnabled = true      -- Enable wandering behavior
Config.WanderRadius = 15.0                -- Max wander distance from spawn
Config.WanderMinDistance = 3.0            -- Min wander distance
Config.WanderSpeed = 1.0                  -- 1.0 = walk, 2.0 = jog
Config.WanderIdleTimeMin = 10000          -- Min idle time (ms)
Config.WanderIdleTimeMax = 30000          -- Max idle time (ms)
Config.WanderMoveTimeMin = 5000           -- Min movement time (ms)
Config.WanderMoveTimeMax = 15000          -- Max movement time (ms)
Config.WanderCheckInterval = 2000         -- Update frequency (ms)
```

### Feed & Water System
```lua
Config.FeedItem = 'animal_feed'           -- Feed item name
Config.WaterItem = 'water_bucket'         -- Water item name
Config.WaterBucketUses = 5                -- Uses per bucket
Config.WaterRefillCost = 0                -- Refill cost (0 = free)
```

### Herding System
```lua
Config.HerdingEnabled = true              -- Enable herding
Config.HerdingDistance = 25.0             -- Max detection distance
Config.HerdingMaxAnimals = 10             -- Max animals to herd
Config.HerdingFollowDistance = 3.0        -- Distance while following
Config.HerdingSpeed = 1.5                 -- Movement speed multiplier
Config.HerdingTimeout = 300               -- Auto-stop timeout (seconds)
Config.RequireHerdingTool = false          -- Require item to herd
Config.HerdingTool = 'weapon_lasso'       -- Item required (if enabled)
Config.IndividualSelectionEnabled = true  -- Allow individual selection
Config.ShowAnimalDistance = true          -- Show distance in menu
Config.SelectionRangeMultiplier = 1.5     -- Selection range multiplier
```

### Pricing Configuration
```lua
Config.BullBuyPrice = 100
Config.BullSellPrice = 1
Config.CowBuyPrice = 50
Config.CowSellPrice = 1

-- Age-based pricing multipliers
Config.AgePricing = {
    young = 0.5,    -- Below prime age
    prime = 1.5,    -- Prime age range
    adult = 1.0,    -- Between prime and old
    old = 0.7       -- Old age
}

-- Base selling prices (modified by age)
Config.BaseSellPrices = {
    ['a_c_bull_01'] = 400,
    ['a_c_cow'] = 150
}
```

### Sale Point Settings
```lua
Config.AnimalSaleDistance = 15.0          -- Min distance to sale point
Config.RequireAnimalPresent = true        -- Require physical animal
Config.TransportMode = true               -- Keep animals spawned while herding
```

### Breeding Configuration
```lua
Config.BreedingEnabled = true
Config.MinAgeForBreeding = 5              -- Minimum age in days
Config.MaxBreedingAge = 30                -- Maximum breeding age
Config.BreedingDistance = 10.0            -- Distance between animals
Config.BreedingCooldown = 86400           -- Default cooldown (1 day)
Config.RequireHealthForBreeding = 70      -- Min health required
Config.RestrictMaleBreedingWhenFemalesPregnant = true
Config.RequireHungerForBreeding = 50      -- Min hunger stat
Config.RequireThirstForBreeding = 50      -- Min thirst stat

-- Gender-specific cooldowns
Config.GenderSpecificCooldowns = {
    male = 3600,    -- 1 hour for bulls
    female = 86400  -- 24 hours for cows
}

-- Gender ratios when buying
Config.GenderRatios = {
    ['a_c_bull_01'] = 1.0,  -- 100% male
    ['a_c_cow'] = 0.0       -- 100% female
}

-- Breeding configuration per animal
Config.BreedingConfig = {
    ['a_c_bull_01'] = {
        gestationPeriod = 259200,  -- 3 days in seconds
        offspringCount = { min = 1, max = 1 },
        breedingSeasonStart = 1,
        breedingSeasonEnd = 365,
        enabled = true,
        offspringModels = {
            { model = 'a_c_cow', chance = 100 }
        }
    },
    ['a_c_cow'] = {
        gestationPeriod = 259200,
        offspringCount = { min = 1, max = 1 },
        breedingSeasonStart = 1,
        breedingSeasonEnd = 365,
        enabled = true,
        offspringModels = {
            { model = 'a_c_cow', chance = 50 },
            { model = 'a_c_bull_01', chance = 50 }
        }
    }
}
```

### Production Settings
```lua
Config.ProductionEnabled = true
Config.ProductionCheckInterval = 3600    -- Check every hour
Config.MinAgeForProduction = 5           -- Minimum age in days

-- Products per animal type
Config.AnimalProducts = {
    ['a_c_bull_01'] = {
        product = 'fertilizer',
        productionTime = 3600,     -- Every hour
        amount = 1,
        requiresHealth = 60,
        requiresHunger = 40,
        requiresThirst = 40
    },
    ['a_c_cow'] = {
        product = 'milk',
        productionTime = 3600,
        amount = 1,
        requiresHealth = 60,
        requiresHunger = 40,
        requiresThirst = 40
    }
}
```

### Staff Management
```lua
Config.StaffManagement = {
    MinGradeToManage = 2,           -- Minimum job grade for staff mgmt
    MaxEmployeesPerRanch = 20,      -- Max employees per ranch
    EnableSalarySystem = false,     -- Enable salary payments
    
    Permissions = {
        [0] = { -- Trainee
            canFeedAnimals = true,
            canWaterAnimals = true,
            canCollectProducts = false,
            canBreed = false,
            canSell = false,
            canBuy = false,
            canManageStaff = false,
        },
        [1] = { -- Ranch Hand
            canFeedAnimals = true,
            canWaterAnimals = true,
            canCollectProducts = true,
            canBreed = true,
            canSell = false,
            canBuy = false,
            canManageStaff = false,
        },
        [2] = { -- Manager
            canFeedAnimals = true,
            canWaterAnimals = true,
            canCollectProducts = true,
            canBreed = true,
            canSell = true,
            canBuy = true,
            canManageStaff = true,
        },
        [3] = { -- Boss
            canFeedAnimals = true,
            canWaterAnimals = true,
            canCollectProducts = true,
            canBreed = true,
            canSell = true,
            canBuy = true,
            canManageStaff = true,
        }
    }
}
```

---

## Core Features

### 1. **Ranch Management**
- Six fully configured ranch locations
- Job-based access control
- Ranch storage with weight and slot limits
- Animal capacity management

### 2. **Animal Management**
- Realistic survival mechanics (hunger, thirst, health)
- Automatic wandering behavior
- Health regeneration system
- Age-based degradation

### 3. **Herding System**
- Multi-animal herding with configurable limits
- Individual animal selection
- Automatic distance-based herding
- Optional herding tool requirement

### 4. **Breeding System**
- Realistic gestation periods
- Gender-based gameplay
- Automatic breeding detection
- Health and nutrition requirements for breeding

### 5. **Production System**
- Animal-specific products (milk, fertilizer)
- Time-based production cycles
- Health/nutrition requirements
- Automatic collection capabilities

### 6. **Staff System**
- Role-based permissions (Trainee, Ranch Hand, Manager, Boss)
- Hierarchical job grades
- Permission enforcement
- Employee tracking

### 7. **Buy/Sell System**
- Multiple livestock dealer locations
- Age-based pricing
- Gender-specific pricing
- Market-style transactions

---

## Ranch Locations

Six fully equipped ranches are available throughout the map:

### Macfarlane Ranch
- **Coordinates:** -2405.00, -2381.53, 61.18
- **Job Access:** `macfarranch`
- **Spawn Point:** -2425.51, -2367.51, 61.18

### Emerald Ranch
- **Coordinates:** 1403.50, 280.42, 89.25
- **Job Access:** `emeraldranch`
- **Spawn Point:** 1400.58, 290.48, 88.57

### Pronghorn Ranch
- **Coordinates:** -2561.00, 403.92, 148.23
- **Job Access:** `pronghornranch`
- **Spawn Point:** -2567.10, 404.34, 148.61

### Downes Ranch
- **Coordinates:** -853.86, 339.76, 96.39
- **Job Access:** `downesranch`
- **Spawn Point:** -850.30, 334.23, 95.77

### Hill Haven Ranch
- **Coordinates:** 1367.14, -848.88, 70.85
- **Job Access:** `hillhavenranch`
- **Spawn Point:** 1373.20, -845.12, 70.56

### Hanging Dog Ranch
- **Coordinates:** -2207.69, 726.97, 122.82
- **Job Access:** `hangingdogranch`
- **Spawn Point:** -2208.03, 719.73, 122.54

### Livestock Dealers (Buy Points)
- **Valentine:** -218.78, 652.80, 113.27
- **Near Strawberry:** -1834.75, -578.28, 155.97
- **Wallace Station:** -1309.82, 387.21, 95.35

### Livestock Markets (Sell Points)
- **Valentine:** -230.28, 637.59, 113.38
- **Near Strawberry:** -1791.83, -579.00, 155.95
- **Wallace Station:** -1308.77, 375.84, 96.4

---

## Database Schema

### Main Animals Table
```sql
CREATE TABLE rex_ranch_animals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    animalid VARCHAR(20) UNIQUE NOT NULL,
    ranchid VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    gender VARCHAR(10),
    age INT DEFAULT 0,
    health INT DEFAULT 100,
    hunger INT DEFAULT 100,
    thirst INT DEFAULT 100,
    born BIGINT,
    pos_x FLOAT,
    pos_y FLOAT,
    pos_z FLOAT,
    pos_w FLOAT,
    product_ready INT DEFAULT 0,
    pregnant INT DEFAULT 0,
    breeding_ready_time BIGINT,
    gestation_end_time BIGINT,
    last_production BIGINT,
    INDEX (ranchid),
    INDEX (animalid)
)
```

---

## API & Exports

### Server-Side Exports

#### `isPlayerRanchStaff(playerId)`
Check if a player is ranch staff.
```lua
local isStaff, ranchId = exports['rex-ranch']:isPlayerRanchStaff(playerId)
```
**Returns:** `boolean, string` (isStaff, ranchId)

#### `getPlayerRanchId(playerId)`
Get the ranch ID for a player.
```lua
local ranchId = exports['rex-ranch']:getPlayerRanchId(playerId)
```
**Returns:** `string` (ranchId or nil)

#### `getRanchAnimalCount(ranchid)`
Get total animal count for a ranch.
```lua
local count = exports['rex-ranch']:getRanchAnimalCount('macfarranch')
```
**Returns:** `number`

#### `getRanchAnimals(ranchid)`
Get all animals for a ranch.
```lua
local animals = exports['rex-ranch']:getRanchAnimals('macfarranch')
```
**Returns:** `table` (array of animal objects)

#### `getAnimalData(animalid)`
Get specific animal data.
```lua
local animal = exports['rex-ranch']:getAnimalData(123456)
```
**Returns:** `table` (animal data or nil)

#### `addAnimalToRanch(ranchid, model, gender, pos_x, pos_y, pos_z, pos_w)`
Add an animal to a ranch.
```lua
local animalId = exports['rex-ranch']:addAnimalToRanch(
    'macfarranch',
    'a_c_bull_01',
    'male',
    -2400.0,
    -2380.0,
    61.18,
    0.0
)
```
**Returns:** `number` (animalId or false)

#### `removeAnimalFromRanch(animalid)`
Remove an animal from a ranch.
```lua
local success = exports['rex-ranch']:removeAnimalFromRanch(123456)
```
**Returns:** `boolean`

#### `updateAnimalStats(animalid, stats)`
Update animal statistics.
```lua
exports['rex-ranch']:updateAnimalStats(123456, {
    health = 85,
    hunger = 70,
    thirst = 80,
    age = 5
})
```
**Returns:** `boolean`

#### `getStaffCount(ranchid)`
Get number of staff at a ranch.
```lua
local count = exports['rex-ranch']:getStaffCount('macfarranch')
```
**Returns:** `number`

#### `getRanchStatistics(ranchid)`
Get comprehensive ranch statistics.
```lua
local stats = exports['rex-ranch']:getRanchStatistics('macfarranch')
```
**Returns:** `table` with:
- `total`: Total animals
- `byType`: Animals grouped by model
- `byGender`: Breakdown of male/female
- `pregnant`: Pregnant animals
- `unhealthy`: Animals with health < 70
- `needsFood`: Animals with hunger < 50
- `needsWater`: Animals with thirst < 50
- `producing`: Animals with products ready

---

## Events

### Client Events

#### `rex-ranch:client:openranch`
Open the ranch menu.
```lua
TriggerEvent('rex-ranch:client:openranch', ranchid, jobaccess)
```

#### `rex-ranch:client:opentraineemenu`
Open trainee-level menu.
```lua
TriggerEvent('rex-ranch:client:opentraineemenu', ranchid)
```

#### `rex-ranch:client:openranchhandmenu`
Open ranch hand-level menu.
```lua
TriggerEvent('rex-ranch:client:openranchhandmenu', ranchid)
```

#### `rex-ranch:client:openmanagermenu`
Open manager-level menu.
```lua
TriggerEvent('rex-ranch:client:openmanagermenu', ranchid)
```

#### `rex-ranch:client:removeAnimal`
Remove an animal from the client.
```lua
TriggerClientEvent('rex-ranch:client:removeAnimal', playerId, animalid)
```

#### `rex-ranch:client:refreshSingleAnimal`
Refresh a single animal's data on client.
```lua
TriggerClientEvent('rex-ranch:client:refreshSingleAnimal', -1, animalid, stats)
```

### Server Events

#### `rex-ranch:server:refreshAnimals`
Refresh all animals across the server.
```lua
TriggerEvent('rex-ranch:server:refreshAnimals')
```

---

## Commands

No direct commands are documented. Access to ranch systems is controlled through:
- **Job-based access** at ranch locations
- **Grade-based permissions** for staff operations
- **NPC interactions** at ranches and livestock dealers

---

## Staff System

### Role Hierarchy

**Trainee (Grade 0)**
- Can feed and water animals
- Cannot collect products
- Cannot breed or sell
- Cannot manage staff

**Ranch Hand (Grade 1)**
- Can feed and water animals
- Can collect products
- Can initiate breeding
- Cannot buy or sell
- Cannot manage staff

**Manager (Grade 2)**
- Full animal management
- Can buy and sell livestock
- Can collect products
- Can manage staff

**Boss (Grade 3)**
- Full access to all operations
- Can manage staff
- Complete ranch control

### Permission System

Each grade has explicit permissions defined in `Config.StaffManagement.Permissions`. Customize permissions by editing these configurations before server startup.

---

## Animal Management

### Survival Mechanics

Animals have three main stats: **Health**, **Hunger**, and **Thirst** (0-100)

**Health Degradation:**
- When hunger or thirst falls below `Config.MinSurvivalStats`, health decays by `Config.HealthDecayRate` per cycle
- Health decay only occurs if both hunger and thirst are critically low

**Health Regeneration:**
- When both hunger and thirst are above `Config.MinStatsForRegeneration`, health regenerates by `Config.HealthRegenerationRate` per cycle

**Stat Decay:**
- Hunger decreases by `Config.HungerDecayRate` per cycle
- Thirst decreases by `Config.ThirstDecayRate` per cycle

**Feeding & Watering:**
- Feeding requires `Config.FeedItem` and restores hunger
- Watering requires `Config.WaterItem` and restores thirst
- Feeding/watering provides immediate `Config.ImmediateHealthBoost` to health

### Wandering Behavior

When enabled, animals will:
1. Stand idle for 10-30 seconds
2. Walk/jog around spawn point within 15m radius
3. Move for 5-15 seconds before idling again
4. Behavior updates every 2 seconds

Customize with `Config.AnimalWandering*` settings.

### Aging System

Animals age based on `Config.AnimalCronJob` schedule (default: every 15 minutes = 1 day in-game).

Animals progress through age categories:
- **Young:** Below prime age (0.5x price multiplier)
- **Prime:** Optimal age (1.5x price multiplier)
- **Adult:** Between prime and old (1.0x price multiplier)
- **Old:** Senior animals (0.7x price multiplier)

---

## Breeding System

### Breeding Requirements

To breed, animals must meet ALL criteria:
- Age between `Config.MinAgeForBreeding` and `Config.MaxBreedingAge`
- Health above `Config.RequireHealthForBreeding`
- Hunger above `Config.RequireHungerForBreeding`
- Thirst above `Config.RequireThirstForBreeding`
- Within `Config.BreedingDistance` of mate
- Not in breeding cooldown
- Opposite gender

### Breeding Cooldowns

**Female (Cow):** 24 hours (86400 seconds)  
**Male (Bull):** 1 hour (3600 seconds)

After successful breeding, animals cannot breed again until cooldown expires.

### Gestation & Birth

1. When breeding succeeds, female enters pregnant state
2. Gestation period: 3 days (259200 seconds) 
3. After gestation, offspring is born
4. Offspring inherits quality from parents based on `Config.BreedingConfig`

### Gender Determination

Offspring gender is determined by `offspringModels` configuration:
- **Bull offspring (if any):** Always has 100% chance to be a cow
- **Cow offspring:** 50% chance male (bull), 50% chance female (cow)

### Automatic Breeding

When `Config.AutomaticBreedingEnabled = true`:
- System checks compatible pairs every `Config.AutomaticBreedingCheckInterval` seconds
- Animals within `Config.AutomaticBreedingMaxDistance` can breed automatically
- Notifications sent when automatic breeding occurs

---

## Production System

### How Production Works

1. Animals produce items based on `Config.AnimalProducts` configuration
2. Production checks occur every `Config.ProductionCheckInterval` seconds
3. Animal must be at minimum age: `Config.MinAgeForProduction`

### Product Requirements

Each animal type has production requirements. For example, Cows require:
- **Product:** Milk
- **Health:** Minimum 60
- **Hunger:** Minimum 40
- **Thirst:** Minimum 40
- **Production Time:** Every 3600 seconds (1 hour)
- **Amount:** 1 unit

### Collecting Products

Products are automatically added to ranch storage when ready. Can be collected by staff with appropriate permissions.

---

## Herding System

### Herding Activation

1. Player opens herding menu at ranch
2. Selects animals to herd (up to 10)
3. Animals within 25m of player are eligible
4. Selected animals enter "follow" mode

### Herding Mechanics

- Animals maintain 3m distance from player
- Travel at 1.5x movement speed
- Herd follows player until:
  - Player stops herding
  - Herd timeout (5 minutes) expires
  - Player distance exceeds limits

### Transport Mode

When `Config.TransportMode = true`:
- Animals remain spawned even if player moves far away
- Useful for moving herds to sale points
- Improves reliability for livestock trading

### Individual Selection

When `Config.IndividualSelectionEnabled = true`:
- Players can select specific animals instead of all nearby
- Selection menu shows distance to each animal
- More control over herding operations

---

## Troubleshooting

### Animals Not Spawning

**Possible Causes:**
1. Distance setting too small (`Config.AnimalDistanceSpawn`)
2. Player too far from ranch (`> 100m`)
3. Database not loaded with animal data

**Solutions:**
- Increase `Config.AnimalDistanceSpawn` to 50+
- Check database connection
- Verify animals exist in database: `SELECT * FROM rex_ranch_animals LIMIT 5`

### Breeding Not Working

**Possible Causes:**
1. Animals don't meet requirements (age, health, hunger, thirst)
2. Animals are same gender
3. Breeding cooldown not expired
4. Distance between animals too great

**Solutions:**
- Check animal stats in database
- Verify gender using database query
- Lower `Config.MinAgeForBreeding` for testing
- Increase `Config.BreedingDistance`

### Staff Can't Perform Actions

**Possible Causes:**
1. Job grade doesn't match permissions
2. Incorrect job name configured
3. Player not assigned correct job

**Solutions:**
- Check player job with `/jobs` command
- Verify job name matches `Config.StaffManagement.Permissions`
- Confirm job assignment in framework

### Performance Issues

**Optimization Tips:**
1. Increase `Config.AnimalCronJob` interval (less frequent updates)
2. Reduce `Config.MaxRanchAnimals` capacity
3. Disable `Config.AnimalWanderingEnabled` if not needed
4. Disable `Config.AutomaticBreedingEnabled` if not needed
5. Increase `Config.WanderCheckInterval`

### Database Errors

**Ensure:**
1. Database user has proper permissions
2. Tables created from SQL file
3. oxmysql is properly installed
4. Connection string is correct in server config

**Debug:**
- Enable `Config.Debug = true` for verbose logging
- Check server console for MySQL errors

---

## Advanced Usage

### Custom Animal Models

To add new animal models:

1. **Add to config:**
   ```lua
   Config.BaseSellPrices['a_c_horse_01'] = 500
   Config.GenderRatios['a_c_horse_01'] = 0.5
   ```

2. **Add breeding config:**
   ```lua
   Config.BreedingConfig['a_c_horse_01'] = {
       gestationPeriod = 345600,  -- 4 days
       offspringCount = { min = 1, max = 1 },
       offspringModels = { { model = 'a_c_horse_01', chance = 100 } },
       enabled = true,
       breedingSeasonStart = 1,
       breedingSeasonEnd = 365
   }
   ```

3. **Add production:**
   ```lua
   Config.AnimalProducts['a_c_horse_01'] = {
       product = 'horse_item',
       productionTime = 7200,
       amount = 1,
       requiresHealth = 70,
       requiresHunger = 50,
       requiresThirst = 50
   }
   ```

### Custom Locations

To add new ranches:

```lua
table.insert(Config.RanchLocations, {
    name = 'Your Ranch',
    ranchid = 'yourranch',
    coords = vector3(x, y, z),
    npcmodel = `model_hash`,
    npccoords = vector4(x, y, z, h),
    jobaccess = 'yourranch_job',
    blipname = 'Your Ranch',
    blipsprite = 'blip_ambient_herd',
    blipscale = 0.2,
    showblip = true,
    spawnpoint = vector4(x, y, z, h)
})
```

---

## Performance Notes

- **Animal Limit:** Default 10 per ranch (configurable)
- **Cron Job:** Runs every 15 minutes by default
- **Spawn Distance:** 50m default for balance
- **Memory Usage:** Minimal with proper cleanup enabled

---

## License & Credits

This resource was developed for the RSG Framework and Red Dead Redemption 2 RedM servers.

For support or contributions, refer to official RSG documentation and RedM community resources.

---

**Last Updated:** Version 0.0.24  
**Requires:** RedM, RSG-Core, ox_lib, oxmysql
