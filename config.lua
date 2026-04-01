--[[
    ██╗     ██╗  ██╗██████╗       ██████╗  █████╗ ███╗   ██╗ ██████╗██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗      ██╔══██╗██╔══██╗████╗  ██║██╔════╝██║  ██║
    ██║      ╚███╔╝ ██████╔╝█████╗██████╔╝███████║██╔██╗ ██║██║     ███████║
    ██║      ██╔██╗ ██╔══██╗╚════╝██╔══██╗██╔══██║██║╚██╗██║██║     ██╔══██║
    ███████╗██╔╝ ██╗██║  ██║      ██║  ██║██║  ██║██║ ╚████║╚██████╗██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝

    🐺 LXR Core - Ranch Simulation & Management System

    A persistent, state-driven agricultural simulation system for RedM that
    transforms ranching into a multi-layered economic, biological, and managerial
    gameplay loop. Features deterministic animal simulation, resource dependency
    chains, ownership structures, market-driven outputs, and time-based decay.

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

    Version: 1.0.0
    Performance Target: Optimized for minimal server overhead and client FPS impact

    Tags: RedM, Georgian, SeriousRP, Whitelist, Ranch, Livestock, Farming,
          Breeding, Economy, Simulation

    Framework Support:
    - LXR Core (Primary)
    - RSG Core (Compatible)
    - VORP Core (Compatible)
    - Standalone (Compatible)

    ═══════════════════════════════════════════════════════════════════════════════
    CREDITS
    ═══════════════════════════════════════════════════════════════════════════════

    Script Author: iBoss21 / The Lux Empire for The Land of Wolves
    Original Concept: Rex Ranch (Community Contribution)

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

Config = {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SERVER BRANDING & INFO ████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.ServerInfo = {
    name        = 'The Land of Wolves 🐺',
    tagline     = 'Georgian RP 🇬🇪 | მგლების მიწა - რჩეულთა ადგილი!',
    description = 'ისტორია ცოცხლდება აქ!',
    type        = 'Serious Hardcore Roleplay',
    access      = 'Discord & Whitelisted',
    website       = 'https://www.wolves.land',
    discord       = 'https://discord.gg/CrKcWdfd3A',
    github        = 'https://github.com/iBoss21',
    store         = 'https://theluxempire.tebex.io',
    serverListing = 'https://servers.redm.net/servers/detail/8gj7eb',
    developer = 'iBoss21 / The Lux Empire',
    tags = {'RedM', 'Georgian', 'SeriousRP', 'Whitelist', 'Ranch', 'Livestock', 'Farming', 'Breeding', 'Economy'}
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ FRAMEWORK CONFIGURATION ███████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

--[[ Framework Priority (in order):
    1. LXR-Core (Primary)
    2. RSG-Core (Primary)
    3. VORP Core (Supported)
    4. Standalone (Fallback)
]]
Config.Framework = 'auto' -- 'auto' or manual: 'lxr-core', 'rsg-core', 'vorp_core', 'standalone'

Config.FrameworkSettings = {
    ['lxr-core'] = {
        resource      = 'lxr-core',
        notifications = 'ox_lib',
        inventory     = 'lxr-inventory',
        target        = 'ox_target',
        events = {
            server   = 'lxr-core:server:%s',
            client   = 'lxr-core:client:%s',
            callback = 'lxr-core:callback:%s'
        }
    },
    ['rsg-core'] = {
        resource      = 'rsg-core',
        notifications = 'ox_lib',
        inventory     = 'rsg-inventory',
        target        = 'ox_target',
        events = {
            server   = 'RSGCore:Server:%s',
            client   = 'RSGCore:Client:%s',
            callback = 'RSGCore:Callback:%s'
        }
    },
    ['vorp_core'] = {
        resource      = 'vorp_core',
        notifications = 'vorp',
        inventory     = 'vorp_inventory',
        target        = 'vorp_core',
        events = {
            server = 'vorp:server:%s',
            client = 'vorp:client:%s'
        }
    },
    ['standalone'] = {
        notifications = 'print',
        inventory     = 'none',
        target        = 'none'
    }
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LANGUAGE CONFIGURATION ████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Lang = 'en'

Config.Locale = {
    en = {
        action_success = 'Action completed successfully.',
        action_failed = 'Action failed. Please try again.',
        no_permission = 'You do not have permission to do this.',
        cooldown_active = 'Please wait before trying again.',
        not_enough_money = 'You do not have enough money.',
        ranch_storage = 'Ranch Storage',
        ranch_overview = 'Ranch Overview',
        ranch_dashboard = 'Ranch Dashboard',
        ranch_locked = 'This ranch is locked due to unpaid taxes!',
        ranch_condition = 'Ranch Condition: %s%%',
        ranch_full = 'Ranch has reached maximum animal capacity.',
        animal_fed = 'Animal has been fed!',
        animal_watered = 'Animal has been watered!',
        animal_cleaned = 'Animal has been cleaned!',
        animal_not_found = 'Animal not found!',
        animal_dead = 'This animal has died.',
        animal_too_young = 'This animal is too young.',
        animal_too_old = 'This animal is too old.',
        animal_needs_feed = 'You need animal feed to feed the animals!',
        animal_needs_water = 'You need a water bucket!',
        animal_health_boost = 'Animal health improved!',
        breeding_started = 'Breeding initiated!',
        breeding_cooldown = 'Breeding cooldown active.',
        breeding_pregnant = 'Animal is pregnant.',
        breeding_born = 'New offspring has been born!',
        breeding_genetics = 'Genetic traits have been inherited.',
        breeding_disabled = 'Breeding system is disabled.',
        breeding_requirements = 'Requirements not met for breeding.',
        product_ready = 'Product is ready for collection!',
        product_collected = 'Product collected!',
        product_not_ready = 'No product ready to collect.',
        production_disabled = 'Production is disabled.',
        purchase_success = 'Successfully purchased!',
        sale_success = 'Successfully sold!',
        sale_failed = 'Sale failed!',
        market_price = 'Market Price',
        staff_hired = 'Employee hired!',
        staff_fired = 'Employee fired!',
        staff_promoted = 'Employee promoted!',
        staff_demoted = 'Employee demoted!',
        staff_max_reached = 'Maximum staff reached!',
        herding_started = 'Herding started!',
        herding_stopped = 'Herding stopped.',
        herding_no_animals = 'No nearby animals found.',
        herding_max_reached = 'Maximum herding capacity reached.',
        herding_disabled = 'Herding is disabled.',
        tax_due = 'Ranch tax is due!',
        tax_paid = 'Tax paid successfully!',
        tax_overdue = 'Tax is overdue!',
        tax_warning = 'Tax payment deadline approaching!',
        tax_locked = 'Ranch locked for unpaid taxes.',
        tax_liquidation = 'Ranch liquidated for non-payment!',
        species_chicken = 'Chicken',
        species_turkey = 'Turkey',
        species_cow = 'Cow',
        species_bull = 'Bull',
        species_sheep = 'Sheep',
        species_goat = 'Goat',
        species_pig = 'Pig',
        nui_overview = 'Overview',
        nui_animals = 'Animals',
        nui_production = 'Production',
        nui_staff = 'Staff',
        nui_storage = 'Storage',
        nui_economy = 'Economy',
        water_bucket_filled = 'Water bucket filled!',
        water_bucket_empty = 'Water bucket is empty!',
        water_bucket_not_empty = 'Bucket is not yet empty.',
    },
    ka = {
        action_success = 'მოქმედება წარმატებით შესრულდა.',
        action_failed = 'მოქმედება ვერ შესრულდა. სცადეთ თავიდან.',
        no_permission = 'თქვენ არ გაქვთ ამის უფლება.',
        cooldown_active = 'გთხოვთ დაელოდოთ.',
        not_enough_money = 'თქვენ არ გაქვთ საკმარისი თანხა.',
        ranch_storage = 'რანჩოს საწყობი',
        ranch_overview = 'რანჩოს მიმოხილვა',
        ranch_dashboard = 'რანჩოს პანელი',
        ranch_locked = 'რანჩო დაბლოკილია გადაუხდელი გადასახადის გამო!',
        ranch_condition = 'რანჩოს მდგომარეობა: %s%%',
        ranch_full = 'რანჩომ მიაღწია მაქსიმალურ ტევადობას.',
        animal_fed = 'ცხოველი გამოკვებულია!',
        animal_watered = 'ცხოველს წყალი მიეცა!',
        animal_cleaned = 'ცხოველი გასუფთავებულია!',
        animal_not_found = 'ცხოველი ვერ მოიძებნა!',
        animal_dead = 'ცხოველი მოკვდა.',
        animal_too_young = 'ცხოველი ძალიან პატარაა.',
        animal_too_old = 'ცხოველი ძალიან მოხუცია.',
        animal_needs_feed = 'საჭიროა საკვები!',
        animal_needs_water = 'საჭიროა წყლის ვედრო!',
        animal_health_boost = 'ჯანმრთელობა გაუმჯობესდა!',
        breeding_started = 'მოშენება დაიწყო!',
        breeding_cooldown = 'მოშენების დასვენება აქტიურია.',
        breeding_pregnant = 'ცხოველი ორსულია.',
        breeding_born = 'ახალი შთამომავალი დაიბადა!',
        breeding_genetics = 'გენეტიკა გადაეცა.',
        breeding_disabled = 'მოშენება გამორთულია.',
        breeding_requirements = 'მოთხოვნები არ არის დაკმაყოფილებული.',
        product_ready = 'პროდუქტი მზადაა!',
        product_collected = 'პროდუქტი შეგროვებულია!',
        product_not_ready = 'პროდუქტი ჯერ არ არის მზად.',
        production_disabled = 'წარმოება გამორთულია.',
        purchase_success = 'წარმატებით შეძენილია!',
        sale_success = 'წარმატებით გაიყიდა!',
        sale_failed = 'გაყიდვა ვერ მოხერხდა!',
        market_price = 'საბაზრო ფასი',
        staff_hired = 'თანამშრომელი დაქირავებულია!',
        staff_fired = 'თანამშრომელი გათავისუფლებულია!',
        staff_promoted = 'თანამშრომელი დაწინაურებულია!',
        staff_demoted = 'თანამშრომელი დაქვეითებულია!',
        staff_max_reached = 'მაქსიმალური პერსონალი!',
        herding_started = 'მართვა დაიწყო!',
        herding_stopped = 'მართვა შეჩერდა.',
        herding_no_animals = 'ცხოველები ვერ მოიძებნა.',
        herding_max_reached = 'მაქსიმალური რაოდენობა.',
        herding_disabled = 'მართვა გამორთულია.',
        tax_due = 'გადასახადი!',
        tax_paid = 'გადასახადი გადახდილია!',
        tax_overdue = 'გადასახადი ვადაგადაცილებულია!',
        tax_warning = 'გაფრთხილება!',
        tax_locked = 'რანჩო დაბლოკილია.',
        tax_liquidation = 'რანჩო ლიკვიდირებულია!',
        species_chicken = 'ქათამი',
        species_turkey = 'ინდაური',
        species_cow = 'ძროხა',
        species_bull = 'ხარი',
        species_sheep = 'ცხვარი',
        species_goat = 'თხა',
        species_pig = 'ღორი',
        nui_overview = 'მიმოხილვა',
        nui_animals = 'ცხოველები',
        nui_production = 'წარმოება',
        nui_staff = 'პერსონალი',
        nui_storage = 'საწყობი',
        nui_economy = 'ეკონომიკა',
        water_bucket_filled = 'ვედრო შევსებულია!',
        water_bucket_empty = 'ვედრო ცარიელია!',
        water_bucket_not_empty = 'ვედრო ჯერ არ არის ცარიელი.',
    }
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ GENERAL SETTINGS ██████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.General = {
    targetDistance     = 2.0,       -- Distance to interact (world units)
    enableSounds      = true,      -- Enable interaction sounds
    enableParticles   = false,     -- Enable particle effects (performance impact)
    requireEmptyHands = false,     -- Require player to have no weapon drawn
    serverNotify      = true,      -- Show server notifications for events
    cronJob           = '*/15 * * * *', -- Cron schedule for animal updates (every 15 min)
    updateClientsOnCron = true,    -- Update client data when cronjob runs
    refreshAfterCron  = true,      -- Full refresh after cronjob completion
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ KEYS CONFIGURATION ████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Keys = {
    interact  = 0x760A9C6F,    -- G key (primary interaction)
    cancel    = 0x8CC9CD42,    -- X key (cancel action)
    herd      = 0xCEFD9220,    -- E key (herding toggle)
    dashboard = 0x4CC0E2FE,    -- B key (open ranch dashboard)
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ TIMING & COOLDOWNS ████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Cooldowns = {
    actionTime        = 5000,      -- Time in ms to complete action
    globalCooldown    = 60000,     -- Global cooldown between uses (ms)
    perPlayerCooldown = true,      -- Track cooldown per player
    actionDelay       = 1000,      -- Delay between actions to prevent spam (ms)
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ ANIMATION CONFIGURATION ███████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

-- Animation settings (Find more: https://github.com/femga/rdr3_discoveries/blob/master/animations/ingameanims/ingameanims_list.lua)
Config.Animation = {
    feed = {
        dict = 'script_common@other@unapproved',
        anim = 'medic_kneel_enter',
        flag = 0
    },
    water = {
        dict = 'script_common@other@unapproved',
        anim = 'medic_kneel_enter',
        flag = 0
    },
    clean = {
        dict = 'amb_camp@world_camp_jack_brush_horse@male_a@idle_a',
        anim = 'idle_a',
        flag = 1
    },
    collect = {
        dict = 'script_common@other@unapproved',
        anim = 'medic_kneel_enter',
        flag = 0
    },
    breed = {
        dict = 'script_common@other@unapproved',
        anim = 'medic_kneel_enter',
        flag = 0
    },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ ANIMAL ID SETTINGS ████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.AnimalId = {
    min              = 100000,     -- Minimum animal ID
    max              = 999999,     -- Maximum animal ID
    fallbackSuffixMin = 1000,     -- Fallback ID suffix minimum
    fallbackSuffixMax = 9999,     -- Fallback ID suffix maximum
    maxLength        = 20,         -- Maximum ID string length
}

-- Backward compatibility aliases
Config.ANIMAL_ID_MIN = Config.AnimalId.min
Config.ANIMAL_ID_MAX = Config.AnimalId.max
Config.FALLBACK_ID_SUFFIX_MIN = Config.AnimalId.fallbackSuffixMin
Config.FALLBACK_ID_SUFFIX_MAX = Config.AnimalId.fallbackSuffixMax
Config.MAX_ID_LENGTH = Config.AnimalId.maxLength

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ RANCH TIERS ███████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.RanchTiers = {
    [1] = {
        label          = 'Homestead',
        maxAnimals     = 10,        -- Maximum animals at this tier
        speciesAllowed = {'chicken', 'turkey'},
        storageSlots   = 50,        -- Storage capacity
        productionBonus = 1.0,      -- Production multiplier
        breedingBonus  = 1.0,       -- Breeding success multiplier
        upgradeCost    = 0,         -- Cost to reach this tier
    },
    [2] = {
        label          = 'Small Ranch',
        maxAnimals     = 20,
        speciesAllowed = {'chicken', 'turkey', 'sheep', 'goat'},
        storageSlots   = 75,
        productionBonus = 1.1,
        breedingBonus  = 1.1,
        upgradeCost    = 500,
    },
    [3] = {
        label          = 'Working Ranch',
        maxAnimals     = 30,
        speciesAllowed = {'chicken', 'turkey', 'sheep', 'goat', 'cattle', 'pig'},
        storageSlots   = 100,
        productionBonus = 1.2,
        breedingBonus  = 1.15,
        upgradeCost    = 1500,
    },
    [4] = {
        label          = 'Large Ranch',
        maxAnimals     = 40,
        speciesAllowed = {'chicken', 'turkey', 'sheep', 'goat', 'cattle', 'pig'},
        storageSlots   = 150,
        productionBonus = 1.35,
        breedingBonus  = 1.25,
        upgradeCost    = 3000,
    },
    [5] = {
        label          = 'Empire Ranch',
        maxAnimals     = 50,
        speciesAllowed = {'chicken', 'turkey', 'sheep', 'goat', 'cattle', 'pig'},
        storageSlots   = 200,
        productionBonus = 1.5,
        breedingBonus  = 1.4,
        upgradeCost    = 5000,
    },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ ANIMAL SPECIES ████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Species = {
    chicken = {
        label      = 'Chicken',
        maleModel  = 'a_c_rooster_01',
        femaleModel = 'a_c_chicken_01',
        maleLabel  = 'Rooster',
        femaleLabel = 'Hen',
        category   = 'poultry',
        scaleTable = { [0]=0.40, [1]=0.50, [2]=0.60, [3]=0.70, [4]=0.80, [5]=0.90 },
    },
    turkey = {
        label      = 'Turkey',
        maleModel  = 'a_c_turkey_01',
        femaleModel = 'a_c_turkey_01',
        maleLabel  = 'Tom',
        femaleLabel = 'Hen',
        category   = 'poultry',
        scaleTable = { [0]=0.40, [1]=0.50, [2]=0.60, [3]=0.70, [4]=0.85, [5]=1.00 },
    },
    cattle = {
        label      = 'Cattle',
        maleModel  = 'a_c_bull_01',
        femaleModel = 'a_c_cow',
        maleLabel  = 'Bull',
        femaleLabel = 'Cow',
        category   = 'livestock',
        scaleTable = { [0]=0.50, [1]=0.60, [2]=0.70, [3]=0.80, [4]=0.90, [5]=1.00 },
    },
    sheep = {
        label      = 'Sheep',
        maleModel  = 'a_c_sheepmerino_01',
        femaleModel = 'a_c_sheepmerino_01',
        maleLabel  = 'Ram',
        femaleLabel = 'Ewe',
        category   = 'livestock',
        scaleTable = { [0]=0.40, [1]=0.50, [2]=0.60, [3]=0.70, [4]=0.85, [5]=1.00 },
    },
    goat = {
        label      = 'Goat',
        maleModel  = 'a_c_goat_01',
        femaleModel = 'a_c_goat_01',
        maleLabel  = 'Buck',
        femaleLabel = 'Doe',
        category   = 'livestock',
        scaleTable = { [0]=0.35, [1]=0.45, [2]=0.55, [3]=0.65, [4]=0.80, [5]=0.95 },
    },
    pig = {
        label      = 'Pig',
        maleModel  = 'a_c_pig_01',
        femaleModel = 'a_c_pig_01',
        maleLabel  = 'Boar',
        femaleLabel = 'Sow',
        category   = 'livestock',
        scaleTable = { [0]=0.40, [1]=0.50, [2]=0.60, [3]=0.70, [4]=0.85, [5]=1.00 },
    },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ NEEDS ENGINE ██████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Needs = {
    hungerDecayRate       = 1,     -- Hunger reduction per cronjob run
    thirstDecayRate       = 1,     -- Thirst reduction per cronjob run
    healthDecayRate       = 1,     -- Health reduction when starving/dehydrated
    cleanlinessDecayRate  = 0.5,   -- Cleanliness passive decay per tick
    stressGainRate        = 0.3,   -- Stress increase from neglect per tick
    minSurvivalStats      = 0,     -- Minimum hunger/thirst before health decays
    healthRegenerationRate = 2,    -- Health regen when well-fed and watered
    minStatsForRegeneration = 80,  -- Min hunger/thirst for health regen
    immediateHealthBoost  = 5,     -- Immediate health boost when feeding unhealthy animal
    stressThreshold       = 80,    -- Stress above this reduces production
    cleanlinessThreshold  = 30,    -- Cleanliness below this causes health decay
}

-- Backward compatibility
Config.HungerDecayRate = Config.Needs.hungerDecayRate
Config.ThirstDecayRate = Config.Needs.thirstDecayRate
Config.HealthDecayRate = Config.Needs.healthDecayRate
Config.MinSurvivalStats = Config.Needs.minSurvivalStats
Config.HealthRegenerationRate = Config.Needs.healthRegenerationRate
Config.MinStatsForRegeneration = Config.Needs.minStatsForRegeneration
Config.ImmediateHealthBoost = Config.Needs.immediateHealthBoost

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ ANIMAL WANDERING ██████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Wandering = {
    enabled        = true,         -- Enable animals to wander naturally
    radius         = 15.0,         -- Max wander distance from spawn point
    minDistance     = 3.0,          -- Minimum distance for a wander movement
    speed          = 1.0,          -- Movement speed (1.0 = walk, 2.0 = jog)
    idleTimeMin    = 10000,        -- Min time (ms) standing still
    idleTimeMax    = 30000,        -- Max time (ms) standing still
    moveTimeMin    = 5000,         -- Min time (ms) spent moving
    moveTimeMax    = 15000,        -- Max time (ms) spent moving
    checkInterval  = 2000,         -- How often to update wander behavior (ms)
}

-- Backward compatibility
Config.AnimalWanderingEnabled = Config.Wandering.enabled
Config.WanderRadius = Config.Wandering.radius
Config.WanderMinDistance = Config.Wandering.minDistance
Config.WanderSpeed = Config.Wandering.speed
Config.WanderIdleTimeMin = Config.Wandering.idleTimeMin
Config.WanderIdleTimeMax = Config.Wandering.idleTimeMax
Config.WanderMoveTimeMin = Config.Wandering.moveTimeMin
Config.WanderMoveTimeMax = Config.Wandering.moveTimeMax
Config.WanderCheckInterval = Config.Wandering.checkInterval

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ FEED & WATER SYSTEM ███████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.FeedWater = {
    feedItem       = 'animal_feed',    -- Item required to feed animals
    waterItem      = 'water_bucket',   -- Item required to water animals
    bucketUses     = 5,                -- Number of uses before refill
    refillCost     = 0,                -- Cost to refill (0 = free)
}

-- Backward compatibility
Config.FeedItem = Config.FeedWater.feedItem
Config.WaterItem = Config.FeedWater.waterItem
Config.WaterBucketUses = Config.FeedWater.bucketUses
Config.WaterRefillCost = Config.FeedWater.refillCost

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ HERDING SYSTEM ████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Herding = {
    enabled            = true,     -- Enable herding system
    distance           = 25.0,     -- Max distance to detect animals
    maxAnimals         = 10,       -- Max animals herded at once
    followDistance     = 3.0,      -- Distance animals maintain while following
    speed              = 1.5,      -- Movement speed when herding
    timeout            = 300,      -- Seconds before herding auto-stops
    requireTool        = false,    -- Require specific item to herd
    tool               = 'weapon_lasso', -- Required item (if enabled)
    individualSelection = true,    -- Enable individual animal selection
    showDistance        = true,    -- Show distance in selection menu
    selectionMultiplier = 1.5,     -- Multiplier for selection range
}

-- Backward compatibility
Config.HerdingEnabled = Config.Herding.enabled
Config.HerdingDistance = Config.Herding.distance
Config.HerdingMaxAnimals = Config.Herding.maxAnimals
Config.HerdingFollowDistance = Config.Herding.followDistance
Config.HerdingSpeed = Config.Herding.speed
Config.HerdingTimeout = Config.Herding.timeout
Config.RequireHerdingTool = Config.Herding.requireTool
Config.HerdingTool = Config.Herding.tool
Config.IndividualSelectionEnabled = Config.Herding.individualSelection
Config.ShowAnimalDistance = Config.Herding.showDistance
Config.SelectionRangeMultiplier = Config.Herding.selectionMultiplier

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ PRODUCTION ENGINE █████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Production = {
    enabled            = true,     -- Enable production system
    checkInterval      = 3600,     -- Seconds between production checks (1 hour)
    minAge             = 5,        -- Min age (days) before animals produce
}

-- Backward compatibility
Config.ProductionEnabled = Config.Production.enabled
Config.ProductionCheckInterval = Config.Production.checkInterval
Config.MinAgeForProduction = Config.Production.minAge

Config.AnimalProducts = {
    ['a_c_bull_01'] = {
        product = 'fertilizer', productionTime = 3600, amount = 1,
        requiresHealth = 60, requiresHunger = 40, requiresThirst = 40,
    },
    ['a_c_cow'] = {
        product = 'milk', productionTime = 3600, amount = 1,
        requiresHealth = 60, requiresHunger = 40, requiresThirst = 40,
    },
    ['a_c_chicken_01'] = {
        product = 'eggs', productionTime = 1800, amount = 2,
        requiresHealth = 50, requiresHunger = 30, requiresThirst = 30,
    },
    ['a_c_rooster_01'] = {
        product = 'feathers', productionTime = 7200, amount = 1,
        requiresHealth = 50, requiresHunger = 30, requiresThirst = 30,
    },
    ['a_c_turkey_01'] = {
        product = 'feathers', productionTime = 5400, amount = 1,
        requiresHealth = 50, requiresHunger = 30, requiresThirst = 30,
    },
    ['a_c_sheepmerino_01'] = {
        product = 'wool', productionTime = 7200, amount = 1,
        requiresHealth = 60, requiresHunger = 40, requiresThirst = 40,
    },
    ['a_c_goat_01'] = {
        product = 'milk', productionTime = 5400, amount = 1,
        requiresHealth = 55, requiresHunger = 35, requiresThirst = 35,
    },
    ['a_c_pig_01'] = {
        product = 'fertilizer', productionTime = 3600, amount = 1,
        requiresHealth = 50, requiresHunger = 30, requiresThirst = 30,
    },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ BREEDING & GENETICS ███████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Breeding = {
    enabled                = true,
    minAge                 = 5,       -- Days old before breeding
    maxAge                 = 30,      -- Days old after which breeding stops
    distance               = 10.0,    -- Max distance between animals to breed
    cooldown               = 86400,   -- Default cooldown (1 day)
    healthRequirement      = 70,
    hungerRequirement      = 50,
    thirstRequirement      = 50,
    restrictMaleWhenPregnant = true,  -- Prevent males breeding when females pregnant
    autoEnabled            = true,    -- Automatic breeding between compatible animals
    autoCheckInterval      = 60,      -- Auto breeding check interval (seconds)
    autoMaxDistance         = 5.0,    -- Max distance for auto breeding
    autoNotifications      = true,    -- Notify owners on auto breeding
    geneticsEnabled        = true,    -- Enable genetic inheritance
    mutationChance         = 0.05,   -- 5% chance of genetic mutation
}

-- Backward compatibility
Config.BreedingEnabled = Config.Breeding.enabled
Config.MinAgeForBreeding = Config.Breeding.minAge
Config.MaxBreedingAge = Config.Breeding.maxAge
Config.BreedingDistance = Config.Breeding.distance
Config.BreedingCooldown = Config.Breeding.cooldown
Config.RequireHealthForBreeding = Config.Breeding.healthRequirement
Config.RequireHungerForBreeding = Config.Breeding.hungerRequirement
Config.RequireThirstForBreeding = Config.Breeding.thirstRequirement
Config.RestrictMaleBreedingWhenFemalesPregnant = Config.Breeding.restrictMaleWhenPregnant
Config.AutomaticBreedingEnabled = Config.Breeding.autoEnabled
Config.AutomaticBreedingCheckInterval = Config.Breeding.autoCheckInterval
Config.AutomaticBreedingMaxDistance = Config.Breeding.autoMaxDistance
Config.AutomaticBreedingNotifications = Config.Breeding.autoNotifications

Config.GenderSpecificCooldowns = {
    male   = 3600,     -- 1 hour cooldown for males
    female = 86400,    -- 24 hours for females
}

Config.GenderRatios = {
    ['a_c_bull_01']       = 1.0,   -- 100% male
    ['a_c_cow']           = 0.0,   -- 100% female
    ['a_c_chicken_01']    = 0.0,   -- 100% female (hen)
    ['a_c_rooster_01']    = 1.0,   -- 100% male (rooster)
    ['a_c_turkey_01']     = 0.5,   -- 50/50
    ['a_c_sheepmerino_01'] = 0.5,  -- 50/50
    ['a_c_goat_01']       = 0.5,   -- 50/50
    ['a_c_pig_01']        = 0.5,   -- 50/50
}

Config.BreedingConfig = {
    ['a_c_bull_01'] = {
        gestationPeriod = 259200, offspringCount = { min = 1, max = 1 },
        breedingSeasonStart = 1, breedingSeasonEnd = 365, enabled = true,
        offspringModels = { { model = 'a_c_cow', chance = 100 } }
    },
    ['a_c_cow'] = {
        gestationPeriod = 259200, offspringCount = { min = 1, max = 1 },
        breedingSeasonStart = 1, breedingSeasonEnd = 365, enabled = true,
        offspringModels = { { model = 'a_c_cow', chance = 50 }, { model = 'a_c_bull_01', chance = 50 } }
    },
    ['a_c_chicken_01'] = {
        gestationPeriod = 86400, offspringCount = { min = 1, max = 3 },
        breedingSeasonStart = 1, breedingSeasonEnd = 365, enabled = true,
        offspringModels = { { model = 'a_c_chicken_01', chance = 60 }, { model = 'a_c_rooster_01', chance = 40 } }
    },
    ['a_c_turkey_01'] = {
        gestationPeriod = 129600, offspringCount = { min = 1, max = 2 },
        breedingSeasonStart = 1, breedingSeasonEnd = 365, enabled = true,
        offspringModels = { { model = 'a_c_turkey_01', chance = 100 } }
    },
    ['a_c_sheepmerino_01'] = {
        gestationPeriod = 216000, offspringCount = { min = 1, max = 2 },
        breedingSeasonStart = 1, breedingSeasonEnd = 365, enabled = true,
        offspringModels = { { model = 'a_c_sheepmerino_01', chance = 100 } }
    },
    ['a_c_goat_01'] = {
        gestationPeriod = 194400, offspringCount = { min = 1, max = 2 },
        breedingSeasonStart = 1, breedingSeasonEnd = 365, enabled = true,
        offspringModels = { { model = 'a_c_goat_01', chance = 100 } }
    },
    ['a_c_pig_01'] = {
        gestationPeriod = 172800, offspringCount = { min = 2, max = 4 },
        breedingSeasonStart = 1, breedingSeasonEnd = 365, enabled = true,
        offspringModels = { { model = 'a_c_pig_01', chance = 100 } }
    },
}

Config.Genetics = {
    enabled        = true,
    mutationChance = 0.05,          -- 5% mutation chance per gene
    traits = {
        productionGene  = { min = 0.5, max = 1.5, default = 1.0 },
        healthGene      = { min = 0.5, max = 1.5, default = 1.0 },
        growthGene      = { min = 0.5, max = 1.5, default = 1.0 },
    },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ ECONOMY & MARKETS █████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Economy = {
    dynamicPricing      = true,        -- Enable supply/demand pricing
    priceUpdateInterval = 1800000,     -- Price update interval (ms) (30 min)
    minPriceMultiplier  = 0.5,         -- Minimum price (50% of base)
    maxPriceMultiplier  = 2.0,         -- Maximum price (200% of base)

    baseBuyPrices = {
        ['a_c_bull_01']       = 100,   -- Bull buy price
        ['a_c_cow']           = 50,    -- Cow buy price
        ['a_c_chicken_01']    = 10,    -- Chicken buy price
        ['a_c_rooster_01']    = 15,    -- Rooster buy price
        ['a_c_turkey_01']     = 20,    -- Turkey buy price
        ['a_c_sheepmerino_01'] = 40,   -- Sheep buy price
        ['a_c_goat_01']       = 35,    -- Goat buy price
        ['a_c_pig_01']        = 30,    -- Pig buy price
    },

    baseSellPrices = {
        ['a_c_bull_01']       = 400,   -- Bull sell price
        ['a_c_cow']           = 150,   -- Cow sell price
        ['a_c_chicken_01']    = 25,    -- Chicken sell price
        ['a_c_rooster_01']    = 30,    -- Rooster sell price
        ['a_c_turkey_01']     = 60,    -- Turkey sell price
        ['a_c_sheepmerino_01'] = 120,  -- Sheep sell price
        ['a_c_goat_01']       = 100,   -- Goat sell price
        ['a_c_pig_01']        = 90,    -- Pig sell price
    },

    minAgeToSell    = 6,               -- Minimum age (days) to sell
    primeAgeStart   = 6,               -- Prime age start (days)
    primeAgeEnd     = 30,              -- Prime age end (days)
    oldAgeStart     = 31,              -- Old age start (days)
    saleDistance     = 15.0,           -- Animal must be within this distance of sale point
    requirePresent   = true,           -- Require animal at sale point
    transportMode    = true,           -- Keep animals spawned during transport
    buyPointSpawnDistance = 8.0,        -- Distance from buy point for spawning
}

-- Backward compatibility
Config.BullBuyPrice = Config.Economy.baseBuyPrices['a_c_bull_01']
Config.BullSellPrice = 1
Config.CowBuyPrice = Config.Economy.baseBuyPrices['a_c_cow']
Config.CowSellPrice = 1
Config.BaseSellPrices = Config.Economy.baseSellPrices
Config.MinAgeToSell = Config.Economy.minAgeToSell
Config.PrimeAgeStart = Config.Economy.primeAgeStart
Config.PrimeAgeEnd = Config.Economy.primeAgeEnd
Config.OldAgeStart = Config.Economy.oldAgeStart
Config.AnimalSaleDistance = Config.Economy.saleDistance
Config.RequireAnimalPresent = Config.Economy.requirePresent
Config.TransportMode = Config.Economy.transportMode
Config.BuyPointSpawnDistance = Config.Economy.buyPointSpawnDistance

Config.AgePricing = {
    young = 0.5,     -- Below prime age (50% of base)
    prime = 1.5,     -- In prime age (150% of base)
    adult = 1.0,     -- Between prime and old (100%)
    old   = 0.7,     -- Old animals (70% of base)
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ TAXATION SYSTEM ███████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Taxation = {
    enabled           = true,      -- Enable taxation system
    baseTax           = 50,        -- Base tax amount per cycle
    tierMultiplier    = 25,        -- Additional tax per tier level
    cycleDays         = 7,         -- Tax cycle length in days
    warningDays       = 3,         -- Days past due before warning
    lockDays          = 7,         -- Days past due before ranch lock
    liquidationDays   = 14,        -- Days past due before liquidation
    checkInterval     = 3600000,   -- Tax check interval (ms) (1 hour)
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ STAFF MANAGEMENT ██████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Staff = {
    minGradeToManage    = 2,       -- Min grade to manage staff
    maxEmployeesPerRanch = 20,     -- Max employees per ranch
    enableSalarySystem  = false,   -- Enable salary payments
}

-- Backward compatibility
Config.StaffManagement = {
    MinGradeToManage = Config.Staff.minGradeToManage,
    MaxEmployeesPerRanch = Config.Staff.maxEmployeesPerRanch,
    EnableSalarySystem = Config.Staff.enableSalarySystem,
    Permissions = {
        [0] = { -- Trainee
            canFeedAnimals = true, canWaterAnimals = true,
            canCollectProducts = false, canBreed = false,
            canSell = false, canBuy = false, canManageStaff = false,
        },
        [1] = { -- Ranch Hand
            canFeedAnimals = true, canWaterAnimals = true,
            canCollectProducts = true, canBreed = true,
            canSell = false, canBuy = false, canManageStaff = false,
        },
        [2] = { -- Manager
            canFeedAnimals = true, canWaterAnimals = true,
            canCollectProducts = true, canBreed = true,
            canSell = true, canBuy = true, canManageStaff = true,
        },
        [3] = { -- Boss
            canFeedAnimals = true, canWaterAnimals = true,
            canCollectProducts = true, canBreed = true,
            canSell = true, canBuy = true, canManageStaff = true,
        },
    }
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ STORAGE SYSTEM ████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Storage = {
    maxWeight     = 10000000,      -- Maximum storage weight
    maxSlots      = 100,           -- Maximum storage slots
    minJobGrade   = 1,             -- Minimum job grade for storage access
}

-- Backward compatibility
Config.RanchStorageMaxWeight = Config.Storage.maxWeight
Config.RanchStorageMaxSlots = Config.Storage.maxSlots
Config.StorageMinJobGrade = Config.Storage.minJobGrade

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ RANCH LOCATIONS ███████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

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
        spawnpoint = vector4(-2425.51, -2367.51, 61.18, 82.40),
        tier = 1,
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
        spawnpoint = vector4(1400.58, 290.48, 88.57, 19.79),
        tier = 1,
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
        spawnpoint = vector4(-2567.10, 404.34, 148.61, 83.07),
        tier = 1,
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
        spawnpoint = vector4(-850.30, 334.23, 95.77, 189.21),
        tier = 1,
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
        spawnpoint = vector4(1373.20, -845.12, 70.56, 301.98),
        tier = 1,
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
        spawnpoint = vector4(-2208.03, 719.73, 122.54, 185.14),
        tier = 1,
    },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ BUY POINT LOCATIONS ███████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.BuyPointLocations = {
    {
        name = 'Livestock Dealer',
        coords = vector3(-218.78, 652.80, 113.27),
        npcmodel = `mp_u_m_m_trader_01`,
        npccoords = vec4(-218.78, 652.80, 113.27, 241.67),
        blipname = 'Livestock Dealer',
        blipsprite = 'blip_shop_horse',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vec4(-217.61, 649.48, 113.10, 195.09),
    },
    {
        name = 'Livestock Dealer',
        coords = vector3(-1834.75, -578.28, 155.97),
        npcmodel = `mp_u_m_m_trader_01`,
        npccoords = vector4(-1834.75, -578.28, 155.97, 304.67),
        blipname = 'Livestock Dealer',
        blipsprite = 'blip_shop_horse',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-1830.77, -576.25, 155.97, 291.70),
    },
    {
        name = 'Livestock Dealer',
        coords = vector3(-1309.82, 387.21, 95.35),
        npcmodel = `mp_u_m_m_trader_01`,
        npccoords = vector4(-1309.82, 387.21, 95.35, 167.82),
        blipname = 'Livestock Dealer',
        blipsprite = 'blip_shop_horse',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vec4(-1311.06, 385.14, 95.51, 95.24),
    },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SALE POINT LOCATIONS ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.SalePointLocations = {
    {
        name = 'Livestock Market',
        coords = vector3(-230.28, 637.59, 113.38),
        npcmodel = `cs_valauctionboss_01`,
        npccoords = vec4(-230.28, 637.59, 113.38, 243.69),
        blipname = 'Livestock Market',
        blipsprite = 'blip_shop_store',
        blipscale = 0.2,
        showblip = true,
    },
    {
        name = 'Livestock Market',
        coords = vector3(-1791.83, -579.00, 155.95),
        npcmodel = `cs_valauctionboss_01`,
        npccoords = vector4(-1791.83, -579.00, 155.95, 28.21),
        blipname = 'Livestock Market',
        blipsprite = 'blip_shop_store',
        blipscale = 0.2,
        showblip = true,
    },
    {
        name = 'Livestock Market',
        coords = vector3(-1308.77, 375.84, 96.4),
        npcmodel = `cs_valauctionboss_01`,
        npccoords = vec4(-1308.77, 375.84, 96.46, 90.13),
        blipname = 'Livestock Market',
        blipsprite = 'blip_shop_store',
        blipscale = 0.2,
        showblip = true,
    },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ MARKET LOCATIONS ██████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.MarketLocations = Config.SalePointLocations -- Markets co-located with sale points

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ WATER PROPS ███████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.WaterProps = {
    `p_wellpumpnbx01x`,
    `p_watertrough01x`,
    `p_watertroughsml01x`,
    `p_watertrough01x_new`,
    `p_watertrough02x`,
    `p_watertrough03x`,
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ NPC SETTINGS ██████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.NPC = {
    distanceSpawn       = 50.0,    -- NPC spawn distance
    fadeIn              = true,     -- Fade in NPCs
    animalDistanceSpawn = 50.0,    -- Animal spawn distance
    animalFadeIn        = true,     -- Fade in animals
    blipHash            = 1664425300, -- Default blip hash
}

-- Backward compatibility
Config.DistanceSpawn = Config.NPC.distanceSpawn
Config.FadeIn = Config.NPC.fadeIn
Config.AnimalDistanceSpawn = Config.NPC.animalDistanceSpawn
Config.AnimalFadeIn = Config.NPC.animalFadeIn
Config.MaxRanchAnimals = 10
Config.AnimalCronJob = Config.General.cronJob
Config.UpdateClientsOnCron = Config.General.updateClientsOnCron
Config.RefreshAfterCron = Config.General.refreshAfterCron
Config.ServerNotify = Config.General.serverNotify

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ NUI SETTINGS ██████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.NUI = {
    enabled            = true,     -- Enable NUI dashboard
    refreshInterval    = 30000,    -- Auto-refresh interval (ms)
    showConditionScore = true,     -- Show condition score on dashboard
    showMarketPrices   = true,     -- Show dynamic market prices
    showTaxStatus      = true,     -- Show tax status
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SECURITY & ANTI-ABUSE █████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Security = {
    enabled              = true,       -- Enable security checks
    maxDistance           = 5.0,        -- Max distance for server-side validation
    maxActionsPerMinute  = 10,         -- Rate limit per player per minute
    actionCooldown       = 2000,       -- Cooldown between actions (ms)
    requireLineOfSight   = false,      -- Require LoS to target
    validateTargetExists = true,       -- Validate target still exists
    logSuspiciousActivity = true,      -- Log suspicious behavior
    kickOnExploit        = false,      -- Kick player on detected exploit
    banOnExploit         = false,      -- Ban player on detected exploit
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ PERFORMANCE OPTIMIZATION ██████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Performance = {
    cacheEnabled      = true,      -- Cache data for faster lookups
    updateInterval    = 1000,      -- Client update interval (ms)
    maxNearbyEntities = 50,        -- Max nearby entities to track
    cleanupInterval   = 300000,    -- Cleanup stale data interval (ms)
    lodNearDistance   = 50.0,      -- Full simulation distance
    lodMidDistance    = 150.0,     -- Reduced simulation distance
    lodFarDistance    = 300.0,     -- Statistical-only distance
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ DEBUG SETTINGS █████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Debug = false               -- Enable debug prints and extra logging

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ END OF CONFIGURATION ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

CreateThread(function()
    Wait(1000)
    local speciesCount = 0
    for _ in pairs(Config.Species) do speciesCount = speciesCount + 1 end
    local ranchCount = #Config.RanchLocations
    local buyPointCount = #Config.BuyPointLocations
    local salePointCount = #Config.SalePointLocations

    print([[
        
        ═══════════════════════════════════════════════════════════════════════════════
        
            ██╗     ██╗  ██╗██████╗       ██████╗  █████╗ ███╗   ██╗ ██████╗██╗  ██╗
            ██║     ╚██╗██╔╝██╔══██╗      ██╔══██╗██╔══██╗████╗  ██║██╔════╝██║  ██║
            ██║      ╚███╔╝ ██████╔╝█████╗██████╔╝███████║██╔██╗ ██║██║     ███████║
            ██║      ██╔██╗ ██╔══██╗╚════╝██╔══██╗██╔══██║██║╚██╗██║██║     ██╔══██║
            ███████╗██╔╝ ██╗██║  ██║      ██║  ██║██║  ██║██║ ╚████║╚██████╗██║  ██║
            ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝
        
        ═══════════════════════════════════════════════════════════════════════════════
        🐺 LXR-RANCH - SUCCESSFULLY LOADED
        ═══════════════════════════════════════════════════════════════════════════════
        
        Version:     1.0.0
        Server:      ]] .. Config.ServerInfo.name .. [[
        
        Framework:   Auto-detect enabled
        Species:     ]] .. speciesCount .. [[ types configured
        Ranches:     ]] .. ranchCount .. [[ locations
        Buy Points:  ]] .. buyPointCount .. [[ locations
        Sale Points: ]] .. salePointCount .. [[ locations
        Tiers:       5 levels (Homestead → Empire)
        Taxation:    ]] .. (Config.Taxation.enabled and 'ENABLED ✓' or 'DISABLED ✗') .. [[
        
        Economy:     ]] .. (Config.Economy.dynamicPricing and 'Dynamic Pricing ENABLED ✓' or 'Fixed Pricing') .. [[
        Genetics:    ]] .. (Config.Genetics.enabled and 'ENABLED ✓' or 'DISABLED ✗') .. [[
        NUI:         ]] .. (Config.NUI.enabled and 'ENABLED ✓' or 'DISABLED ✗') .. [[
        Security:    ]] .. (Config.Security.enabled and 'ENABLED ✓' or 'DISABLED ✗') .. [[
        Debug:       ]] .. (Config.Debug and 'ENABLED' or 'DISABLED') .. [[
        
        ═══════════════════════════════════════════════════════════════════════════════
        
        Developer:   iBoss21 / The Lux Empire
        Website:     https://www.wolves.land
        Discord:     https://discord.gg/CrKcWdfd3A
        
        ═══════════════════════════════════════════════════════════════════════════════
        
    ]])
end)
