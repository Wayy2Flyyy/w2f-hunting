# w2f-hunting

Advanced ESX + ox hunting ecosystem for FiveM.

## Current scaffold

This repository now contains the initial project structure for:

- wildlife spawning and client streaming
- carcass and harvest flow
- kill quality evaluation
- legality checks and tag/license handling
- buyer/vendor market flow
- processing benches
- metadata-heavy ox_inventory items

## Stack

- ESX
- ox_lib
- ox_inventory
- ox_target
- oxmysql

## Next major milestone

Persistent player progression and hunter reputation.

## Repo layout

- `shared/` shared config and data registries
- `server/` authoritative services and events
- `client/` local streaming, targeting, UI, and interaction flow
- `docs/` design notes for Codex continuation

## Notes

This is an actively scaffolded foundation intended to be continued in Codex. Read `AGENTS.md` before making changes.
