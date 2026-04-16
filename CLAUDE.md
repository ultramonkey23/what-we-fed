# WHAT WE FED — PROJECT MEMORY

This project is the base implementation for a larger flagship game direction.

## Current truth
This is currently a Godot 4.6 2D rhythm-action combat prototype with:
- 3 horizontal lanes
- timing-based projectile interaction
- lane actions using A/S/D plus modifiers
- combo/style/ultimate systems
- reward choices based on bonding or consuming creatures
- one-scene prototype structure
- EventBus-driven communication pattern

## Non-negotiable current architecture rules
- Preserve the EventBus pattern unless explicitly told otherwise.
- Do not refactor large systems casually.
- Do not rewrite the whole prototype unless explicitly asked.
- Prefer small, testable, low-risk changes.
- Explain what will change before editing.
- After editing, explain exactly what changed and how to test it.

## Core long-term direction
This prototype is being evolved into a flagship game with these pillars:
- dark oppressive worldbuilding
- horror + creature feeding + mutation
- rhythm/timing-based mastery
- strong style and atmosphere
- “start weak, become feared” power fantasy
- enemy and boss musical identity shaping combat feel
- AI-assisted development with careful scope control

## Current workflow
- ChatGPT = design brain, critic, planner, prompt architect
- Claude Code = local coding partner
- Godot = implementation engine

## Editing behavior
When asked to make a change:
1. Inspect current relevant files first
2. Explain what is happening now
3. Explain the smallest safe change
4. Make the edit
5. Explain how to test it
6. Avoid unrelated refactors

## Imports
@docs/GAME_SPINE.md
@docs/PROJECT_OPERATING_SYSTEM.md
@docs/NEXT_PHASE_PLAN.md
@docs/CLAUDE_APPROVAL_WORKFLOW.md
@docs/PATCH_QUEUE.md
@docs/PROMPT_TEMPLATES.md
@docs/WHAT_WE_FED_FINAL_GAME_SCOPE_CANON_FLAGSHIP.md
@docs/THE_HOLLOW_EGG_KAIJU_ASCENSION_CANON.md
@docs/DEMO_MILESTONE_LADDER.md
@docs/GAME_SOUL_AND_CORE_FANTASY.md
@docs/SONG_LEVEL_STRUCTURE.md