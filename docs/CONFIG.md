# 🐺 LXR-RANCH — Configuration Guide

> **The Land of Wolves** | **The Lux Empire**
> Version 1.0.0

---

## Overview

All configuration is centralized in `config.lua`. Protected files (client/server/shared) read from `Config.*` exclusively.

## Sections

### Config.ServerInfo
Server branding and contact information. Used in startup banner.

### Config.Framework
Set to `'auto'` for automatic detection or manually specify: `'lxr-core'`, `'rsg-core'`, `'vorp_core'`, `'standalone'`

### Config.Locale
Inline translations for English (`en`) and Georgian (`ka`). 80+ translation keys.

### Config.General
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| targetDistance | number | 2.0 | Interaction distance in world units |
| enableSounds | boolean | true | Enable interaction sounds |
| enableParticles | boolean | false | Enable particle effects |
| requireEmptyHands | boolean | false | Require no weapon drawn |

### Config.RanchTiers
5 tiers with progressive unlocks. Each tier defines: maxAnimals, species unlocks, storage capacity, production bonus, breeding bonus.

### Config.Species
Per-species configuration including: models, display names, growth stages, scale tables, base stats.

### Config.Needs
Hunger, thirst, health, cleanliness, and stress decay rates with threshold effects.

### Config.Production
Per-species output items, production intervals, and stat requirements.

### Config.Breeding
Per-species gestation periods, offspring models, gender ratios, genetic inheritance rules.

### Config.Economy
Buy/sell prices, age-based multipliers, dynamic pricing settings.

### Config.Taxation
Weekly tax cycles, base rate, tier multiplier, penalty days (warning/lock/liquidation).

### Config.Staff
Grade-based permissions, max employees, salary system toggle.

### Config.Security
Rate limiting, max distance validation, suspicious activity logging, exploit detection.

### Config.Performance
LOD distances, cache settings, update intervals, cleanup timers.

### Config.Debug
Set to `true` for verbose server/client logging.

---

**🐺 wolves.land — The Land of Wolves**
**© 2026 iBoss21 / The Lux Empire — All Rights Reserved**
