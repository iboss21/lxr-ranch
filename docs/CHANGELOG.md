# 🐺 LXR-RANCH — Changelog

> **The Land of Wolves** | **The Lux Empire**

---

## [1.0.0] - 2026-03-30

### Added
- Complete wolves.land branding with ASCII banners and section dividers
- Multi-framework bridge (LXR Core, RSG Core, VORP Core, Standalone)
- Resource name guard for Tebex escrow compliance
- Anti-abuse system with rate limiting and cooldowns
- Ranch tier system (5 tiers with progressive unlocks)
- Expanded species: Chickens, Turkeys, Sheep, Goats, Pigs (in addition to Bulls, Cows)
- Needs engine with cleanliness and stress (in addition to hunger, thirst, health)
- Condition score system (Food + Water + Health + Cleanliness) / 4
- Genetic inheritance system for breeding
- Dynamic economy engine with supply/demand pricing
- Weekly taxation system with penalty progression
- NUI ranch dashboard with 6 tabs (Overview, Animals, Production, Staff, Storage, Economy)
- Expanded production outputs: eggs, feathers, wool, raw_meat
- Market locations for dedicated animal marketplaces
- Full documentation suite (INSTALL, CONFIG, FRAMEWORKS, EVENTS, TROUBLESHOOTING)
- Tebex product templates
- English and Georgian locale files
- Expanded database schema (6 tables)

### Changed
- Renamed resource from rex-ranch to lxr-ranch
- Renamed all events from rex-ranch: to lxr-ranch: prefix
- Renamed database table from rex_ranch_animals to lxr_ranch_animals
- Moved config.lua from shared/ to root level
- Expanded config.lua from 445 lines to 1200+ lines with 25+ branded sections
- Replaced hardcoded RSGCore references with framework bridge

### Removed
- server/versionchecker.lua (replaced by wolves.land standard)
- locales/en.json (replaced by locales/en.lua)

---

**🐺 wolves.land — The Land of Wolves**
**© 2026 iBoss21 / The Lux Empire — All Rights Reserved**
