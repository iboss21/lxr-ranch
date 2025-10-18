Config = {}

---------------------------------
-- system constants
---------------------------------
Config.BLIP_HASH = 1664425300 -- Standard blip hash for RedM
Config.ANIMAL_ID_MIN = 111111 -- Minimum animal ID
Config.ANIMAL_ID_MAX = 999999 -- Maximum animal ID
Config.FALLBACK_ID_SUFFIX_MIN = 1000 -- Minimum suffix for fallback IDs
Config.FALLBACK_ID_SUFFIX_MAX = 9999 -- Maximum suffix for fallback IDs
Config.MAX_ID_LENGTH = 9 -- Maximum length for animal IDs

---------------------------------
-- debug settings
---------------------------------
Config.Debug = false

---------------------------------
-- npc settings
---------------------------------
Config.DistanceSpawn = 20.0
Config.FadeIn = true

---------------------------------
-- ranch settings
---------------------------------
Config.StorageMinJobGrade = 1
Config.RanchStorageMaxWeight = 10000000
Config.RanchStorageMaxSlots = 100
Config.AnimalDistanceSpawn = 50.0
Config.AnimalFadeIn = true
Config.ServerNotify = true
Config.AnimalCronJob = '*/15 * * * *' -- every 5 minutes (for testing), change to '0 * * * *' for hourly
Config.MaxRanchAnimals = 10
Config.UpdateClientsOnCron = true -- Update client animal data when cronjob runs
Config.RefreshAfterCron = true -- Full refresh of animal data after cronjob completion

---------------------------------
-- animal management settings
---------------------------------
Config.HungerDecayRate = 1 -- hunger reduction per cronjob run
Config.ThirstDecayRate = 1 -- thirst reduction per cronjob run
Config.HealthDecayRate = 5 -- health reduction per cronjob run when starving/dehydrated
Config.MinSurvivalStats = 0 -- minimum hunger/thirst before health starts decaying
Config.FeedItem = 'animal_feed' -- item required to feed animals
Config.WaterItem = 'water_bucket' -- item required to water animals

---------------------------------
-- herding system settings
---------------------------------
Config.HerdingEnabled = true
Config.HerdingDistance = 25.0 -- maximum distance to detect animals for herding
Config.HerdingMaxAnimals = 10 -- maximum number of animals that can be herded at once
Config.HerdingFollowDistance = 3.0 -- distance animals maintain while following during herding
Config.HerdingSpeed = 1.5 -- movement speed when herding animals
Config.HerdingTimeout = 300 -- seconds before herding automatically stops (5 minutes)
Config.RequireHerdingTool = false -- set to true if you want to require a specific item to herd
Config.HerdingTool = 'weapon_lasso' -- item required for herding (if RequireHerdingTool is true)
Config.IndividualSelectionEnabled = true -- enable individual animal selection for herding
Config.ShowAnimalDistance = true -- show distance to animals in selection menu
Config.SelectionRangeMultiplier = 1.5 -- multiplier for selection range vs herding distance

-- Herding blip settings
Config.ShowHerdingBlips = true -- Show blips on herded animals
Config.HerdingBlipSprite = 'blip_ambient_herd' -- Blip sprite for herded animals
Config.HerdingBlipScale = 0.3 -- Size of herding blips
Config.HerdingBlipColor = 'WHITE' -- Color of herding blips

---------------------------------
-- animal buy/sell settings
---------------------------------
Config.BullBuyPrice = 100
Config.BullSellPrice = 1
---------------------------------
Config.CowBuyPrice = 50
Config.CowSellPrice = 1
---------------------------------

---------------------------------
-- animal sale point settings
---------------------------------
Config.MinAgeToSell = 6 -- minimum age in days to sell animals (reduced from 2 for easier testing)
Config.PrimeAgeStart = 6 -- age when animals are considered prime
Config.PrimeAgeEnd = 30 -- age when animals are no longer prime
Config.OldAgeStart = 31 -- age when animals are considered old

-- Age-based pricing multipliers
Config.AgePricing = {
    young = 0.5,     -- animals below prime age (50% of base price)
    prime = 1.5,     -- animals in prime age (150% of base price)
    adult = 1.0,     -- animals between prime and old (100% of base price)
    old   = 0.7      -- old animals (70% of base price)
}

-- Base selling prices (will be modified by age multipliers)
Config.BaseSellPrices = {
    ['a_c_bull_01'] = 400,
    ['a_c_cow'] = 150
}

