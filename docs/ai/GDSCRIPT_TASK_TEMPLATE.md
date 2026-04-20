# GDScript Task Template

*Copy and paste this template when delegating tasks to an AI agent for the WHAT WE FED project.*

```markdown
## Mission
[Clear, one-sentence description of the goal. e.g., "Implement the 'Parry' timing window logic in PlayerCombat.gd"]

## Current Truth
[Brief statement of how the game currently works regarding this feature. e.g., "Player currently only takes damage on hit. No defensive moves exist."]

## Protected Systems
[Identify systems that MUST NOT be broken. e.g., "SongConductor.gd master clock, LaneManager.gd strict positioning."]

## Exact Files to Inspect
1. `path/to/file1.gd`
2. `path/to/file2.tscn` (for hierarchy reference)

## Exact Task Type
[Choose one: Surgical Bug Fix / New Feature Implementation / Refactor / Data Entry]

## Anti-Drift Rules
- Do NOT introduce generic RPG stats.
- Preserve "Bond vs Eat" mechanics.
- Maintain lane readability; no visual clutter.
- [Add task-specific anti-drift rules here]

## Output Format
- Provide the modified GDScript code.
- If `.tscn` changes are required (e.g., wiring signals in the inspector, adding nodes), list exact, step-by-step instructions for the human developer. Do not attempt to raw-edit `.tscn` files unless explicitly instructed.

## Validation Run Expectations
Before completing the task, you must:
1. Explain how this interacts with the `EventBus` (if applicable).
2. Note any potential null-reference risks.

## Validation Checklist (To be completed by human/agent)
- [ ] Code passes `smoke_project.bat` without parse errors.
- [ ] Feature tested in `debug_harness.bat`.
- [ ] Timing and lane honesty preserved in **realtime during active combat** (between-level menus are out of scope for this checkbox).
```