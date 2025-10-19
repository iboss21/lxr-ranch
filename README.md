# Rex Ranch - RedM Ranching System

A comprehensive ranching simulation system for RedM servers, featuring realistic animal management, breeding, herding, and production mechanics.

## 🌟 Key Features

### 🐄 Advanced Animal Management
- **Multiple Animal Types**: Cows, Bulls, Sheep, Pigs, and Horses with unique behaviors
- **Realistic Aging System**: Visual scaling and stat progression over time
- **Comprehensive Care**: Health, hunger, and thirst management with automatic decay
- **Breeding System**: Full breeding mechanics with gestation periods and offspring
- **Smart Spawning**: Distance-based spawning/despawning for optimal performance

### 🏡 Ranch Management
- **6 Pre-configured Ranches**: Macfarlane, Emerald, Pronghorn, Downes, Hill Haven, Hanging Dog
- **Job-based Access Control**: Secure ranch access tied to RSG-Core job system
- **Tiered Permissions**: Trainee, Ranch Hand, and Manager roles with different capabilities
- **Ranch Storage**: Dedicated inventory system for feed and supplies
- **Strategic Spawn Points**: Optimized animal placement locations

### 🐎 Interactive Herding System
- **Multiple Herding Modes**: Distance-based, type-based, and individual animal selection
- **Visual Feedback**: Real-time blips and indicators for herded animals
- **Smart Controls**: Configurable distances, speeds, and group limits
- **Transport Mode**: Maintains animal spawning during herding operations
- **Command Integration**: Easy-to-use `/herd` command system

### 💰 Dynamic Economy
- **Age-based Pricing**: Smart pricing system (Young 50%, Prime 150%, Adult 100%, Old 70%)
- **Multiple Markets**: Strategic buy/sell points across the map
- **Bulk Operations**: Efficient handling of multiple animal transactions
- **Configurable Prices**: Server owners can adjust all pricing parameters
- **Minimum Age Requirements**: Prevents exploitation with age restrictions

### 🥛 Production & Breeding
- **Automated Production**: Animals generate resources (milk, wool, bacon, horsehair) over time
- **Health Requirements**: Production tied to animal welfare stats
- **Breeding Mechanics**: Realistic gestation periods and breeding cooldowns
- **Gender System**: Proper male/female ratios and breeding compatibility
- **Automatic Breeding**: Optional hands-off breeding for busy ranchers

### ⚙️ Performance & Quality
- **Optimized Database**: Indexed queries and efficient data structures
- **Debug System**: Comprehensive logging and troubleshooting tools
- **Automatic Cleanup**: Built-in systems to prevent data corruption
- **Scalable Architecture**: Handles multiple ranches and hundreds of animals
- **Real-time Sync**: All players see consistent animal states

## 📍 Requirements

### Framework Dependencies
- **RSG Framework** (Required - core framework)
- **ox_lib** (Required - UI and utility library)
- **oxmysql** (Required - MySQL database connector)
- **ox_target** (Required - NPC and entity interactions)
- **rsg-inventory** (Required - inventory system integration)

### Server Requirements
- **MySQL/MariaDB** database
- **Lua 5.4** support enabled in server
- Minimum **4GB RAM** for optimal performance

## 🚀 Installation Guide

### Step 1: Download and Extract
```bash
# Download the rex-ranch resource
# Extract to: server/resources/rex-ranch/
# Ensure the folder name is exactly 'rex-ranch'
```

### Step 2: Database Setup
1. **Import the main table**:
```sql
-- Execute in your MySQL database
source path/to/rex-ranch/installation/rex-ranch.sql
```

### Step 3: Server Configuration
1. **Add to server.cfg**:
```cfg
# Resource loading (ensure dependencies load first)
ensure ox_lib
ensure oxmysql
ensure rsg-core
ensure ox_target
ensure rsg-inventory
ensure rex-ranch
```

2. **Configure permissions**:
```cfg
# Add ranch management permissions (if using admin system)
add_ace group.admin "rex-ranch.admin" allow
```

### Step 4: Job Configuration
Add ranch jobs to your rsg-core\shared\jobs.lua

### Step 5: Items Setup
Add ranch items to your rsg-core\shared\items.lua

## Configuration

### Basic Settings
Edit `shared/config.lua` to customize:

