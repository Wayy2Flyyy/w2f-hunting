# DD Hunting — Code Review Report

## Framework Support

### Current status

| Framework | Role | Bridge file | Default |
|-----------|------|-------------|---------|
| **Qbox / QBX** | Primary target | `server/bridge/qbox.lua` | Yes (`Config.Framework.Target = 'qbox'`) |
| **QBCore** | Secondary compatibility | `server/bridge/qbcore.lua` | No |
| **ESX** | Supported compatibility | `server/bridge/esx.lua` | No |

Server services and events call **generic** `Bridge.Framework.*` APIs. Framework-specific logic lives only in bridge files plus the dispatcher in `server/bridge/framework.lua`.

### What changed for Qbox-primary support

- **`shared/config/framework.lua`**
  - `Config.Framework.Target` / `Primary` default to `qbox`.
  - `UseOxInventory = true` documents inventory priority.
  - Hard `es_extended` coupling removed from config shape (`Name`, `SharedObjectExport` removed).
  - `InteractionTarget` renamed from the old nested `Target` table (ox_target settings) to avoid clashing with framework `Target`.
  - Default payout accounts set to Qbox-friendly `cash` / `black_money`.

- **New bridges**
  - `server/bridge/qbox.lua` — `qbx_core` player, citizenid, job, money, notifications.
  - `server/bridge/qbcore.lua` — `qb-core` compatibility path.
  - `server/bridge/framework.lua` — config-driven selection and shared API surface.

- **Manifest (`fxmanifest.lua`)**
  - Hard dependencies limited to `ox_lib`, `oxmysql`, `ox_inventory`.
  - `es_extended` removed from `dependencies`.
  - Bridge load order: qbox → qbcore → esx → framework dispatcher.

- **Server boot (`server/main.lua`)**
  - `Bridge.Framework.Init()` replaces `Bridge.ESX.Init()`.
  - `Bridge.Framework.RegisterPlayerLoaded()` handles ESX and QBCore/Qbox player-loaded events.

- **Services / events**
  - All prior `Bridge.ESX.*` usage migrated to `Bridge.Framework.*` (market, processing, contracts, progression, enforcement, evidence, and event handlers).

### QBCore compatibility status

- **Working (bridge-level):** `GetPlayer`, `GetIdentifier` (citizenid/license), `GetName`, `GetJob`, `AddMoney`, `RemoveMoney`, `ShowNotification`.
- **Account alias:** `money` maps to `cash` in the QBCore bridge (same as Qbox).
- **Player loaded:** `QBCore:Server:PlayerLoaded` and `QBCore:Server:OnPlayerLoaded` registered via framework dispatcher.
- **Inventory:** unchanged — all frameworks use `server/bridge/ox_inventory.lua`.
- **Activation:** set `Config.Framework.Target = 'qbcore'` and ensure `qb-core` starts before `dd-hunting`.

### ESX compatibility status

- **Working (bridge-level):** existing ESX bridge retained; same API surface as Qbox/QBCore bridges.
- **Notifications:** still routed through `ox_lib` by default (config `Notifications.Type = 'ox_lib'`).
- **Account alias:** `cash` maps to ESX `money` in Add/RemoveMoney.
- **Player loaded:** `esx:playerLoaded` still supported via framework dispatcher.
- **Activation:** set `Config.Framework.Target = 'esx'` and ensure `es_extended` starts before `dd-hunting`.
- **Config note for ESX servers:** set `Config.Framework.Accounts.LegalPayout = 'money'` (and keep `IllegalPayout = 'black_money'` if used).

### Framework-specific TODOs

- [ ] Optional client bridge layer if client-side framework calls are added later (currently client code has no direct framework usage).
- [ ] Admin permission checks still use config group names; wire `Bridge.Framework` group/job helpers if admin gates expand.
- [ ] Per-server money type validation (some QBCore/Qbox servers disable `black_money` as an account — may need item-based dirty money).
- [ ] Vendor/bench config still defaults some accounts to `'money'` in services; bridge normalizes to `cash` on Qbox/QBCore — consider centralizing on `Config.Framework.Accounts` in a follow-up.
- [ ] Rich ESX notification mode when `Notifications.Type = 'esx'` (bridge currently always uses ox_lib server-side).

### Required `server.cfg` examples

**Qbox (default / recommended)**

```cfg
ensure ox_lib
ensure oxmysql
ensure ox_inventory
ensure qbx_core
ensure dd-hunting

# shared/config/framework.lua
# Config.Framework.Target = 'qbox'
```

**QBCore (compatibility)**

```cfg
ensure ox_lib
ensure oxmysql
ensure ox_inventory
ensure qb-core
ensure dd-hunting

# shared/config/framework.lua
# Config.Framework.Target = 'qbcore'
```

**ESX (compatibility)**

```cfg
ensure ox_lib
ensure oxmysql
ensure ox_inventory
ensure es_extended
ensure dd-hunting

# shared/config/framework.lua
# Config.Framework.Target = 'esx'
# Config.Framework.Accounts.LegalPayout = 'money'
```

---

## Inventory

- **Primary:** `ox_inventory` via `server/bridge/ox_inventory.lua` (unchanged).
- **qb-inventory:** not added; not required for any framework target.

---

## Bridge API (server)

All frameworks implement:

- `GetPlayer(source)`
- `GetIdentifier(source)`
- `GetName(source)`
- `GetJob(source)`
- `AddMoney(source, account, amount, reason)`
- `RemoveMoney(source, account, amount, reason)`
- `ShowNotification(source, message, notifyType)`

Access via `DDHunting.Server.Bridge.Framework.*` after `Bridge.Framework.Init()`.
