# PROTECTED SYSTEMS REGISTRY

Use this registry before changing fragile files or systems.
This file defines lightweight guardrails and validation expectations; it does not replace existing doctrine.

## Contracts
| File/System | Why Protected | Change Contract | Validation Expectation |
|---|---|---|---|
| `project.godot` | Global project wiring, autoload registration, input maps, plugin/runtime config. Small edits can break startup or core wiring. | Do not edit unless task explicitly requires it. Make the smallest possible scoped change. No opportunistic cleanup. | Minimum Level 3 runtime validation (`validate_project.bat` or project boot). Report exact keys changed. |
| `*.tscn` scene files | Scene graph/wiring changes can silently break node paths, signals, and exported references. | Prefer script-only changes first. If scene edit is required, keep to one bounded scene and one intent. | Minimum Level 3 runtime check of affected scene path and interaction. |
| `scenes/combat/CombatScene.gd` | Core combat orchestration and timing-critical flow; very high blast radius. | Require fresh repo truth and explicit bounded scope before edits. One change at a time. | Level 3+ runtime validation of combat loop; include unverified feel risks if no playtest. |
| `scenes/combat/PlayerCombat.gd` | Player input/combat behavior integrity; regressions directly affect combat honesty. | Keep changes local and reversible. Preserve timing/input contracts and existing signal flow. | Level 3+ runtime validation of player actions and timing windows. |
| `scenes/combat/LaneManager.gd` | Cardinal lane readability and threat-direction contracts are identity-critical. | Do not alter lane semantics without explicit approval. Favor minimal targeted fixes. | Level 3+ runtime validation for lane threat/readability behavior. |
| `autoloads/EventBus.gd` | Cross-system signaling hub; contract changes can cause silent systemic breakage. | No signal renames/removals without explicit migration plan. Preserve backward compatibility where possible. | Static signal-trace check plus Level 3 runtime exercise of affected emits/listeners. |
| `autoloads/GameState.gd` | Persistent run/world state authority; corruption impacts broad gameplay systems. | Avoid schema/field drift unless explicitly requested. Keep save/state contract stable. | Level 3 runtime smoke + targeted state transition checks. |
| `systems/SongConductor.gd` | Timing authority for beat-locked systems; regressions harm rhythm truth. | Preserve timing source-of-truth behavior and public timing interfaces. | Level 3 runtime validation in combat timing scenarios. |
| `data/CombatContent.gd` | Core combat content/data truth; mistakes propagate to many combat behaviors. | Keep data changes explicit and bounded. Do not mix unrelated balancing/content shifts. | Run `validate_data.bat` and any relevant runtime checks for touched content paths. |

## Escalation
- If task touches any protected file and repo truth is stale, load:
  - `docs/ai/AI_CONTROL_PLANE.md`
  - `docs/ai/SYSTEM_KERNEL.md`
  - `docs/ai/AGENT_ROUTING_MATRIX.md`
- Prefer explicit "Static-Only" labeling when runtime was not performed.

## Protected Edit Preflight (Copy/Paste)
Use this block before any protected-system edit:

```md
PROTECTED EDIT PREFLIGHT
- Protected file/system: [path/system]
- Why protected: [short reason from registry]
- Existing owner/pattern: [autoload owner, scene owner, signal/timing/state pattern to preserve]
- Intended files to inspect: [paths]
- Intended files to change: [paths]
- Files/systems not touching: [paths/systems]
- Validation expectation: [Level 2 static | Level 3 runtime | Level 4 playtest + commands]
- Stop condition / escalation trigger: [stale truth, cross-system blast radius, unclear owner, or contract conflict -> stop and escalate via AI_CONTROL_PLANE + SYSTEM_KERNEL]
```
