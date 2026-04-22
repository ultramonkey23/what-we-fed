# CORE SYSTEMS & GROWTH — LOCAL INSTRUCTIONS

## 5-Layer Canon Compliance
All system design must adhere to the **5-Layer Canon Model**:
1. **Layer 1 (Locked Core)**: DNA economy, Bond vs Eat tension, and Reward Ecology lanes.
2. **Layer 2 (Live Build Truth)**: EventBus signals and current `GameState` schema.
3. **Layer 3 (Evolving Spine)**: UI styling, growth curves, and non-core reward values.

## System Philosophy: Management-Rich
Systems should be decoupled and modular, favoring composition over deep inheritance.
- **Management-Rich**: While combat is clean, between-level and pre-run screens must be information-dense and strategic. Provide detailed comparisons for loot, grafts, artifacts, and collars.
- **Comprehension > Urgency**: Outside active combat, the player should have all the data needed to make complex build decisions.
- **Display Law**: **Combat HUD = Urgency** (live action) | **Management Screens = Comprehension** (detailed strategy).

## Reward Ecology: Lane Separation
To prevent "stat sludge," all progression systems must strictly adhere to distinct Reward Ecology lanes:
1. **Loot / Gear**: Shapes the hunter (Biological trophies, organs, grafts).
2. **Artifacts / Relics**: Shape the run (Rare, transformative, synergy-rich).
3. **DNA**: The species relationship economy earned from actual kills.
4. **Bond / Eat**: The core identity split (relational vs predatory).
5. **Collars**: Shape bonded creature support behavior.
6. **Tendencies**: Behavior-shaped growth spine.

## Growth & Economy
- **Behavior-Shaped Growth**: Growth should reflect how the player plays (predation vs bonding), not just generic level-up choices.
- **DNA Integrity**: DNA is the currency of evolution. Protect the predation economy.
- **Support Logic**: Bonded creatures provide "Support." This should be readable and reliable, not random noise.

## State Management
- **Persistence**: `GameState.gd` is the only place for long-term data (Roster, DNA totals, Region unlocks).
- **Run Local**: `RunGrowth.gd` and `systems/RunStats.gd` own the current run's state.
- **Cleanup**: Ensure run-local state is properly reset when a run ends or a new one begins.

## Presentation Logic
- **UI Style**: Use `systems/UIStyle.gd` for consistent colors, fonts, and "teeth."
- **HUD Performance**: Reward readouts and combo meters must be responsive but non-distracting.
- **Modular HUD**: Keep presentation logic (`CombatPresentationRuntime.gd`) separate from combat mechanics.

## Implementation Rules
- **Signals**: Always prefer `EventBus.emit_signal()` over direct node references across systems.
- **Growth Effects**: Add new growth logic to `systems/RunGrowth.gd` and define data in `data/RunGrowthContent.gd`.
- **Meter Logic**: `systems/CombatMeter.gd` owns Combo/Ultimate/Stamina. Do not fragment this logic.

## Validation Checklist (Systems-Specific)
- [ ] Are signals disconnected properly at exit?
- [ ] Does `GameState` save/load correctly?
- [ ] Does the "Bond vs Eat" tension remain balanced?
- [ ] Does every new reward fit a specific Reward Ecology lane?
- [ ] Is "Management-Rich" detail preserved in UI screens?
- [ ] Did you verify with `smoke_project.bat`?