-- Sale point settings
Config.AnimalSaleDistance = 15.0 -- Distance animal must be within sale point to sell
Config.RequireAnimalPresent = false -- Set to false to disable physical animal requirement (temporarily disabled for testing)
Config.TransportMode = true -- Keep animals spawned when being herded, regardless of distance

-- Buy point settings
Config.BuyPointSpawnDistance = 8.0 -- Distance from buy point where animals can spawn
---------------------------------

---------------------------------
-- animal production settings
---------------------------------
Config.ProductionEnabled = true
Config.ProductionCheckInterval = 3600 -- seconds (1 hour)
Config.MinAgeForProduction = 2 -- days old before animals can produce

---------------------------------
-- animal breeding settings
---------------------------------
Config.BreedingEnabled = true
Config.MinAgeForBreeding = 2 -- days old before animals can breed (more realistic)
Config.MaxBreedingAge = 30 -- days old after which animals can't breed (extended for more breeding time)
Config.BreedingDistance = 10.0 -- maximum distance between animals to breed
Config.BreedingCooldown = 172800 -- 2 days in seconds before animal can breed again
Config.RequireHealthForBreeding = 70 -- minimum health required for breeding
Config.RequireHungerForBreeding = 50 -- minimum hunger required for breeding
Config.RequireThirstForBreeding = 50 -- minimum thirst required for breeding

-- Automatic breeding settings
Config.AutomaticBreedingEnabled = true -- Enable automatic breeding between compatible animals
Config.AutomaticBreedingCheckInterval = 60 -- Check interval in seconds (1 minute for testing)
Config.AutomaticBreedingMaxDistance = 5.0 -- Maximum distance for automatic breeding (shorter than manual)
Config.AutomaticBreedingNotifications = true -- Send notifications to ranch owners when automatic breeding occurs

