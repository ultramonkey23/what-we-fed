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

## WHAT WE FED EXECUTION MODE

## Core long-term direction
This prototype is being evolved into a flagship game with these pillars:
- dark oppressive worldbuilding
- horror + creature feeding + mutation
- rhythm/timing-based mastery
- strong style and atmosphere
- “start weak, become feared” power fantasy
- enemy and boss musical identity shaping combat feel
- AI-assisted development with careful scope control
## FULL-GAME PRODUCTION MODE

This repo is no longer treated as a prototype playground.
Default behavior should increasingly help the current foundation grow into the real game.

### Primary execution bias
When multiple valid edits are possible, prefer the one that:
- strengthens long-term game identity
- improves runtime distinctiveness
- helps systems scale cleanly
- reduces future retrofit pain
- still stays practical in the current codebase

Do not default to the smallest possible local patch if a slightly broader thin-layer improvement would better move the project toward full-game reality.

### Full-game layer check
For any non-trivial coding task, quietly identify which layer it advances:
- combat feel
- run-growth depth
- creature identity
- boss identity
- region identity
- between-run structure
- future ranch preparation
- future world-state preparation

If a change clearly strengthens none of these, reconsider whether it is worth doing now.

### Evolution rule
The prototype is the foundation.
Do not treat current systems as disposable unless they are clearly broken or blocking growth.
Default to:
- evolve
- harden
- deepen
- extract when necessary
- layer new systems on top of what works

Avoid:
- novelty rewrites
- replacing existing foundations casually
- abstracting away the game’s actual identity

### Practical full-game bias
As the project matures, prefer work that helps the repo become:
- more content-expandable
- more data-driven where content will multiply
- more distinct from generic action/roguelite design
- more ready for broader creature, boss, and world layers

### Distinctiveness rule
If a coding choice would make the game more generic, choose again.
Prefer implementations that preserve or strengthen:
- timing trust
- lane pressure identity
- bond vs eat tension
- creature meaning
- readable triggered support
- dark stylish oppressive tone
- musically charged combat feel
- start weak, become feared

### Anti-prototype-polish rule
Do not spend repeated cycles polishing isolated prototype details if the more important need is:
- stronger feel cohesion
- stronger boss uniqueness
- stronger region runtime identity
- stronger creature build divergence
- stronger between-run meaning

### Thin-layer rule
To move toward full game without exploding scope:
- build thin playable layers
- keep layers coherent
- make each layer prove something real
- preserve future expansion paths

Good:
- one stronger boss identity layer
- one stronger region runtime layer
- one stronger creature-signature layer
- one stronger between-run meaning layer

Bad:
- giant frameworks
- speculative future systems
- wide shallow feature creep

### Extraction timing
If a gameplay/content area is clearly becoming permanent and is already touched repeatedly, treat it as graduation pressure:
- extract constants
- extract content data
- isolate helpers
- reduce hardcoded duplication
- keep tuning centralized

But do not do large refactors without a direct payoff.

### Deferred systems reminder
Ranch and deeper world-state are real later-scope systems, but they should not be overbuilt early.
Only deepen them when current runtime systems are strong enough to justify it.

### Preferred outcome of edits
After an edit, the game should ideally be:
- more fun
- more readable
- more distinct
- more scalable
- more like the final game
not just “more code complete”
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

## WHAT WE FED EXECUTION MODE

This project is implementation-first.
Default to coding, debugging, tightening, and practical production help.
Do not drift into broad design discussion unless explicitly asked.

### Repo-truth rule
Always prefer current repo truth over stale chat assumptions.
Before changing anything significant:
- inspect what already exists
- check whether the system is already implemented
- verify whether the requested change is already partially done
- avoid reapplying completed work

Do not assume chat memory is correct if the repo says otherwise.

### Default behavior
Unless explicitly asked for planning only:
- edit directly
- keep scope coherent
- choose the strongest practical version that fits the current codebase
- avoid approval-loop churn
- avoid splitting one simple task into too many phases

### Project-specific priority order
When multiple improvements are possible, prioritize:
1. timing trust
2. player feel
3. lane readability
4. creature identity
5. support readability
6. runtime distinctiveness
7. shell/world layering later

### Combat execution bias
When working on combat, bias toward:
- stronger feel
- more trustworthy timing
- clearer pressure reads
- more distinctive action identity
- better rhythm integration
- better creature/support expression

Do not bias toward:
- abstract purity over feel
- generic safety that makes the game bland
- extra complexity without stronger player experience

### Music integration rule
Music should become part of combat expression, not just background structure.
When improving music-related gameplay:
- make player action feel more on-beat
- make successful actions feel more musically answered
- preserve fairness and clarity
- avoid rhythm gimmicks that fight the lane system

### Creature-support rule
Support should feel signature, triggered, and role-defining.
When improving creatures:
- make them feel more like combat philosophies or performance partners
- avoid turning them into passive stat wrappers
- avoid autonomous clutter
- preserve the rule of one active readable support creature unless explicitly changed

### Thin-layer rule
Prefer thin playable layers over giant framework expansion.
Default to:
- small strong edits
- clear vertical-slice proof
- practical extensions of existing systems

Avoid:
- giant future systems too early
- broad rewrites
- speculative abstractions
- replacing current foundations instead of strengthening them

### Anti-generic rule
Do not let the game drift toward:
- generic survivor clone behavior
- generic roguelite soup
- generic fantasy RPG habits
- spreadsheet-heavy management
- rhythm gimmick design detached from the game’s creature/combat identity

Whenever a task has multiple possible implementations, prefer the one that makes the game feel more uniquely like What We Fed.

### When editing, always protect:
- timing truth
- lane identity
- bond vs eat tension
- creature meaning
- readable support
- dark stylish oppressive tone
- start weak, become feared

## REQUIRED POST-EDIT SUMMARY

After any non-trivial edit, always summarize:

1. what changed
2. what files changed
3. what the actual root cause or implementation gap was
4. what the new behavior is
5. how to test it end-to-end
6. any remaining risks, edge cases, or deferred follow-ups

For gameplay-facing changes, also explain:
- what the player should feel differently now
- what was intentionally left unchanged
- whether the change strengthened distinctiveness, readability, or player mastery

For bugfixes:
- state the actual cause, not just the symptom
- prefer the smallest strong fix
- avoid stealth refactors unless necessary

For content/system additions:
- state exact scope
- state what was reused directly
- state what future expansion path was preserved

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
