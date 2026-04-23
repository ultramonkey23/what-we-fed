# CONTENT & DATA — LOCAL INSTRUCTIONS

## THE AUTHORITY HIERARCHY
Data structures must adhere to the project's authority hierarchy:
1. **User / Creator Intent**: Highest authority.
2. **Current Repo Truth (Layer 2)**: Valid resource paths and active UID mappings.
3. **Older Canon / Source Docs (Layer 1)**: Combat identity, Reward Ecology lanes, and DNA economy structure. Useful memory and guidance.

## Data Philosophy: Management-Rich
Data should be structured, authored, and predictable. Avoid "data sludge" (duplicate or vague entries).
- **Management-Rich Content**: Data must support high-detail comprehension in between-level and pre-run management screens. Provide clear descriptors, tooltips, and comparative stats for all items.
- **Display Law**: **Combat HUD = Urgency** (live action) | **Management Screens = Comprehension** (detailed data).
- **Reward Ecology Lane Integrity**: Every data entry for a reward or progression item must explicitly belong to one of the six canon lanes (Loot, Artifact, DNA, Bond/Eat, Collar, Tendency).

## Song Maps
- **Timing Integrity**: Song maps in `data/song_maps/` must align perfectly with the audio assets.
- **Phase Logic**: `RegionSongContent.gd` defines how a song escalates. Respect the phases.
- **Conductor Link**: All song data must be digestible by `SongConductor.gd`.

## Content Ownership
- **Combat Content**: `data/CombatContent.gd` owns creature stats, encounter groups, and spawns.
- **Route Content**: `data/RouteContent.gd` owns region connections and difficulty scaling.
- **Reward Content**: `data/PerformanceRewardContent.gd` defines skill-based rewards within the proper lanes.

## Implementation Rules
- **Adding Content**: Follow the pattern in existing `.gd` files. Use `static func` where appropriate for data definitions.
- **Naming**: Use the "Black Signal" naming convention—dark, evocative, and consistent (e.g., `ashclaw`, `bond_remnant`).
- **Paths**: Use `res://` absolute paths for assets.

## Validation Checklist (Data-Specific)
- [ ] Does `validate_project.bat` pass (imports and parse errors)?
- [ ] Is every new data item assigned to a Reward Ecology lane?
- [ ] Are descriptors and stats detailed enough for "Management-Rich" comprehension?
- [ ] Are there any duplicate IDs or overlapping song timings?
- [ ] Does the content fit the "Start Weak, Become Feared" progression?

## Anti-Drift: Data
- **NO** generic "Enemy 1", "Enemy 2" naming.
- **NO** "Reward Sludge" (overlapping items that don't fit a clear lane).
- **NO** placeholder values that aren't clearly marked for removal.
- **NO** breaking the authored feel with procedurally-generated nonsense.
