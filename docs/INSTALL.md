# 🐺 LXR-RANCH — Installation Guide

> **The Land of Wolves** | **The Lux Empire**
> Version 1.0.0

---

## Prerequisites

- RedM Server (latest build)
- One of: LXR-Core, RSG-Core, or VORP-Core
- [ox_lib](https://github.com/overextended/ox_lib) (latest)
- [oxmysql](https://github.com/overextended/oxmysql) (latest)

## Step 1: Database Setup

Import the SQL file into your database:

```sql
mysql -u root -p your_database < installation/lxr-ranch.sql
```

Or paste the contents of `installation/lxr-ranch.sql` into your database management tool (HeidiSQL, phpMyAdmin, etc.).

This creates 6 tables:
- `lxr_ranch_animals` — Animal data and lifecycle
- `lxr_ranches` — Ranch ownership, tiers, condition
- `lxr_ranch_permissions` — Access control
- `lxr_ranch_storage` — Per-ranch inventory
- `lxr_ranch_transactions` — Economy audit trail
- `lxr_ranch_tax_records` — Tax payment history

## Step 2: Items Setup

Add the items from `installation/shared_items.lua` to your framework's shared items file.

Required items: `animal_feed`, `water_bucket`, `milk`, `fertilizer`, `eggs`, `feathers`, `wool`, `raw_meat`

## Step 3: Jobs Setup

Add the ranch jobs from `installation/shared_jobs.lua` to your framework's shared jobs file.

Each ranch location needs a matching job with 4 grades:
- Grade 0: Trainee
- Grade 1: Ranch Hand
- Grade 2: Manager
- Grade 3: Boss

## Step 4: Resource Installation

1. Place the `lxr-ranch` folder in your server's `resources/` directory
2. **Important:** The folder MUST be named exactly `lxr-ranch`
3. Add `ensure lxr-ranch` to your `server.cfg` AFTER your framework and ox_lib

## Step 5: Configuration

Edit `config.lua` to customize:
- Ranch locations and coordinates
- Animal species and pricing
- Breeding and production settings
- Tax rates and cycles
- Staff permissions
- Security settings

See [CONFIG.md](CONFIG.md) for detailed option descriptions.

## Start Order

```cfg
ensure oxmysql
ensure ox_lib
ensure rsg-core        # or lxr-core / vorp_core
ensure rsg-inventory   # or lxr-inventory / vorp_inventory
ensure lxr-ranch
```

## Verification

After starting the server, check the console for:
```
LXR-RANCH - SUCCESSFULLY LOADED
```

If you see a resource name mismatch error, ensure the folder is named `lxr-ranch`.

---

**🐺 wolves.land — The Land of Wolves**
**© 2026 iBoss21 / The Lux Empire — All Rights Reserved**
