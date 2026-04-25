# WHAT WE FED — GDSCRIPT AGENT GUIDE

Version: 1.1 | Complements: `AGENTS.md`, `docs/ai/AI_CONTROL_PLANE.md`, `docs/ai/SIGNAL_MAP.md`, `.cursor/rules/*.mdc`

## 1. Purpose

This guide tells AI agents how to write **safe, repo-fit GDScript** for WHAT WE FED before editing any `.gd` file.

It does **not** claim the codebase is fully typed, uniformly styled, or free of legacy patterns. It sets **discipline** for future edits.

Following this guide does **not** make the repo “typed” or “clean” by itself — it only bounds **your** patch. See **§4.1** and **§6.1**.

**Related load order (repo truth):**

- `docs/ai/TERMINAL_AI_BOOTSTRAP.md` — terminal fast-load
- `docs/ai/AI_CONTROL_PLANE.md` — routing, reports, validation honesty
- `docs/ai/SIGNAL_MAP.md` — static EventBus / signal flow scan (not runtime proof)
- `CLAUDE.md` — Godot root, live scene flow, validation commands
- `REPO_SYSTEM_MAP.md` — system ownership (when present)
- Folder adapters: `scenes/combat/CLAUDE.md`, `systems/CLAUDE.md`, `data/CLAUDE.md`, `scenes/CLAUDE.md`

## 2. Core Rule

**Do not write generic GDScript.**

First **scan the repo**, **match the local file’s style**, identify the **Godot owner** (scene vs autoload vs system vs data), then make the **smallest safe change**.

Reject drive-by abstractions, “utility dumps,” and patterns that would not blend with neighboring lines in the same file.

## 3. Required Before Editing `.gd`

Agents must identify (and briefly note in their report):

| Question | Where to look |
|----------|----------------|
| **Godot version / project context** | `project.godot` (read-only for agents unless explicitly approved), `CLAUDE.md` working truth |
| **File owner** | Who constructs/owns the node; who calls `setup` / `start`; paired `.tscn` if any |
| **System owner** | `systems/*.gd`, `REPO_SYSTEM_MAP.md`, `docs/ai/AI_CONTROL_PLANE.md` fragile-system list |
| **Signal / event path** | `autoloads/EventBus.gd` declarations; **`docs/ai/SIGNAL_MAP.md` as a map only** — then **mandatory source verification** per **§6.1** |
| **Data owner** | `data/*.gd` content scripts, song maps, combat feel — not hardcoded duplicates |
| **Validation path** | Section 13 — which `.bat` commands apply |
| **Protected systems touched** | Especially combat hot path (Section 11) |

If truth is stale or conflicting, follow **Fresh Truth Gate** in `docs/ai/AI_CONTROL_PLANE.md` before implementing.

## 4. Typing Rules

Prefer **typed GDScript** for **new or edited** code, consistent with the **surrounding file**:

- Typed function parameters and **return types** on **new** functions (`-> void`, `-> bool`, etc.).
- Typed locals when it clarifies contracts or prevents mistakes.
- Typed constants where the file already uses explicit types (e.g. `const X: float = 1.0`).
- Typed dictionaries and arrays **when practical** (`Dictionary`, `Array[int]`, etc.) — match nearby declarations.
- **Avoid untyped `Variant` soup** in new code unless the **existing file** consistently uses untyped APIs (e.g. some `Array` without element type, or dynamic `Dictionary` payloads).
- **Do not mass-convert** old files for typing or style-only passes unless explicitly tasked and audited.

**Reality check:** The repo mixes strict typing (e.g. many `GameState` proxies, typed `@onready` in `CombatScene.gd`) with older or pragmatic untyped areas (e.g. some `Node` references, dynamic `Dictionary` signal payloads). **New code should lean typed** without fighting the whole file in one patch.

### 4.1 Mixed typing baseline (agent obligations)

- **Legacy is normal:** Entire files may stay partially untyped for years. That is **not** a license to add more slop in new lines — it is a reason to **match the local envelope** (the function or block you touch) and improve **only** what your change needs.
- **One patch ≠ repo health:** Do **not** report “typing pass,” “modernized GDScript,” or “codebase is cleaner/typed now” unless the task was explicitly repo-wide and verified.
- **Honest scope:** State what **you** typed (new params, returns, locals) vs what you **left** unchanged in the same file.
- **Do not** widen a small fix into a file-wide typing sweep — that belongs in a dedicated, approved pass with its own validation story.

## 5. Function Rules

- Keep functions **small** when it improves readability — avoid inflating `CombatScene.gd`-scale files without need.
- **Do not hide gameplay behavior** behind vague helpers (`do_stuff`, `handle`, `process_things`).
- Use names that express **game intent** (`resolve_timed_attack`, `grant_support_charge`, not `fix_state`).
- **Return type annotations** on every **new** function.
- **Do not** introduce broad shared utilities unless **multiple call sites** already need the same contract — prefer local clarity over premature extraction.

## 6. Signal Rules

