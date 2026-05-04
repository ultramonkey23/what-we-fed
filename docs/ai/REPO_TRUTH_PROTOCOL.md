# REPO TRUTH PROTOCOL
Guidelines for maintaining the integrity of the project's implemented reality.

## 1. THE STALE TRUTH RULE
Repo truth is considered "Stale" if:
- A major implementation occurred after the latest agent report.
- Multiple reports conflict on the same system.
- The user is unsure what changed.
- Runtime behavior differs from documentation.
- The task touches **Fragile Systems** (see SOVEREIGN_CORE.md).

**If Stale**: Do not implement. Request or generate a fresh repo audit.

## 2. THE LEDGER DISCIPLINE
- All significant architectural changes must be appended to `docs/ai/archive_legacy/truth_history/CURRENT_REPO_TRUTH_LEDGER.md` (archived path; historical ledger, not default active context — prefer updating `docs/ai/CURRENT_PULSE.md` for compact current truth when appropriate).
- Ledger entries must be grounded in **Evidence Tier 2 or 3** (Static or Runtime).
- Distinguish clearly between "Static-Only" and "Runtime-Verified" implementation.

## 3. PROTECTED SYSTEMS LIST
High-risk files requiring extra validation and care:
- `project.godot`
- `scenes/combat/CombatScene.gd`
- `scenes/combat/PlayerCombat.gd`
- `systems/SongConductor.gd`
- `systems/LaneManager.gd`
- `autoloads/GameState.gd`
- `data/CombatContent.gd`

## 4. ASSUMPTION-BUSTING
Before mutation, agents must:
1. Grep for existing implementations.
2. Verify signal emissions AND connections.
3. Check for `@onready` or `%UniqueName` validity.
4. Confirm if a system is "Locked Core" or "Older Canon."

## 5. NO PARALLEL SYSTEMS
Do not introduce new control planes or parallel doctrine. If a system exists, patch it. If it's redundant, extract/merge it into the Sovereign Core.
