# DD Hunting (FiveM ESX + ox)

A modular hunting framework for ESX + ox stack with wildlife simulation, carcass harvesting, processing, markets, and persistent hunter progression.

## Current Systems

- Wildlife spawn + server state sync
- Carcass creation/harvest loop with legality resolution
- Processing benches with metadata-aware outputs
- Buyer/vendor market loops
- **Persistent progression + reputation + mastery milestone (new)**

## Progression & Reputation (Milestone Complete)

### Persistent data model
The progression layer now persists normalized records using oxmysql:

- `dd_hunting_profiles`
- `dd_hunting_skill_branches`
- `dd_hunting_species_mastery`
- `dd_hunting_unlocks`
- `dd_hunting_reputation`
- `dd_hunting_ranger_crimes`

Schema migration is available at `sql/dd_hunting_progression.sql` and is also auto-created on resource start.

### Hunter progression
- Hunter level + XP curve
- Unspent skill points
- Skill branches:
  - tracker
  - marksman
  - butcher
  - survivalist
  - trophy_hunter
  - poacher

### Reputation bars
- legal hunter rep
- trapper rep
- trophy rep
- black market rep
- ranger heat (plus crime log table)

### Species mastery
Tracked per species:
- kills
- clean kills
- best trophy
- best weight
- variants found
- mastery XP/rank

### Server-authoritative gain hooks
Progression updates are wired into:
- carcass harvesting (quality/legality/rare/trophy)
- market sales (legal vs illegal, bulk, trophy lines)
- processing benches (including illegal/trophy benches)

### Unlock foundation hooks
Unlock flags are persisted and evaluated from:
- level thresholds
- reputation thresholds

This lays groundwork for:
- advanced contract tiers
- better multipliers
- gated high-tier gameplay loops

### Minimal UI hooks
- `/huntprogress` quick status summary
- `/huntskills` ox_lib context overview:
  - level + title
  - skill points + branch ranks
  - reputation values
  - species mastery snapshot

## Next milestone suggestion
Build **dynamic contract and ranger response systems** using current unlock + heat foundations:
- tiered contracts driven by unlock flags and species mastery
- ranger patrol/event pressure scaling with heat and crime history
- reward multipliers using branch specialization + reputation bands
- optional lodge/trophy showroom progression tied to trophy mastery