- **`autoloads/EventBus.gd`** defines cross-cutting signals, often with **typed parameters** and `@warning_ignore("unused_signal")` on declarations. **Match contracts exactly** — names, arity, and types.
- **Do not change** signal signatures casually; treat it as a **breaking API** for every `emit` and `connect`.
- **If adding a signal:** document in the agent report: **emitter(s)**, **listener(s)**, **payload shape**, **owner**, and how **validation** will catch mistakes. Regenerate or update signal reference workflow if the project uses it (`docs/ai/SIGNAL_MAP.md` notes it is a static scan).
- **Disconnect / cleanup:** Follow existing patterns (e.g. `CombatScene.gd` and subsystems that disconnect in `_exit_tree` or teardown paths). Search for `disconnect` and mirrored `connect` when touching subscriptions.
- **Do not** create **duplicate parallel signal paths** (second bus, duplicate “almost same” signals) without explicit architecture approval.

**Local signals:** Scripts like `systems/SongConductor.gd` or `scenes/combat/CombatScene.gd` may declare **scene-local** signals — same rules apply within their listen/connect graph.

### 6.1 `SIGNAL_MAP.md` is static — verify in source

`docs/ai/SIGNAL_MAP.md` is a **generated, static** view. It can be **wrong or incomplete** when code uses:

- `Callable` / `bind` / lambdas where listeners are not obvious from text search
- Dynamic signal names, indirect `emit`, or connections built from data
- Runtime-only `connect` paths, add-on scripts, or tools not scanned by the generator

**Mandatory workflow** when you change, add, or rely on a signal (especially `EventBus`):