```lua
Config.Debug = false -- Enable debug mode for troubleshooting
Config.MaxRanchAnimals = 10 -- Maximum animals per ranch
Config.AnimalCronJob = '0 * * * *' -- Stat decay frequency (every hour)
Config.BuyPointSpawnDistance = 8.0 -- Distance from buy point where animals spawn
```

### Ranch Locations
Modify ranch locations in `Config.RanchLocations`:
```lua
{
    name = 'Custom Ranch',
    ranchid = 'customranch',
    coords = vector3(x, y, z),
    npcmodel = `g_m_m_uniranchers_01`,
    npccoords = vector4(x, y, z, heading),
    jobaccess = 'customranch', -- Job required to access this ranch
    spawnpoint = vector4(x, y, z, heading) -- Where animals spawn
}
```

### Animal Pricing
Adjust prices in `Config.BaseSellPrices`:
```lua
Config.BaseSellPrices = {
    ['a_c_cow'] = 150,
    ['a_c_sheep_01'] = 80,
    ['a_c_pig_01'] = 100,
    ['a_c_horse_americanpaint_greyovero'] = 300
}
```

### Production Settings
Configure animal production in `Config.AnimalProducts`:
```lua
['a_c_cow'] = {
    product = 'milk',
    productionTime = 21600, -- 6 hours in seconds
    amount = 1,
    requiresHealth = 50,
    requiresHunger = 30,
    requiresThirst = 30
}
```

## 🎮 Usage Guide

### 👤 For Players

#### Getting Started
1. **Obtain Ranch Job**: Get assigned a ranch job from an admin

2. **Find Your Ranch**: Look for ranch blips on your map or visit these locations:
   - **Macfarlane Ranch**: New Austin region
   - **Emerald Ranch**: Heartlands region
   - **Pronghorn Ranch**: Hennigan's Stead
   - And more...

#### Daily Operations
3. **Animal Purchase & Management**:
   - Visit livestock dealers to buy animals
   - Animals spawn near the dealer for pickup
   - Use `/herd` command to move animals to your ranch
   - Feed animals with `animal_feed` items
   - Water animals with `water_bucket` items
   - Monitor animal health, hunger, and thirst stats

4. **Herding System**:
   ```
   /herd - Opens the herding menu
   
   Herding Options:
   - Distance-based: All animals within range
   - Type-based: Select specific animal types
   - Individual: Choose specific animals
   ```

5. **Production & Sales**:
   - Collect products from healthy, well-fed animals
   - Products: milk (cows), wool (sheep), bacon (pigs), horsehair (horses)
   - Sell mature animals at livestock markets
   - Age affects pricing: Young (50%), Prime (150%), Adult (100%), Old (70%)

#### Advanced Features
6. **Breeding System**:
   - Healthy animals will automatically breed when conditions are met
   - Gestation periods vary by animal type
   - Monitor breeding cooldowns and pregnancy status

7. **Ranch Storage**:
   - Access ranch storage for feed and supplies (Manager+ only)
   - Organize inventory for efficient ranch operations

### 🔧 For Server Administrators

#### Player Management
```lua
-- Assign ranch jobs
/givejob [player_id] [ranch_name] [grade]

-- Example: Make player ID 1 a manager at Macfarlane Ranch
/givejob 1 macfarranch 2
```

#### Monitoring & Maintenance
- **Performance Monitoring**: Check server console for animal spawn/despawn logs
- **Database Health**: Monitor `rex_ranch_animals` table for corruption
- **Configuration Tuning**: Adjust settings in `shared/config.lua` as needed
- **Debug Mode**: Enable `Config.Debug = true` for detailed logging

#### Common Admin Tasks
- Adjust animal limits per ranch: `Config.MaxRanchAnimals`
- Modify pricing: `Config.BaseSellPrices` and `Config.AgePricing`
- Change production timers: `Config.AnimalProducts`
- Configure breeding settings: `Config.BreedingConfig`

## 🔍 Troubleshooting Guide

### ⚠️ Common Issues

#### Animals Not Spawning
```
🔴 Problem: Animals don't appear after purchase/restart

✅ Solutions:
1. Verify player has correct ranch job: /job [player_id]
2. Check database connection in server console
3. Ensure Config.Debug = true and check spawn logs
4. Verify animal spawn points are not obstructed
5. Check for conflicting animal resources
6. Restart resource: refresh rex-ranch
```

