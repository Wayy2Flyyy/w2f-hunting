# DD Hunting — Code review report

## Framework abstraction

### Current framework support status

| Target (`Config.Framework.Target`) | Resource | Status |
|--------------------------------------|----------|--------|
| `qbox` (default) | `qbx_core` | Primary path: `server/bridge/qbox.lua` uses documented exports (`GetPlayer`, `AddMoney`, `RemoveMoney`, `Notify`). |
| `qbcore` | `qb-core` | Secondary compatibility: `server/bridge/qbcore.lua` uses `GetCoreObject()` and player `Functions` for money; notifications use `ox_lib` for parity with existing ESX bridge behavior. |
| `esx` | `es_extended` | Supported: `server/bridge/esx.lua` unchanged in behavior; selected when `Target = 'esx'`. |

All server services and event handlers call **`Bridge.Framework`** for `GetIdentifier`, `AddMoney`, `RemoveMoney`, and `ShowNotification`. Inventory remains **`Bridge.Inventory`** (ox_inventory only; no qb-inventory).

The dispatcher lives in **`server/bridge/framework.lua`**: it reads `Config.Framework.Target`, resolves the implementation table (`Bridge.Qbox`, `Bridge.QBCore`, or `Bridge.ESX`), and forwards calls. Framework-specific logic is not duplicated across service files.

### What was changed for Qbox primary support

- Default `Config.Framework.Target` / `Primary` set to **`qbox`** in `shared/config/framework.lua`.
- Added **`server/bridge/qbox.lua`** (qbx_core) and **`server/bridge/qbcore.lua`** (qb-core), plus **`server/bridge/framework.lua`** as the single entry point for services.
- Replaced direct **`Bridge.ESX`** usage in services and server events with **`Bridge.Framework`**.
- **`fxmanifest.lua`**: removed `es_extended` from `dependencies`; documented conditional framework starts in comments; load order loads implementation bridges before `framework.lua`.
- **`server/main.lua`**: initializes **`Bridge.Framework.Init()`** instead of `Bridge.ESX.Init()`; registers **`QBCore:Server:OnPlayerLoaded`** for Qbox/QBCore (in addition to **`esx:playerLoaded`** for ESX), each gated by `Config.Framework.Target`.
- Renamed the ox_target config block from **`Config.Framework.Target`** (table) to **`Config.Framework.Targeting`** to avoid clashing with the string **`Config.Framework.Target`** (`qbox` | `qbcore` | `esx`). Client code already calls `exports.ox_target` directly; nothing in-repo read the old nested `Target` table.

### QBCore compatibility status

- Implemented: `GetPlayer`, `GetIdentifier` (citizenid), `GetName`, `GetJob` (normalized table), `AddMoney` / `RemoveMoney` with account aliases (`money` → `cash`, `black_money` → `crypto`), `ShowNotification` via ox_lib.
- **Note:** `black_money` is mapped to the **`crypto`** money type on QBCore/Qbox (qbx supports `cash` | `bank` | `crypto` only). Servers that treat dirty cash as items only should adjust config/payout accounts or extend the bridge.

### ESX compatibility status

- **Unchanged API** on `Bridge.ESX`; still used when `Target == 'esx'`.
- Identifiers remain ESX **`identifier`** strings; money paths unchanged (`money`, `black_money`, accounts).

### Framework-specific TODOs

1. **Illegal payouts:** Confirm whether your Qbox/QBCore economy uses `crypto` for `black_money` or item-based dirty money; adjust `resolveMoneyType` in `qbox.lua` / `qbcore.lua` if you use a custom account or item-only flow.
2. **Client bridge:** No client-side framework calls existed in this resource; a `client/bridge/` layer was not added. Add one if client code later needs framework-specific helpers.
3. **Identifier migration:** Switching from ESX `identifier` to Qbox `citizenid` changes persistence keys in `dd_hunting_*` tables; migrating existing player data is a separate DBA task.

### Required `server.cfg` examples

**Qbox (default)**

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure qbx_core
ensure dd-hunting
```

Set in resource config: `Config.Framework.Target = 'qbox'`.

**QBCore**

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure qb-core
ensure dd-hunting
```

Set: `Config.Framework.Target = 'qbcore'`.

**ESX**

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure es_extended
ensure dd-hunting
```

Set: `Config.Framework.Target = 'esx'`.

Always start **oxmysql**, **ox_lib**, and **ox_inventory** before **dd-hunting**. Start the chosen framework core **before** **dd-hunting** so `Init()` can resolve the player object.

---

## Inventory

**ox_inventory** remains the only inventory integration (`server/bridge/ox_inventory.lua`). No qb-inventory dependency was added.