1. Read the **declaration** in `autoloads/EventBus.gd` (or the owning script for local signals).
2. **Search the repo in source** for the signal name and for `emit` / `emit_signal` / `EventBus.` patterns — include consumers: `connect`, `await`, `is_connected`, `disconnect`.
3. Open **every** emitter and listener file your change cares about; **read** the handler signature and payload use — do not trust the map row alone.
4. In your report, state **`SIGNAL_MAP` used as index only: yes`** and **grep / read verification done: yes** (with paths or a tight summary).

If search results disagree with `SIGNAL_MAP.md`, **source wins**. Consider flagging drift for regeneration or doc update in a separate, explicit task.

## 7. Node / Scene Rules

- **Do not edit `.tscn`** unless the task **explicitly** allows scene edits. Node path changes break `@onready` and exports.
- **Do not rely on brittle deep paths** without verifying the **paired scene** and existing patterns (`$UI/...`, `%UniqueName` if used).
- Prefer **typed `@onready`** when editing scene scripts (as in `CombatScene.gd`), e.g. `@onready var hp_bar: ProgressBar = $UI/HPBar`.
- **Optional nodes** must be guarded (`if node:`, `is_instance_valid`, or lazy fetch) — match file convention.
- **Do not** relocate scene ownership into random systems — keep **lifecycle** with the scene or documented autoload.

## 8. Autoload Rules

- **`GameState`** owns persistent / run-level state and compatibility proxies — **do not** casually reshape save-facing or run state without an explicit persistence plan.
- **`EventBus`** owns **cross-system signals**, not business logic. Do not stuff game rules into the bus.
- **No new autoloads** without **explicit** creator/project approval (requires `project.godot` changes).
- **No new globals** when **local ownership** (scene child, system node, resource) is enough.

## 9. Data / Export Rules

- Prefer **`data/*.gd`** (and related content) for **authored tuning, IDs, tables, and copy** — e.g. combat feel, song profiles, presentation text consumed by `CombatScene.gd` via `preload`.
- Use **`@export`** when **designer-tunable scene values** are appropriate; avoid exporting secrets of timing contracts without understanding combat feel ownership.
- **Do not hardcode** creature IDs, lane indices, or tuning that already lives in **data** owners — check `data/` and consumers first.
- If you must introduce a **first-pass tuning** constant, **name it clearly** (purpose + unit in comment if non-obvious) and place it where maintainers expect (file-level `const` near related logic, or data).

## 10. Error / Guard Rules

- **Defensive checks** around optional nodes, deferred references, and `ResourceLoader.load` / `preload` failures (see patterns like `SongConductor` pushing errors on missing audio).
- **Report missing data** with `push_error` / `push_warning` as appropriate — do not fail silently.
- **Do not swallow** exceptions or errors in ways that hide combat dishonesty.
- **Do not spam** logs inside **per-frame or per-beat hot loops** — rate-limit or gate debug prints.

## 11. Combat-Specific GDScript Rules

**Never casually change:**

- **Timing windows** (beat quality, recovery, iframe, stagger — e.g. `PlayerCombat.gd`, `SongConductor.gd`, `CombatFeelConstants.gd`)
- **`PlayerCombat.gd`** action resolution, input buffering, chain/bypass, lane focus semantics
- **`LaneManager.gd`** projectile / attack / parry / status resolution and fire-cycle authority
- **`EventBus`** combat-related signal contracts
- **`GameState`** save / persistence shape and run proxies
- **`CombatScene.gd`** core combat loop, conductor integration, reward shell, and teardown/connect graphs

If any of the above **must** be touched: require **explicit justification**, **narrowest diff**, **emitter/listener audit**, and **stronger validation** (`validate_project.bat`, `smoke_project.bat`, and `debug_harness.bat` or manual playtest when feel/input/HUD is implicated).

## 12. Style Rules

- **Match local naming** (`snake_case` for functions/vars per GDScript norm in this repo), **spacing**, and **comment tone** in the file you edit.
- Prefer **readable** code over clever one-liners.
- **No broad formatting churn** — no reindenting entire files, no mass whitespace-only diffs.
- **No mass rewrites** or unrelated cleanup inside feature patches.

## 13. Validation Rules

Run from **Godot project root** (`what-we-fed/`, same directory as `project.godot`):

**For any `.gd` edit:**

1. `git status --short` **before and after** (know every touched path).
2. **Targeted diff review** — read your own diff; ensure no accidental files.
3. **`validate_project.bat`** — import pass, smoke boot, data audit per project scripts.
4. **`smoke_project.bat`** — fast headless boot check.

### 13.1 Git working tree — never assume a clean baseline

- **Always** run `git status --short` **before** claiming “only these files changed.” Another agent or the creator may have **pre-uncommitted** `.gd` (or other) edits in the tree.
- If `git status` shows paths **outside your task**, **do not ignore them** in the report: label them **pre-existing / out-of-scope** (or integrate if your editor touched them by mistake).
- Prefer **`git diff --stat`** and path-scoped **`git diff path/to/file.gd`** so you see exactly what **your** session changed before commit.
- **Do not** stash, revert, or “clean” unrelated local changes unless the user explicitly asked — report the situation instead.
- When validating, remember: **smoke/validate exercise the working tree as it exists**, not “main at HEAD” — hidden dirty files can affect outcomes.

### 13.2 `SIGNAL_MAP.md` maintenance (optional follow-up)

If you changed signal contracts or materially shifted emit/listen topology, note in the report whether **`SIGNAL_MAP.md` should be regenerated** (project-specific script or workflow, if any). Do not claim the map is updated unless you actually ran the update.

**Also run when relevant:**

- **`validate_data.bat`** — if `data/` or content schemas / IDs changed.
- **`debug_harness.bat`** — if combat, input, or HUD logic changed **and** it is safe per task constraints (dev harness).

**Manual playtest** is required when the change can affect **feel, readability, input, rhythm, or HUD feedback** — smoke/validate alone are not enough (see `CLAUDE.md`).

Label validation claims honestly (`runtime-verified` vs `static-only` vs `not run`) per `.cursor/rules/10-validation-and-runtime-safety.mdc`.

## 14. Agent Report Addition

Every agent report that touches `.gd` files must include:

**GDScript quality decision:**

- **Existing style matched:** (file-level examples: typing density, `@onready` style, signal naming)
- **Types added:** (where; return types; params; none if intentionally minimal)
- **Signals changed:** yes/no — if yes, list and cite emitters/listeners
- **Node paths / `.tscn` changed:** yes/no
- **Autoload / global state changed:** yes/no
- **Data ownership respected:** (yes/no + note)
- **Broad formatting avoided:** yes/no
- **Validation run:** (commands + outcome)
- **`SIGNAL_MAP` index-only + source grep/read:** yes/no (per **§6.1**)
- **Working tree:** clean / dirty — if dirty, list **non-task** paths from `git status --short` (per **§13.1**)
- **Remaining GDScript risks:** (timing, nullables, indirect `connect`, map drift, uncommitted files affecting validation, etc.)

## 15. Stop Conditions

**Stop and report** instead of editing if the change would require:

- Broad **`CombatScene.gd`** rewrite or unmaintainable expansion without a design split
- **`project.godot`** edit (e.g. new autoload, input map) without explicit approval
- **New autoload** or new global singleton pattern
- **New save schema** or migration without an explicit persistence plan
- **New parallel manager** duplicating `LaneManager`, `CombatMeter`, `SongConductor`, etc.
- **Signal contract rewrite** or breaking EventBus payload changes
- **Timing / input / lane resolution** changes **without** explicit approval and validation plan

When stopped, use the **Handoff** block in `AGENTS.md` and route to the right specialist (BRAIN / CYBORG / INSPECTOR) with files, risks, and validation gaps.

---

## Appendix A — Repo patterns snapshot (illustrative, not exhaustive)

These examples show **style anchors**, not mandates to rewrite other files:

- **EventBus:** Central typed `signal` declarations; cross-system contract surface.
- **GameState:** `preload` of data scripts; typed `Array[Dictionary]` / `Dictionary` in many proxies; sub-state objects (`PlayerState`, etc.).
- **CombatScene:** Many `const` `preload`/`PackedScene` lines; typed `@onready` node references; local `signal` for presentation requests.
- **PlayerCombat / LaneManager:** File-level tuning `const`s, lane indices as ints, coordination with `EventBus` and optional `lane_manager` injection patterns — high sensitivity; edit minimally.
- **Data scripts:** Often `extends RefCounted` with `const` dictionaries for tuning tables.

**When in doubt:** read the **next 50 lines** above and below your edit, then align with that voice.
