--[[ ═══════════════════════════════════════════════════════════════════════════
     🐺 LXR-RANCH — The Land of Wolves — Locale: English
     ═══════════════════════════════════════════════════════════════════════════ ]]

Locales = Locales or {}

Locales['en'] = {

    -- ─── General ─────────────────────────────────────────────────────────────
    action_success              = 'Action completed successfully.',
    action_failed               = 'Action failed. Please try again.',
    no_permission               = 'You do not have permission to do that.',
    cooldown_active             = 'Please wait before performing this action again.',
    not_enough_money            = 'You do not have enough money.',
    invalid_input               = 'Invalid input provided.',
    server_error                = 'A server error occurred. Please try again later.',
    loading                     = 'Loading...',
    confirm_action              = 'Are you sure you want to proceed?',
    cancel                      = 'Action cancelled.',

    -- ─── Ranch ───────────────────────────────────────────────────────────────
    ranch_storage               = 'Ranch Storage',
    ranch_overview              = 'Ranch Overview',
    ranch_dashboard             = 'Ranch Dashboard',
    ranch_locked                = 'This ranch is currently locked.',
    ranch_condition             = 'Ranch Condition: %s%%',
    ranch_not_found             = 'Ranch not found.',
    ranch_full                  = 'This ranch has reached its maximum animal capacity.',
    ranch_upgraded              = 'Ranch has been upgraded to tier %s.',
    ranch_tier                  = 'Ranch Tier: %s',
    ranch_no_access             = 'You do not have access to this ranch.',

    -- ─── Animals ─────────────────────────────────────────────────────────────
    animal_fed                  = 'Animal has been fed successfully.',
    animal_watered              = 'Animal has been watered successfully.',
    animal_cleaned              = 'Animal has been cleaned successfully.',
    animal_not_found            = 'Animal not found.',
    animal_dead                 = 'This animal has died.',
    animal_too_young            = 'This animal is too young for this action.',
    animal_too_old              = 'This animal is too old for this action.',
    animal_health_low           = 'This animal\'s health is too low.',
    animal_hungry               = 'This animal is hungry and needs feeding.',
    animal_thirsty              = 'This animal is thirsty and needs water.',
    animal_stressed             = 'This animal is stressed. Reduce workload.',
    animal_info                 = 'Animal Info: %s | Health: %s%% | Age: %s days',
    animal_needs_feed           = 'You need animal feed to feed this animal!',
    animal_needs_water          = 'You need a water bucket!',
    animal_health_boost         = 'Animal health has been boosted!',

    -- ─── Breeding ────────────────────────────────────────────────────────────
    breeding_started            = 'Breeding has been initiated.',
    breeding_cooldown           = 'This animal is on breeding cooldown. Ready in %s.',
    breeding_pregnant           = 'The animal is now pregnant! Expected birth in %s.',
    breeding_born               = 'A new animal has been born at %s!',
    breeding_genetics           = 'Offspring genetics: Health %s%%, Yield %s%%.',
    breeding_failed             = 'Breeding attempt failed.',
    breeding_incompatible       = 'These animals are not compatible for breeding.',
    breeding_no_male            = 'No suitable male found nearby.',
    breeding_no_female          = 'No suitable female found nearby.',
    breeding_already_pregnant   = 'This animal is already pregnant.',
    breeding_requirements       = 'Animal does not meet breeding requirements.',
    breeding_disabled           = 'The breeding system is currently disabled.',
    breeding_too_young          = 'Too young for breeding.',
    breeding_too_old            = 'Too old for breeding.',

    -- ─── Production ──────────────────────────────────────────────────────────
    product_ready               = 'Product is ready for collection!',
    product_collected           = 'Product collected: %sx %s.',
    product_not_ready           = 'Product is not ready yet. Check back in %s.',
    production_disabled         = 'Production is currently disabled for this animal.',
    production_requirements     = 'Animal does not meet production requirements.',
    production_inventory_full   = 'Storage is full. Make room before collecting.',

    -- ─── Economy ─────────────────────────────────────────────────────────────
    purchase_success            = 'Purchase successful! Paid $%s.',
    sale_success                = 'Sale successful! Received $%s.',
    sale_failed                 = 'Sale failed. Please try again.',
    market_price                = 'Current market price: $%s.',
    dynamic_pricing             = 'Prices have shifted due to market demand.',
    insufficient_funds          = 'Insufficient funds for this transaction.',
    transaction_complete        = 'Transaction complete.',
    price_increase              = 'Market prices have increased!',
    price_decrease              = 'Market prices have decreased.',

    -- ─── Staff ───────────────────────────────────────────────────────────────
    staff_hired                 = '%s has been hired as %s.',
    staff_fired                 = '%s has been removed from the ranch.',
    staff_promoted              = '%s has been promoted to %s.',
    staff_demoted               = '%s has been demoted to %s.',
    staff_max_reached           = 'Maximum staff capacity reached.',
    staff_already_employed      = 'This person is already employed at a ranch.',
    staff_not_found             = 'Staff member not found.',
    staff_salary_paid           = 'Salaries have been paid: $%s total.',

    -- ─── Herding ─────────────────────────────────────────────────────────────
    herding_started             = 'Herding started. %s animals following.',
    herding_stopped             = 'Herding stopped.',
    herding_no_animals          = 'No animals found nearby to herd.',
    herding_max_reached         = 'Maximum herding capacity reached (%s animals).',
    herding_animal_added        = 'Animal added to herd.',
    herding_animal_removed      = 'Animal removed from herd.',
    herding_timeout             = 'Herding timed out. Animals released.',
    herding_too_far             = 'You are too far from the animals.',
    herding_disabled            = 'The herding system is currently disabled.',

    -- ─── Taxation ────────────────────────────────────────────────────────────
    tax_due                     = 'Ranch tax due: $%s. Pay before %s.',
    tax_paid                    = 'Tax payment of $%s received. Thank you!',
    tax_overdue                 = 'Your ranch tax is overdue! Penalties are accumulating.',
    tax_warning                 = 'Tax warning: Payment is due in %s days.',
    tax_locked                  = 'Ranch operations are locked due to unpaid taxes.',
    tax_liquidation             = 'Your ranch is under liquidation review for unpaid taxes.',
    tax_penalty                 = 'A penalty of $%s has been applied for late payment.',
    tax_exempt                  = 'This ranch is currently tax exempt.',

    -- ─── Species Names ───────────────────────────────────────────────────────
    species_chicken             = 'Chicken',
    species_turkey              = 'Turkey',
    species_cow                 = 'Cow',
    species_bull                = 'Bull',
    species_sheep               = 'Sheep',
    species_goat                = 'Goat',
    species_pig                 = 'Pig',
    species_horse               = 'Horse',
    species_donkey              = 'Donkey',
    species_rooster             = 'Rooster',

    -- ─── NUI ─────────────────────────────────────────────────────────────────
    nui_overview                = 'Overview',
    nui_animals                 = 'Animals',
    nui_production              = 'Production',
    nui_staff                   = 'Staff',
    nui_storage                 = 'Storage',
    nui_economy                 = 'Economy',
    nui_breeding                = 'Breeding',
    nui_settings                = 'Settings',
    nui_close                   = 'Close',
    nui_confirm                 = 'Confirm',
    nui_cancel                  = 'Cancel',
    nui_search                  = 'Search...',
    nui_no_data                 = 'No data available.',
    nui_refresh                 = 'Refresh',

    -- ─── Water ───────────────────────────────────────────────────────────────
    water_bucket_filled         = 'Water bucket has been filled!',
    water_bucket_empty          = 'Water bucket is empty!',
    water_bucket_not_empty      = 'Bucket is not empty yet.',
}

--[[ ═══════════════════════════════════════════════════════════════════════════
     🐺 LXR-RANCH — wolves.land — End of English Locale
     ═══════════════════════════════════════════════════════════════════════════ ]]
