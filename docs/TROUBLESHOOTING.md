# 🐺 LXR-RANCH — Troubleshooting

> **The Land of Wolves** | **The Lux Empire**
> Version 1.0.0

---

## Common Issues

### Resource won't start — "Resource name mismatch"
**Cause:** The resource folder is not named `lxr-ranch`.
**Fix:** Rename the folder to exactly `lxr-ranch`.

### Animals don't spawn
**Cause:** Database table missing or empty.
**Fix:** Import `installation/lxr-ranch.sql` into your database.

### "Framework not detected" error
**Cause:** Your framework resource isn't starting before lxr-ranch.
**Fix:** Ensure your framework (rsg-core, lxr-core, etc.) starts before lxr-ranch in server.cfg.

### Inventory items not showing
**Cause:** Items not added to framework shared items.
**Fix:** Add items from `installation/shared_items.lua` to your framework's shared items.

### Ranch jobs not working
**Cause:** Jobs not configured in framework.
**Fix:** Add jobs from `installation/shared_jobs.lua` to your framework's shared jobs.

### Water bucket won't fill
**Cause:** Player not near a water source prop.
**Fix:** Check `Config.WaterProps` contains the correct model hashes for your map.

### Breeding not working
**Cause:** Animals don't meet requirements (age, health, hunger, thirst).
**Fix:** Check `Config.Breeding` requirements. Set `Config.Debug = true` for detailed logs.

### Tax system not running
**Cause:** `lxr_ranches` table empty or `Config.Taxation.enabled = false`.
**Fix:** Ensure ranches exist in the database and taxation is enabled in config.

### NUI dashboard won't open
**Cause:** Player job grade below minimum.
**Fix:** Managers (grade 2+) can use `/ranchdashboard`. Check staff grade.

### Performance issues with many animals
**Cause:** Too many animals spawned simultaneously.
**Fix:** Reduce `Config.Performance.maxNearbyEntities` and increase LOD distances.

## Debug Mode

Enable debug mode in config.lua:
```lua
Config.Debug = true
```

This prints detailed logs to the server console for all systems.

---

**🐺 wolves.land — The Land of Wolves**
**© 2026 iBoss21 / The Lux Empire — All Rights Reserved**
