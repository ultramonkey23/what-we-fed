# VALIDATION STANDARD — WHAT WE FED

Every code change MUST be validated. A task is incomplete until this report is generated or confirmed in spirit.

## 🟢 Runtime-Verified (Mandatory for Implementation)
- [ ] **Smoke Test**: `smoke_project.bat` passes (zero parse errors).
- [ ] **Launch**: Game boots to the title/lair without immediate crash.
- [ ] **Functional Proof**: [Describe the exact scenario, e.g., "Parried a projectile in Lane 1, combo increased"].

## 🟡 Static/Logic Verified (Mandatory for Research/Fixes)
- [ ] **Type Check**: Every modified signature and variable is explicitly typed.
- [ ] **Signal Tracing**: `EventBus` signals are emitted AND connected correctly.
- [ ] **Null-Safety**: All `@onready` and `%UniqueName` nodes are checked or guaranteed by wiring.

## 🔴 Still Unverified (State Honestly)
- [ ] **Feel/Timing**: (AI cannot verify rhythm honesty).
- [ ] **Visual Clarity**: (AI cannot verify HUD clutter under pressure).
- [ ] **Multi-System Side Effects**: (e.g., "Fixing a bullet in CombatScene might affect RewardScreen").

---

## Identity-Lock Check
- **Lane Truth**: Are lanes 0, 1, 2 still the primary focus?
- **Timing Truth**: Does the change respect `SongConductor`?
- **No-Pause In Active Combat**: Is the level’s realtime lane combat uninterrupted (no pausing the song mid-fight)? Between-level menus are excluded from this check.

## Post-Edit Summary
- **Fix/Goal**: [The core problem solved].
- **Player Impact**: [What the player sees/feels].
- **Risks**: [Potential regressions].