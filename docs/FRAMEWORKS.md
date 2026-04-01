# 🐺 LXR-RANCH — Framework Support

> **The Land of Wolves** | **The Lux Empire**
> Version 1.0.0

---

## Supported Frameworks

| Framework | Status | Detection |
|-----------|--------|-----------|
| LXR Core | Primary | Auto-detected first |
| RSG Core | Primary | Auto-detected second |
| VORP Core | Compatible | Auto-detected third |
| RedEM:RP | Compatible | Manual config |
| QBR Core | Compatible | Manual config |
| QR Core | Compatible | Manual config |
| Standalone | Fallback | Used when no framework detected |

## Auto-Detection

When `Config.Framework = 'auto'` (default), the system checks frameworks in priority order:
1. `lxr-core` — If `GetResourceState('lxr-core') == 'started'`
2. `rsg-core` — If `GetResourceState('rsg-core') == 'started'`
3. `vorp_core` — If `GetResourceState('vorp_core') == 'started'`
4. Standalone fallback

## Manual Override

Set `Config.Framework` to a specific framework name to bypass auto-detection:
```lua
Config.Framework = 'rsg-core'  -- Force RSG Core
```

## Framework Bridge

The file `shared/framework.lua` provides a unified API that normalizes all framework calls. Protected code never calls framework APIs directly.

### Unified API Functions

**Server-side:**
- `Framework.GetPlayer(source)` — Get player object
- `Framework.GetIdentifier(source)` — Get citizen ID
- `Framework.AddItem(source, item, count, metadata)` — Add item to inventory
- `Framework.RemoveItem(source, item, count)` — Remove item from inventory
- `Framework.HasItem(source, item, count)` — Check item exists
- `Framework.AddMoney(source, amount, type)` — Add cash
- `Framework.RemoveMoney(source, amount, type)` — Remove cash
- `Framework.Notify(source, msg, type)` — Send notification

**Client-side:**
- `Framework.GetPlayerData()` — Get local player data
- `Framework.TriggerCallback(name, cb, ...)` — Trigger server callback
- `Framework.Notify(msg, type)` — Show notification

## Inventory

wolves.land uses RSG-based inventory only:
- Player inventory stored in `players` table, `inventory` JSON column
- Compatible with: `lxr-inventory`, `rsg-inventory`, `vorp_inventory`

## Economy

Cash-only economy. No gold currency support.

---

**🐺 wolves.land — The Land of Wolves**
**© 2026 iBoss21 / The Lux Empire — All Rights Reserved**
