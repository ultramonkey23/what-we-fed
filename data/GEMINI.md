# CONTENT & DATA — LOCAL INSTRUCTIONS

## Data Philosophy
Data should be structured, authored, and predictable. Avoid "data sludge" (duplicate or vague entries).

## Song Maps
- **Timing Integrity**: Song maps in `data/song_maps/` must align perfectly with the audio assets.
- **Phase Logic**: `RegionSongContent.gd` defines how a song escalates. Respect the phases.
- **Conductor Link**: All song data must be digestible by `SongConductor.gd`.

## Content Ownership
- **Combat Content**: `data/CombatContent.gd` owns creature stats, encounter groups, and spawns.
- **Route Content**: `data/RouteContent.gd` owns region connections and difficulty scaling.
- **Reward Content**: `data/PerformanceRewardContent.gd` defines what the player gets for their skill.

## Implementation Rules
- **Adding Content**: Follow the pattern in existing `.gd` files. Use `static func` where appropriate for data definitions.
- **Naming**: Use the "Black Signal" naming convention—dark, evocative, and consistent (e.g., `ashclaw`, `bond_remnant`).
- **Paths**: Use `res://` absolute paths for assets.

## Validation Checklist (Data-Specific)
- [ ] Does `validate_project.bat` pass (imports and parse errors)?
- [ ] Is the new data correctly routed through `EventBus` or the relevant Manager?
- [ ] Are there any duplicate IDs or overlapping song timings?
- [ ] Does the content fit the "Start Weak, Become Feared" progression?

## Anti-Drift: Data
- **NO** generic "Enemy 1", "Enemy 2" naming.
- **NO** placeholder values that aren't clearly marked for removal.
- **NO** breaking the authored feel with procedurally-generated nonsense that lacks soul.
