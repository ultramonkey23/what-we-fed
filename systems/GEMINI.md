# CORE SYSTEMS & GROWTH — LOCAL INSTRUCTIONS

## System Philosophy
Systems should be decoupled and modular. Use `EventBus.gd` to communicate across boundaries. Favor composition over deep inheritance.

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
- [ ] Is there any "Stat Sludge" (meaningless numbers)? If so, remove/consolidate.
- [ ] Did you verify with `smoke_project.bat` for script/autoload errors?
