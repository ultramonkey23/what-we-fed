# What We Fed Repo Workflow

Practical setup and validation commands for this repo.

For startup context, read first:
- `docs/ai/PROJECT_KERNEL.md`
- `docs/ai/CONTEXT_EXPANSION_MAP.md`
- `docs/ai/VIBE_CODING_QUICKSTART.md`

Truth layering reminder:
- Live build docs (`docs/GAME_SPINE.md`, `docs/NEXT_PHASE_PLAN.md`) outrank stale speculative wording.
- Final scope and deferred docs are deep reference, not default implementation orders.
- **Combat-clean, management-rich**: No menu sludge (repeated interruption) during active in-level combat; rich management is encouraged between levels and before runs.
- **Display Law**: **Combat HUD = Urgency** (live action) | **Management Screens = Comprehension** (between-level strategy).

## Repo-Local Godot Commands

Run these from repo root:

```bat
run_project.bat
debug_harness.bat
smoke_project.bat
validate_project.bat
editor_project.bat
resolve_godot.bat
add_tools_to_path.bat
```

What they do:
- `run_project.bat`: launch the game from terminal
- `debug_harness.bat`: boot the development-facing combat harness scene
- `smoke_project.bat`: fast one-frame headless boot check without an import pass
- `validate_project.bat`: import pass, then one-frame headless smoke validation
- `editor_project.bat`: open the Godot editor against this repo
- `resolve_godot.bat`: print the Godot executable path the repo-local wrapper will use
- `add_tools_to_path.bat`: append `tools\bin\` to your **user** `PATH` so `godot` runs `tools\bin\godot.cmd` in new terminals (see [docs/LOCAL_GODOT_CLI.md](docs/LOCAL_GODOT_CLI.md))

## Agent Asset Generation Commands

Use the headless-only pipeline from repo root:

```powershell
# list pending image entries from docs/ai/ASSET_MANIFEST.json
.\tools\asset_orchestrator.ps1 manifest-list --image-only

# generate pending image assets through ComfyUI API (headless)
.\tools\asset_orchestrator.ps1 manifest-generate --provider comfyui --checkpoint "<your_model>.safetensors"

# preview manifest execution without writing files
.\tools\asset_orchestrator.ps1 manifest-generate --provider comfyui --checkpoint "<your_model>.safetensors" --dry-run

# refresh deterministic in-repo generated assets
.\tools\asset_orchestrator.ps1 procedural-refresh --preset all
```

Automation scope is intentionally limited to headless workflows; GUI-only tools are documented in [docs/ai/AGENT_ASSET_AUTOMATION.md](docs/ai/AGENT_ASSET_AUTOMATION.md).

Wrapper behavior:
- Uses `tools/godot.ps1`
- Keeps logs and writable Godot state inside `.godot-cli/`
- Does not require a machine-wide `PATH` entry if Godot can be auto-discovered
- `debug_harness.bat` keeps the normal `Title -> Lair -> Route -> Combat` flow untouched

Godot resolution order:
1. `WHAT_WE_FED_GODOT_EXE` env var
2. `.godot-cli\godot_path.txt`
3. common local Windows paths such as `Downloads` and `Program Files`

## What Validation Actually Verifies

`validate_project.bat` verifies:
- the project imports
- Godot can boot the project headlessly
- parse errors in scripts
- autoload and early startup failures
- obvious runtime boot crashes
- **Data Integrity**: Unique IDs and valid resource paths in `data/CombatContent.gd`, `data/RouteContent.gd`, and song maps.

It does not verify:
- live gameplay feel
- reward readability under combat pressure
- boss flow correctness beyond boot
- interactive input flows
- smaller-screen readability

`smoke_project.bat` is the fast developer path when you only need to verify:
- the project still boots
- autoloads still initialize
- there are no obvious parse/startup failures

Use `smoke_project.bat` during rapid script or tooling passes.
Use `validate_project.bat` before handoff when imports or assets may have changed.

Logs:
- `.godot-cli/logs/godot-debug-harness.log`
- `.godot-cli/logs/godot-import.log`
- `.godot-cli/logs/godot-smoke.log`
- `.godot-cli/logs/godot-validate.log`
- `.godot-cli/logs/godot-run.log`
- `.godot-cli/logs/godot-editor.log`

Known safe Windows warnings during clean validation:
- `Failed to read the root certificate store`
- `ObjectDB instances leaked at exit`

Treat other `ERROR`, `SCRIPT ERROR`, `USER ERROR`, or `Parse Error` lines as real failures.

## Runtime Source Map

Most agent work should start from these files:
- Main combat runtime: [scenes/combat/CombatScene.gd](scenes/combat/CombatScene.gd)
- Combat meter and style/timing state: [systems/CombatMeter.gd](systems/CombatMeter.gd)
- Run growth and support runtime: [systems/RunGrowth.gd](systems/RunGrowth.gd)
- Music pressure runtime: [systems/SongConductor.gd](systems/SongConductor.gd)
- Shared event coordination: [autoloads/EventBus.gd](autoloads/EventBus.gd)
- Run/player state: [autoloads/GameState.gd](autoloads/GameState.gd)
- Content and tuning data: [data](data)
- Repo ownership map: [REPO_SYSTEM_MAP.md](REPO_SYSTEM_MAP.md)

When inspecting a system:
- start from the runtime owner script
- then check `EventBus`
- then check the relevant `data/` content file
- then validate with repo-local Godot commands if the change is non-trivial

## Task Routing

Gameplay feature pass:
- inspect live runtime files first
- confirm live-build truth vs final-scope canon
- implement the smallest strong layer
- run `validate_project.bat`
- launch the game if the task requires runtime confirmation

Bug fix:
- identify the actual faulting runtime owner
- fix the smallest strong cause
- validate
- state exactly what was and was not runtime-verified

Repo/tooling pass:
- prefer repo-local wrappers, docs, and validation clarity
- avoid speculative automation
- avoid machine-wide assumptions
- use `smoke_project.bat` first, then `validate_project.bat` if imports or assets changed

Debug harness pass:
- use `debug_harness.bat` for fast combat-state validation
- keep harness work isolated from the normal player boot path
- do not claim gameplay validation from harness boot alone

Design/canon question:
- answer from live-build docs first
- only then expand to final-scope canon
- clearly label deferred systems as deferred

## Anti-Drift Rules

Before editing:
- verify whether the repo already has the system
- separate live build truth from final dream scope
- prefer one source-of-truth doc over overlapping notes

After editing:
- run repo-local validation when possible
- if launch was not performed, say so plainly
- if launch succeeded but no interactive scenario was exercised, say so plainly
- call out what remains unverified
