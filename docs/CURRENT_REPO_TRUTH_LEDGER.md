# CURRENT REPO TRUTH LEDGER

## Scope
- Date: 2026-04-24
- Task mode: validation-only inspection
- Constraint followed: no gameplay/code changes made in inspected files

## Evidence Collected This Pass
- `git -C what-we-fed status --short`
- `git -C what-we-fed status --short -- autoloads/EventBus.gd scenes/combat/CombatScene.gd scenes/combat/LaneManager.gd scenes/combat/PlayerCombat.gd tools/godot.ps1`
- `git -C what-we-fed diff --stat -- autoloads/EventBus.gd scenes/combat/CombatScene.gd scenes/combat/LaneManager.gd scenes/combat/PlayerCombat.gd tools/godot.ps1`
- `git -C what-we-fed diff -- autoloads/EventBus.gd scenes/combat/CombatScene.gd scenes/combat/LaneManager.gd scenes/combat/PlayerCombat.gd tools/godot.ps1`
- `cmd /c what-we-fed\validate_project.bat`
- File existence/size and line-count checks for:
  - `autoloads/EventBus.gd`
  - `scenes/combat/CombatScene.gd`
  - `scenes/combat/LaneManager.gd`
  - `scenes/combat/PlayerCombat.gd`
  - `tools/godot.ps1`

## Current Working Tree Truth
- Targeted files inspected in this pass:
  - `autoloads/EventBus.gd`
  - `scenes/combat/CombatScene.gd`
  - `scenes/combat/LaneManager.gd`
  - `scenes/combat/PlayerCombat.gd`
  - `tools/godot.ps1`
- Current `HEAD` delta for all five targeted files: none (no local diff output).
- Current modified/untracked files in repo are docs/meta files, not the five targeted gameplay/tooling files.

## Per-File Inspection Summary
| File | What changed (from this pass evidence) | Affected systems | Risk level | Validation state |
|---|---|---|---|---|
| `autoloads/EventBus.gd` | No current working-tree diff vs `HEAD` | Global event routing/state signaling | High impact surface; unverified runtime behavior | Static-inspected only |
| `scenes/combat/CombatScene.gd` | No current working-tree diff vs `HEAD` | Core combat flow, lane/timing readability, attack authority/HUD integration | High (large monolith; 5,774 lines) | Static-inspected only |
| `scenes/combat/LaneManager.gd` | No current working-tree diff vs `HEAD` | Lane mapping/readability/fairness | Medium-High | Static-inspected only |
| `scenes/combat/PlayerCombat.gd` | No current working-tree diff vs `HEAD` | Input buffer/recovery/i-frame behavior | High player-feel sensitivity | Static-inspected only |
| `tools/godot.ps1` | No current working-tree diff vs `HEAD` | Local validation/tooling entry points | Medium (tooling reliability) | Static-inspected only |

## Safe Validation Results (This Pass)
- `validate_project.bat`: completed.
- Import path required headless retry; validation then reported:
  - `VALIDATE OK`
  - `DATA VALIDATION OK`
- Observed warnings:
  - WASAPI device init failure in this environment
  - fallback to dummy audio driver
  - ObjectDB leak warning at exit
- Runtime/manual combat playtest: not run in this pass.

## Confirmed / Unconfirmed
- Confirmed:
  - The five targeted files are currently unchanged in working tree relative to `HEAD`.
  - Static project/data validation commands can complete in current environment.
- Unconfirmed:
  - Any gameplay behavior change claim tied to prior edits (no runtime/manual evidence captured here).
  - Combat feel, lane fairness, timing honesty, or player-response quality under play.

## Residual Risks
- Prior claimed modifications to high-impact combat files are not visible as current uncommitted diffs, so historical change intent/effect cannot be proven by this pass alone.
- `CombatScene.gd` remains large, increasing regression risk when touched.
- Validation logs show environment-specific audio driver warnings; these are not gameplay proof.

## Ledger Rule
- Keep repo truth evidence-backed:
  - direct `git` state/diff evidence, and/or
  - reproducible validation command output, and/or
  - explicit runtime/manual test steps with observed results.
- Do not promote assumptions or design intent to validated behavior.
