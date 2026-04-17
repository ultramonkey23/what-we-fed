# What We Fed — Codex Agent Rules

This repo is a Godot 4.6 rhythm-action prototype evolving into a larger flagship game.
Do not treat it as throwaway code.

## Core behavior
- Inspect first.
- Plan first.
- Wait for approval before editing.
- Do not refactor architecture casually.
- Preserve the EventBus pattern unless explicitly told otherwise.
- Prefer medium coherent patch bundles over many tiny edits.
- Keep scope tight.

## WHAT WE FED IMPLEMENTATION STANDARD

This project is not a generic action prototype.
All implementation work must preserve and strengthen the actual game spine.
## PROTOTYPE GRADUATION / FULL-GAME STANDARD

This project is no longer treated as a throwaway prototype.
All coding work should assume the current repo is becoming the real game foundation.

### Full-game default
When choosing between:
- a quick local patch that only helps the current slice
- or a thin layered improvement that helps the game grow into full scope

prefer the thin layered improvement, as long as it does not weaken timing trust, lane clarity, or current stability.

### Build toward the full game, not endless prototype polish
Default implementation work should increasingly strengthen one or more of these full-game directions:
- stronger runtime distinctiveness between runs, regions, creatures, and bosses
- stronger long-term creature value
- stronger between-run structure
- stronger world-facing structure
- stronger boss identity and performance states
- stronger data-driven expansion paths
- stronger future hooks for world-state and long-form consequence

Do not spend repeated passes polishing isolated prototype behavior if a broader full-game gap is clearly more important.

### Every non-trivial patch must answer:
1. What full-game layer does this strengthen?
2. Does this make the game broader, deeper, or more distinct?
3. Does this reduce future retrofit pain?
4. Is this still the smallest strong version of the change?

### Prototype smell check
Be suspicious of changes that:
- only improve one narrow moment but do not help the game scale
- add decorative schema with no reader
- add future-lore hooks with no practical gameplay direction
- hardcode content that will obviously need expansion
- make one script absorb too many unrelated responsibilities
- solve the current symptom while making future systems harder to add
- improve polish while ignoring a more important structural gap

### Graduation rule for systems
A system should start being treated as "real" once it has:
- proven fun or readability in play
- been touched in multiple patches
- more than one content variant
- clear future expansion pressure

Once a system reaches that point:
- stop treating it as temporary
- stop patching it like disposable glue
- extract data and helper structure where useful
- make future additions cleaner and more repeatable

### Extraction threshold
When any of the following becomes true, prefer extraction over more hardcoding:
- 3+ content variants exist
- 2+ scripts are duplicating the same logic
- a single script is mixing presentation, flow, content, and tuning in one area
- the same kind of change has already been made twice

Good extraction targets:
- data files
- small helper functions
- isolated subsystem scripts
- clean constants / enums / structs

Bad extraction:
- speculative frameworks
- abstract managers with no present need
- architecture that slows iteration without increasing clarity

### Content authoring rule
When adding content that will likely multiply later:
- make it data-driven early
- keep content readable to future editors
- keep tuning values centralized
- avoid hiding core tuning in many unrelated scripts

This especially applies to:
- creatures
- region behavior
- song maps
- boss patterns
- upgrades
- support roles
- world-state hooks

### Full-game progression bias
Near-term coding should increasingly bias toward:
- feel cohesion
- runtime distinctiveness
- stronger creature identity
- stronger boss identity
- stronger region identity
- stronger between-run meaning
- thin prep for later world-state and ranch systems

Do not prematurely build full ranch or full world-state systems, but do build toward them in a way that reduces future rework.

### Deferred-system discipline
Some systems are explicitly later-scope and should not be bloated early.
Before deepening ranch or world-state code, confirm the current build has enough:
- creature breadth
- creature role clarity
- bond/eat tension
- support stability
- run-growth maturity

If those are still weak, strengthen them first.

### Boss and world scaling rule
Bosses should increasingly become:
- battlefield personalities
- performance states
- rhythm/pressure rewrites
not just higher-HP enemies.

Regions and world-facing systems should increasingly become:
- runtime-distinct
- pressure-distinct
- mood-distinct
not just different labels on the same run.

### Final implementation bias
Code should increasingly answer:
"How does this help What We Fed become the full game?"

not just:
"Does this make the current prototype a bit nicer?"
### Non-negotiable game priorities
When changing code, preserve these first:
- timing truth
- lane pressure readability
- bond vs eat tension
- creature meaning
- readable triggered support
- dark stylish oppressive tone
- the "start weak, become feared" fantasy

If a change improves abstraction but weakens any of the above, reject it.

