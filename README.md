# Rex Ranch - RedM Ranching System

A comprehensive ranching system for RedM servers, featuring animal management, herding, buying/selling, and production systems.

## Features

### 🐄 Animal Management
- Multiple animal types: Cows, Sheep, Pigs, and Horses
- Age-based progression system with visual scaling
- Health, hunger, and thirst management
- Automatic aging and stat decay over time

### 🏡 Ranch System
- Multiple pre-configured ranch locations
- Job-based access control per ranch
- Ranch storage system for feed and supplies
- Spawn point management for animals

### 🐎 Herding System
- Interactive animal herding with selection menus
- Individual or group herding options
- Visual blips for herded animals
- Configurable herding distances and speeds

### 💰 Economy Integration
- Age-based pricing system (young, prime, adult, old)
- Multiple sale points across the map
- Bulk sell functionality
- Configurable buy/sell prices

### 🥛 Production System
- Animals produce resources over time
- Age and health requirements for production
- Multiple product types: milk, wool, bacon, horsehair
- Automated production timers

### 🛠️ Advanced Features
- Comprehensive configuration system
- Debug tools for development
- Automatic cleanup systems
- Performance optimized spawning

## Requirements

- **RedM Server** (Latest version recommended)
- **RSG-Core Framework**
- **ox_lib** (Ox Library)
- **oxmysql** (MySQL connector)
- **rsg-target** (For NPC interactions)

## Installation

### Step 1: Download and Extract
1. Download the `rex-ranch` resource
2. Extract to your server's `resources` folder
3. Ensure the folder name is exactly `rex-ranch`

### Step 2: Database Setup
1. Import the SQL file to create the required database table:
```sql
-- Execute this in your MySQL database
source path/to/rex-ranch/installation/rex-ranch.sql
```

### Step 3: Server Configuration
Add the following to your `server.cfg`:
```cfg
ensure rex-ranch
```

### Step 4: Job Configuration
Add ranch jobs to your RSG-Core jobs table. Example SQL:
```sql
INSERT INTO `jobs` (`name`, `label`, `defaultDuty`, `offDutyPay`, `grades`) VALUES
('macfarranch', 'Macfarlane Ranch', 1, 0, '{"0": {"name": "Ranch Hand", "payment": 50}, "1": {"name": "Ranch Owner", "payment": 100}}'),
('emeraldranch', 'Emerald Ranch', 1, 0, '{"0": {"name": "Ranch Hand", "payment": 50}, "1": {"name": "Ranch Owner", "payment": 100}}'),
('pronghornranch', 'Pronghorn Ranch', 1, 0, '{"0": {"name": "Ranch Hand", "payment": 50}, "1": {"name": "Ranch Owner", "payment": 100}}'),
('downesranch', 'Downes Ranch', 1, 0, '{"0": {"name": "Ranch Hand", "payment": 50}, "1": {"name": "Ranch Owner", "payment": 100}}'),
('hillhavenranch', 'Hill Haven Ranch', 1, 0, '{"0": {"name": "Ranch Hand", "payment": 50}, "1": {"name": "Ranch Owner", "payment": 100}}'),
('hangingdogranch', 'Hanging Dog Ranch', 1, 0, '{"0": {"name": "Ranch Hand", "payment": 50}, "1": {"name": "Ranch Owner", "payment": 100}}');
```

### Step 5: Items Setup
Add the following items to your RSG-Core items table:
```sql
-- Animal feed item
INSERT INTO `items` (`name`, `label`, `weight`, `type`, `image`, `unique`, `useable`, `shouldClose`, `combinable`, `description`) VALUES
('animal_feed', 'Animal Feed', 5, 'item', 'animal_feed.png', 0, 1, 1, NULL, 'Nutritious feed for livestock'),
('water_bucket', 'Water Bucket', 10, 'item', 'water_bucket.png', 0, 1, 1, NULL, 'Fresh water for animals');

-- Animal products
INSERT INTO `items` (`name`, `label`, `weight`, `type`, `image`, `unique`, `useable`, `shouldClose`, `combinable`, `description`) VALUES
('milk', 'Fresh Milk', 2, 'item', 'milk.png', 0, 0, 1, NULL, 'Fresh milk from cows'),
('wool', 'Sheep Wool', 1, 'item', 'wool.png', 0, 0, 1, NULL, 'Soft wool from sheep'),
('bacon', 'Raw Bacon', 3, 'item', 'bacon.png', 0, 0, 1, NULL, 'Fresh bacon from pigs'),
('horsehair', 'Horse Hair', 1, 'item', 'horsehair.png', 0, 0, 1, NULL, 'Quality horse hair');
```

## Configuration

### Basic Settings
Edit `shared/config.lua` to customize:

```lua
Config.Debug = false -- Enable debug mode for troubleshooting
Config.MaxRanchAnimals = 10 -- Maximum animals per ranch
Config.AnimalCronJob = '0 * * * *' -- Stat decay frequency (every hour)
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

## Usage

### For Players
1. **Get Ranch Job**: Obtain a ranch job from an admin or through your server's job system
2. **Visit Your Ranch**: Go to your assigned ranch location (marked with blips)
3. **Buy Animals**: Visit livestock dealers to purchase animals
4. **Manage Animals**: 
   - Feed animals with `animal_feed`
   - Water animals with `water_bucket`
   - Check animal stats through interaction menus
5. **Herding**: Use the herding system to move animals around your ranch
6. **Sell Animals**: Take animals to livestock markets to sell them
7. **Collect Products**: Interact with animals to collect their products

### For Administrators
- Use `/givejob [player] [ranchname] [grade]` to assign ranch jobs
- Monitor animal counts and ranch performance
- Adjust configuration as needed for server balance

## Troubleshooting

### Animals Not Spawning
1. Check if the player has the correct job
2. Verify database connection
3. Ensure animal spawn points are valid
4. Check for conflicting resources

### Performance Issues
1. Reduce `Config.MaxRanchAnimals`
2. Increase `Config.AnimalDistanceSpawn` for better culling
3. Disable debug mode in production

### Economy Balance
1. Adjust `Config.BaseSellPrices` for your server's economy
2. Modify `Config.AgePricing` multipliers
3. Change production times in `Config.AnimalProducts`

## Support

For support and updates:
- Check the resource documentation
- Enable debug mode to troubleshoot issues
- Review server console for error messages

## Version History

- **v2.0.0** - Complete rewrite with new features
  - Added herding system
  - Improved animal management
  - Enhanced production system
  - Performance optimizations

## License

This resource is provided as-is for RedM servers. Please respect the original author's work and contribute back to the community.

---

*Enjoy your ranching experience in RedM!* 🤠
