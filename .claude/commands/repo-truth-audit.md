# /repo-truth-audit

Run a SYMBIOTE fresh audit to confirm current repo truth before implementing.

## When to use
- Before any implementation task touching fragile systems.
- When CURRENT_PULSE.md may be stale.
- When docs conflict about who owns a system.
- When the last agent report was more than one session ago.

## Fragile systems (always audit before touching)
`scenes/combat/ZoneManager.gd`, `scenes/combat/PlayerCombat.gd`,
`systems/CombatFireDirector.gd`, `systems/SongConductor.gd`,
`autoloads/EventBus.gd`, `autoloads/GameState.gd`, `data/CombatContent.gd`

## Current spatial authority (quick reference)
| Director | File | Owns |
|---|---|---|
| ZoneManager | `scenes/combat/ZoneManager.gd` | Spatial registry, spawn placement |
| CombatFireDirector | `systems/CombatFireDirector.gd` | Fire cycle, striker auth |
| CreatureLocomotionDirector | `systems/CreatureLocomotionDirector.gd` | Enemy movement |
| StatusDirector | `systems/StatusDirector.gd` | Status/affliction rules |
| CombatLifecycleDirector | `systems/CombatLifecycleDirector.gd` | Defeat/lifecycle |
| SovereignDamageCalculator | `systems/SovereignDamageCalculator.gd` | Damage math |
| SongConductor | `systems/SongConductor.gd` | Timing truth |

## Audit prompt template (paste to a fresh agent)

```
You are SYMBIOTE (Scout) for WHAT WE FED.

Task: Fresh repo truth audit — [SCOPE]

Read first (Trinity):
1. docs/ai/SOVEREIGN_CORE.md
2. docs/ai/AI_ARCHITECTURE_LEDGER.md
3. docs/ai/CURRENT_PULSE.md

Files to inspect: [list target files — start with the ones above]
Files allowed to change: NONE. Read only.

Required output:
1. Files inspected (evidence tier stated)
2. Confirmed current truth for [SCOPE]
3. Stale or conflicting docs found
4. Fragile systems involved
5. Recommended next bounded move

End with Auditor's Report + Self-Upgrade Check.
No assumptions. Label everything: confirmed / user-reported / design direction / future idea.
```
