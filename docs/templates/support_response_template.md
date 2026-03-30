# Support Response Templates

## Resource Won't Start
Hi! Please check:
1. The folder is named exactly `lxr-ranch`
2. Your framework starts before lxr-ranch in server.cfg
3. ox_lib and oxmysql are running
4. Check server console for error messages

## Database Issues
Please ensure you've imported `installation/lxr-ranch.sql` into your database. If upgrading from rex-ranch, see the migration guide in docs/INSTALL.md.

## Items Not Working
Add the items from `installation/shared_items.lua` to your framework's shared items file, then restart your server.

## Jobs Not Working
Add the jobs from `installation/shared_jobs.lua` to your framework's shared jobs file. Each ranch needs a matching job with grades 0-3.

## General Debug
Enable debug mode: Set `Config.Debug = true` in config.lua, restart, and share the console output with us.

## Contact
- Discord: https://discord.gg/CrKcWdfd3A
- Website: https://www.wolves.land