-- Gender ratios when buying animals (chance of male)
Config.GenderRatios = {
    ['a_c_bull_01'] = 1.0, -- 100% chance of male (it's specifically a bull)
    ['a_c_cow'] = 0.0      -- 0% chance of male, 100% chance of female (cows are always female)
}

-- Breeding configurations per animal type
Config.BreedingConfig = {
    ['a_c_bull_01'] = {
        gestationPeriod = 259200,    -- 3 days in seconds (same as cows, represents 9 months)
        offspringCount = { min = 1, max = 1 }, -- always 1 calf
        breedingSeasonStart = 1,     -- year-round breeding
        breedingSeasonEnd = 365,
        enabled = true
    },
    ['a_c_cow'] = {
        gestationPeriod = 259200,    -- 3 days in seconds (represents 9 months)
        offspringCount = { min = 1, max = 1 }, -- always 1 calf
        breedingSeasonStart = 1,     -- day of year (1-365)
        breedingSeasonEnd = 365,     -- year-round breeding
        enabled = true
    },
}

Config.AnimalProducts = {
    ['a_c_bull_01'] = {
        product = 'hide',
        productionTime = 86400, -- 24 hours in seconds (longer production time)
        amount = 1,
        requiresHealth = 60,
        requiresHunger = 40,
        requiresThirst = 40
    },
    ['a_c_cow'] = {
        product = 'milk',
        productionTime = 21600, -- 6 hours in seconds
        amount = 1,
        requiresHealth = 50, -- minimum health to produce
        requiresHunger = 30, -- minimum hunger to produce
        requiresThirst = 30  -- minimum thirst to produce
    }
}
---------------------------------

---------------------------------
-- ranch locations
---------------------------------
Config.RanchLocations = {
    { 
        name = 'Macfarlane Ranch',
        ranchid = 'macfarranch',
        coords = vector3(-2405.00, -2381.53, 61.18),
        npcmodel = `g_m_m_uniranchers_01`,
        npccoords = vector4(-2405.00, -2381.53, 61.18, 71.45),
        jobaccess = 'macfarranch',
        blipname = 'Macfarlane Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-2425.51, -2367.51, 61.18, 82.40)
    },
    { 
        name = 'Emerald Ranch',
        ranchid = 'emeraldranch',
        coords = vector3(1403.50, 280.42, 89.25),
        npcmodel = `g_m_m_uniranchers_01`,
        npccoords = vector4(1403.50, 280.42, 89.25, 19.85),
        jobaccess = 'emeraldranch',
        blipname = 'Emerald Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(1400.58, 290.48, 88.57, 19.79)
    },
    { 
        name = 'Pronghorn Ranch',
        ranchid = 'pronghornranch',
        coords = vector3(-2561.00, 403.92, 148.23),
        npcmodel = `g_m_m_uniranchers_01`,
        npccoords = vector4(-2561.00, 403.92, 148.23, 97.99),
        jobaccess = 'pronghornranch',
        blipname = 'Pronghorn Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-2567.10, 404.34, 148.61, 83.07)
    },
    { 
        name = 'Downes Ranch',
        ranchid = 'downesranch',
        coords = vector3(-853.86, 339.76, 96.39),
        npcmodel = `g_m_m_uniranchers_01`,
        npccoords = vector4(-853.86, 339.76, 96.39, 262.57),
        jobaccess = 'downesranch',
        blipname = 'Downes Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-850.30, 334.23, 95.77, 189.21)
    },
    { 
        name = 'Hill Haven Ranch',
        ranchid = 'hillhavenranch',
        coords = vector3(1367.14, -848.88, 70.85),
        npcmodel = `g_m_m_uniranchers_01`,
        npccoords = vector4(1367.14, -848.88, 70.85, 297.43),
        jobaccess = 'hillhavenranch',
        blipname = 'Hill Haven Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(1373.20, -845.12, 70.56, 301.98)
    },
    { 
        name = 'Hanging Dog Ranch',
        ranchid = 'hangingdogranch',
        coords = vector3(-2207.69, 726.97, 122.82),
        npcmodel = `g_m_m_uniranchers_01`,
        npccoords = vector4(-2207.69, 726.97, 122.82, 213.49),
        jobaccess = 'hangingdogranch',
        blipname = 'Hanging Dog Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-2208.03, 719.73, 122.54, 185.14)
    }
}

---------------------------------
-- sale point locations
---------------------------------
Config.SalePointLocations = {
    { 
        name = 'Livestock Market',
        coords = vector3(1334.46, 301.40, 87.75),
        npcmodel = `cs_valauctionboss_01`,
        npccoords = vector4(1334.46, 301.40, 87.75, 281.66),
        blipname = 'Livestock Market',
        blipsprite = 'blip_shop_store',
        blipscale = 0.2,
        showblip = true
    },
    { 
        name = 'Livestock Market',
        coords = vector3(-1792.34, -392.56, 160.33),
        npcmodel = `cs_valauctionboss_01`,
        npccoords = vector4(-1792.34, -392.56, 160.33, 180.0),
        blipname = 'Livestock Market',
        blipsprite = 'blip_shop_store',
        blipscale = 0.2,
        showblip = true
    },
    { 
        name = 'Livestock Market',
        coords = vector3(1225.67, -1293.45, 76.04),
        npcmodel = `cs_valauctionboss_01`,
        npccoords = vector4(1225.67, -1293.45, 76.04, 270.0),
        blipname = 'Livestock Market',
        blipsprite = 'blip_shop_store',
        blipscale = 0.2,
        showblip = true
}
}

---------------------------------
-- buy point locations
---------------------------------
Config.BuyPointLocations = {
    {
        name = 'Livestock Dealer',
        coords = vector3(1383.58, 292.34, 88.18),
        npcmodel = `mp_u_m_m_trader_01`,
        npccoords = vector4(1383.58, 292.34, 88.18, 267.87),
        blipname = 'Livestock Dealer',
        blipsprite = 'blip_shop_horse',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(1383.58, 292.34, 88.18, 267.87) -- Near the dealer
    },
    {
        name = 'Livestock Dealer',
        coords = vector3(-1792.84, -394.56, 160.33),
        npcmodel = `mp_u_m_m_trader_01`,
        npccoords = vector4(-1792.84, -394.56, 160.33, 90.0),
        blipname = 'Livestock Dealer',
        blipsprite = 'blip_shop_horse',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-1790.00, -398.00, 160.33, 180.0) -- Near the trader
    },
    {
        name = 'Livestock Dealer',
        coords = vector3(1226.67, -1295.45, 76.04),
        npcmodel = `mp_u_m_m_trader_01`,
        npccoords = vector4(1226.67, -1295.45, 76.04, 270.0),
        blipname = 'Livestock Dealer',
        blipsprite = 'blip_shop_horse',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(1230.00, -1298.00, 76.04, 0.0) -- Near the merchant
    }
}
