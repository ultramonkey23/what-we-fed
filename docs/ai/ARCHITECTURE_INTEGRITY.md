# ARCHITECTURE INTEGRITY — THE PULSE (v2.2)

## THE AUTHORITY HIERARCHY
1. **User / Creator Intent**: Highest authority.
2. **Current Repo Truth (Layer 2)**: The active code, signals, and scene trees.
3. **Older Canon (Layer 1)**: Documentation and original specs.

## CORE INTEGRITY FLOW
To maintain "The Unified Pulse," systems must adhere to this flow:

### 1. Data Definition (Static)
- **Files**: `data/*.gd`
- **Rule**: Pure data. No state. Use `static` functions for lookups.
- **Integrity Check**: Data must fit one of the six Reward Ecology lanes.

### 2. State Persistence (Layer 2)
- **Files**: `autoloads/GameState.gd`
- **Rule**: The single source of truth for long-term progression (DNA, Roster, Unlocks).
- **Communication**: Emits signals via `EventBus` when state changes.

### 3. Runtime Logic (Layer 3)
- **Files**: `systems/*.gd`, `scenes/*.gd`
- **Rule**: Short-term state (Run-local). Resets on run end.
- **Integration**: Listens to `EventBus`, reads from `GameState` at startup, writes to `GameState` at milestones.

## SIGNAL ETIQUETTE
- **EventBus** is the heartbeat. 
- Avoid direct node-to-node references across major system boundaries.
- **Preferred Pattern**: `Action -> System Logic -> EventBus Signal -> UI/Presentation`.

## REWARD ECOLOGY LANES
Every progression item or creature must explicitly belong to:
1. **Loot/Gear**: Biological trophies/grafts.
2. **Artifacts**: Run-transformative synergies.
3. **DNA**: Species relationship economy.
4. **Bond/Eat**: Core identity split.
5. **Collars**: Bonded creature support behavior.
6. **Tendencies**: Behavior-shaped growth spine.

## VALIDATION COMMANDMENTS
1. Never claim gameplay improvement without playtest/smoke evidence.
2. Always verify signal disconnects at exit.
3. Maintain "Management-Rich" detail in all non-combat screens.