### Foundation-first rule
Treat the current prototype as foundation, not disposable scaffolding.
Default to:
- evolving what already works
- hardening fragile code
- extracting data when needed
- adding systems in thin layers

Avoid:
- casual rewrites
- replacing working combat flow for novelty
- flattening the game into generic genre patterns

### Combat change rules
When editing combat code:
- preserve timing-truth windows
- preserve lane clarity under pressure
- prefer stronger feel over bigger system count
- do not add mechanics that make player reads less trustworthy
- do not turn the game into a pure rhythm gimmick
- do not let songs overpower fairness or clarity

Any combat edit should answer:
1. does this improve feel?
2. does this improve readability?
3. does this improve distinctiveness?
4. does this preserve trust?

### Creature and support rules
Creatures must not become generic reward tokens.
When editing creature systems:
- strengthen role identity
- strengthen bond vs eat tension
- keep support role-specific and readable
- keep only one active support creature in combat unless explicitly changed later
- do not let support become autonomous screen-clearing pet spam
- prefer signature interactions over flat number inflation

### Music and SongConductor rules
Songs should shape pressure and feel, not create chaos.
Use music to drive:
- section pacing
- beat feel
- pressure shifts
- boss/climax timing
- visual pulse and combat expression

Avoid:
- raw waveform chaos
- unreadable beat gimmicks
- music logic that breaks combat trust
- timing layers that fight the existing combat windows

### Boss rules
Bosses must feel like performance states, not bigger normal enemies.
When editing bosses:
- make them alter battlefield rhythm or pressure identity
- preserve readability
- prefer one coherent boss identity layer over many scattered gimmicks
- keep boss spectacle aligned with actual gameplay pressure

### Region and route rules
Regions should become meaningfully different in runtime, not only in front-end flavor.
Prefer:
- data-driven runtime differentiation
- pressure-style differences
- lane bias or phase behavior differences
- music and pacing differences that stay readable

Avoid:
- giant biome frameworks too early
- fake variety with only cosmetic labels

### Lair / ranch / world-state rules
Keep ranch and long-term world-state layers deferred until the current slice proves its value.
Do not expand these systems early just because hooks exist.
Before adding deeper ranch or world-state logic, confirm:
- more creatures exist
- creature roles are clearer
- bond/eat tradeoffs are stronger in real play
- active bonded support is stable
- current run-growth loop is trustworthy

### Architecture rules specific to this project
Default to:
- typed GDScript wherever practical
- one script = one main responsibility
- data-driven content in data/ when expansion is likely
- narrow helpers over giant manager classes
- constants/enums for state and timing names
- composition over inheritance webs
- scenes for structure, scripts for behavior
- lightweight data objects where full nodes are unnecessary

Avoid:
- hardcoded content spread across many scripts
- duplicated parallel systems
- mystery globals
- brittle cross-scene node-path assumptions
- giant switchboards
- speculative "future-proof" frameworks that are not yet earned

### EventBus rule
Preserve the EventBus pattern unless there is a compelling project-specific reason to change it.
Do not bypass EventBus casually when the current project already relies on it as a stable coordination layer.

### Code quality gate for edits
Before finalizing any edit, check:
- does this strengthen the game spine?
- does this make the game feel more distinct?
- does this preserve readability under pressure?
- does this reduce or increase future fragility?
- is this the smallest strong version of the idea?
- did I accidentally make the game more generic?

### Required implementation discipline
For any non-trivial change:
- identify exact files touched
- keep scope bounded
- avoid stealth system expansion
- include a clear test checklist
- call out remaining risks honestly
- prefer direct, grounded summaries over vague hype

## Current priorities
1. Timing Truth Bundle
2. Creature Feedback Bundle
3. Combat Feel Cleanup Bundle
4. Data Extraction Bundle
5. Boss / Cadence Foundations

## Required workflow
When asked to work:
1. Inspect relevant files
2. Explain current behavior
3. Explain the problem/opportunity
4. Propose the patch scope
5. List files to change
6. List risks
7. List tests
8. Stop and wait

Do not edit until I explicitly say:
APPROVE EDIT




## Project docs
See:
- docs/CLAUDE_APPROVAL_WORKFLOW.md
- docs/PATCH_QUEUE.md
- docs/PROMPT_TEMPLATES.md
Primary scope canon: docs/WHAT_WE_FED_FINAL_GAME_SCOPE_CANON_FLAGSHIP.md
Future kaiju/world-state canon: docs/THE_HOLLOW_EGG_KAIJU_ASCENSION_CANON.md
Current prove-it ladder: docs/DEMO_MILESTONE_LADDER.md
Core fantasy law: docs/GAME_SOUL_AND_CORE_FANTASY.md
Song-level structure: docs/SONG_LEVEL_STRUCTURE.md