#### Performance Issues
```
🔴 Problem: Server lag, low FPS near ranches

✅ Solutions:
1. Reduce Config.MaxRanchAnimals (default: 10)
2. Increase Config.AnimalDistanceSpawn for better culling
3. Set Config.Debug = false in production
4. Adjust Config.AnimalCronJob frequency
5. Monitor MySQL performance and optimize queries
```

#### Economy & Balance Issues
```
🔴 Problem: Pricing too high/low, exploits

✅ Solutions:
1. Adjust Config.BaseSellPrices for your server economy
2. Modify Config.AgePricing multipliers
3. Change Config.MinAgeToSell to prevent quick flipping
4. Adjust production times in Config.AnimalProducts
5. Monitor Config.MaxRanchAnimals to prevent oversupply
```

#### Herding System Problems
```
🔴 Problem: /herd command not working, animals won't follow

✅ Solutions:
1. Verify player has ranch job access
2. Check Config.HerdingEnabled = true
3. Ensure animals are within Config.HerdingDistance
4. Verify rsg-target dependency is loaded
5. Check for conflicting resources affecting animal entities
```

### 🛠️ Debug Mode

Enable comprehensive logging:
```lua
-- In shared/config.lua
Config.Debug = true

-- Console output will show:
-- Animal spawning/despawning events
-- Database query results
-- Breeding system status
-- Production timing
-- Herding operations
```

### 📋 Database Maintenance

```sql
-- Check for corrupted animal data
SELECT * FROM rex_ranch_animals WHERE 
  pos_x IS NULL OR pos_y IS NULL OR pos_z IS NULL OR
  health < 0 OR health > 100 OR
  hunger < 0 OR hunger > 100 OR
  thirst < 0 OR thirst > 100;

-- Clean up old/invalid animals
DELETE FROM rex_ranch_animals WHERE 
  born < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 365 DAY));
```

## 📚 Configuration Reference

### Key Settings to Adjust
```lua
-- Performance Tuning
Config.MaxRanchAnimals = 10           -- Animals per ranch
Config.AnimalDistanceSpawn = 50.0     -- Spawn distance
Config.AnimalCronJob = '0 * * * *'    -- Hourly stat decay

-- Economy Balancing  
Config.BaseSellPrices = {
    ['a_c_cow'] = 150,                -- Base cow price
    ['a_c_bull_01'] = 400             -- Base bull price
}

Config.AgePricing = {
    young = 0.5,    -- 50% of base price
    prime = 1.5,    -- 150% of base price
    adult = 1.0,    -- 100% of base price
    old = 0.7       -- 70% of base price
}

-- Production Settings
Config.AnimalProducts = {
    ['a_c_cow'] = {
        product = 'milk',
        productionTime = 21600, -- 6 hours
        requiresHealth = 50,
        requiresHunger = 30,
        requiresThirst = 30
    }
}
```

## 💰 Version History

### v2.0.0 - Complete System Rewrite
- **✨ New Features**:
  - Advanced herding system with multiple selection modes
  - Comprehensive breeding mechanics with gestation periods
  - Automatic breeding system for hands-off ranch management
  - Enhanced production system with health requirements
  - Performance-optimized animal spawning

- **🔧 Improvements**:
  - Database schema optimization with proper indexing
  - Real-time animal synchronization across clients
  - Enhanced debug system with detailed logging
  - Improved error handling and validation
  - Scalable architecture supporting hundreds of animals

- **🐛 Bug Fixes**:
  - Fixed animal duplication issues
  - Resolved performance problems with large herds
  - Corrected breeding cooldown calculations
  - Fixed production timer synchronization

## 🆘 Support & Community

### Getting Help
- **Enable Debug Mode**: `Config.Debug = true` for detailed logs
- **Check Dependencies**: Ensure all required resources are loaded
- **Review Documentation**: WARP.md contains technical details
- **Monitor Console**: Server console shows detailed error messages

### Contributing
This resource welcomes community contributions:
- Report bugs and issues
- Suggest feature improvements
- Share configuration optimizations

---

## 🎆 Credits & License

**Rex Ranch v2.0.x** - A comprehensive ranching simulation for RedM

Built by RexShack for the RedM community with ❤️

*Transform your server into the ultimate Wild West ranching experience!* 🤠🐄🌾
