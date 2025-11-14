# Rex Ranch

Rex Ranch is an RSG-Framework resource for RedM (Red Dead Redemption 2) that provides full ranch management: animals, breeding, production, herding, staff, storage, and buy/sell systems.

- **Framework:** RSG-Core
- **Dependencies:** `ox_lib`, `oxmysql`
- **Supported:** RedM on Lua 5.4

See `DOCUMENTATION.md` for full installation, configuration, exports, events, and troubleshooting.

Quick start:

- Add to `server.cfg`:
  ```
  ensure rsg-core
  ensure ox_lib
  ensure rex-ranch
  ```
- Import DB: `mysql < installation/rex-ranch.sql`
- Add shared items/jobs from `installation/shared_items.lua` and `installation/shared_jobs.lua`
- Configure options in `shared/config.lua` before first run

For advanced usage and export examples, open `DOCUMENTATION.md`.