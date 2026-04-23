# AGENTS.md

## Project purpose

This repository is a modular FiveM hunting system for ESX + ox.

## Core rules

- Preserve the modular folder structure.
- Do not collapse logic into giant monolithic `client.lua` or `server.lua` files.
- Keep shared registries in `shared/`, authoritative logic in `server/`, and local rendering/UI in `client/`.
- Prefer metadata-heavy `ox_inventory` items over creating dozens of near-duplicate items.
- Keep event naming under the `dd-hunting:` namespace.
- Prefer server-authoritative validation for money, item rewards, legality, progression, and state changes.
- When uncertain, add structure and comments instead of rewriting architecture.

## Naming conventions

- Server events: `dd-hunting:sv:*`
- Client events: `dd-hunting:cl:*`
- Callbacks: `dd-hunting:*`
- Services live in `server/services/`
- Registries live in `shared/data/`

## Engineering expectations

- Lua 5.4 only.
- Use explicit local helpers for validation and normalization.
- Avoid hidden side effects.
- Keep config-driven values in `shared/config/`.
- Add small comments only where they clarify intent.
- Do not silently change item names, zone keys, or event names.

## What to build next

The next major milestone is persistent player progression and hunter reputation.

Target systems:

- hunter level and total XP
- discipline skill branches
- legal hunter rep
- trapper rep
- trophy rep
- black market rep
- ranger heat
- persistent storage layer
- species mastery and titles

## Done criteria

A change is only done when:

- file structure stays modular
- no existing system names are broken
- configs stay centralized
- code is syntactically valid Lua
- flow is documented well enough for future Codex passes
