# DD Hunting (FiveM ESX + ox)

A modular hunting framework for ESX + ox stack with wildlife simulation, carcass harvesting, processing, markets, persistent progression, contracts, and enforcement risk loops.

## Core Systems

- Wildlife spawn + server state sync
- Carcass creation/harvest loop with legality resolution
- Processing benches with metadata-aware outputs
- Buyer/vendor market loops
- Persistent progression + reputation + species mastery
- Contract boards (legal and illegal)
- Ranger enforcement + evidence foundations

---

## Progression Foundation (Completed)

- Persistent hunter level / XP / skill branches
- Reputation bars (legal, trapper, trophy, black market, ranger heat)
- Species mastery tracking
- Unlock/title foundation

---

## Contract + Enforcement Milestone (Completed)

### Contract system
Implemented modular contract lifecycle with:

- contract boards:
  - ranger
  - trapper
  - trophy
  - black_market
- contract types:
  - legal_hunt
  - trapper_material
  - trophy_collector
  - black_market
  - predator_control
- weighted tier generation (`t1..t4`)
- metadata-driven validation using existing metadata fields:
  - species
  - qualityScore
  - freshness
  - trophyScore
  - variant
  - legal
  - partType
  - quantity
- active contract limit per player
- accept / abandon / turn-in flow
- expiration + failure handling
- persistence for active/completed/failed contracts

### Enforcement system
Server-side ranger/wildlife enforcement logic:

- violation tracking:
  - protected species
  - no license
  - no tag
  - restricted zone
  - illegal hours
  - black market activity
  - illegal bait / forged-tag style events
- alert scoring + anti-spam dampening
- inspection chance calculation
- seizure hook for contraband inventory
- penalty/fine hook foundation
- enforcement audit log persistence

### Evidence foundation
First-pass evidence trail implemented:

- evidence records persisted (`dd_hunting_evidence`)
- evidence creation hooks for illegal flows and contract turn-ins
- seizure-ready inventory removal utility
- logs suitable for future ranger case/audit UI

### Integration points
- harvest flow -> progression + enforcement violation hooks
- market flow -> black market risk + evidence + inspection chance
- processing flow -> illegal bench enforcement hooks
- contract completion -> payout + XP + rep + optional heat escalation

---

## Persistence Schema

All via `sql/dd_hunting_progression.sql` (also auto-created at runtime):

- `dd_hunting_profiles`
- `dd_hunting_skill_branches`
- `dd_hunting_species_mastery`
- `dd_hunting_unlocks`
- `dd_hunting_reputation`
- `dd_hunting_ranger_crimes`
- `dd_hunting_active_contracts`
- `dd_hunting_contract_history`
- `dd_hunting_evidence`
- `dd_hunting_enforcement_logs`

---

## Minimal UI Commands

- `/huntprogress` → quick progression summary
- `/huntskills` → progression, rep, mastery context
- `/huntcontracts` → contract board browser
- `/huntactivecontracts` → active contract turn-in/abandon
- `/huntrisk` → enforcement/heat quick status

---

## Intentionally Stubbed (for next phase)

- No ranger NPC combat AI yet (server-only logic/hooks in place)
- No world patrol routing yet
- No full legal court/jailing pipeline yet
- No rich NUI board frontend yet (ox_lib context only)

---

## Next Milestone Suggestion

Build **dynamic ranger operations + advanced contract chains**:

- world-level ranger dispatch/patrol events from enforcement alerts
- multi-step contract chains with prerequisites/unlock progression
- smarter economy modifiers based on contract reliability and evidence history
- ranger evidence board / case management UI
- optional jail/seizure processing pipeline with ESX job integration
