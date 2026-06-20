# WORLD REACTION / CONSEQUENCE LAYER V1

## Scope + Layer Position
- **Primary layer**: Layer 2 (Live Build Truth).
- **Secondary layer**: Layer 3 (Evolving Spine).
- **Later hooks only**: Layer 4 is tagged and deferred.
- This is a narrative surfacing layer, not a full persistent world-state system.

## 1) What the world notices
The world notices how the Living Codex feeds, what it preserves, and what rhythm it imposes under pressure.  
It reads the Codex as both archive and wound: each kill writes a line, each bond keeps a line alive.  
Regions do not score morality; they answer behavior with tone, pressure language, and threshold voice.

## 2) Consequence axes (v1, max 5)
- **Predation bias**: Repeated Eat choices and kill-forward patterning.
- **Preservation bias**: Repeated Bond choices and support-preserving patterning.
- **Cadence dominance**: The run is authored by timing flow and surge rhythm.
- **Ruin pressure**: The run is authored by damage, desperation, and violent closure.
- **Resonance pressure**: The run is authored by bond charge, support triggers, and echo behavior.

## 3) What each axis means narratively
- **Predation bias**: The Codex is read as a fast eraser. The world answers with sharper, less merciful language.
- **Preservation bias**: The Codex is read as a keeper-under-authority. The world answers with wary reverence.
- **Cadence dominance**: The Codex is read as rhythm law. The world answers with precision and inevitability language.
- **Ruin pressure**: The Codex is read as open damage that still advances. The world answers with fracture and blood-memory language.
- **Resonance pressure**: The Codex is read as a doubled pulse (self + bond layer). The world answers with echo, current, and wake language.

## 4) Feeding Hollow reaction
- **What it notices most**: Predation bias and ruin pressure.
- **World answer**: The Hollow treats force as law and mirrors hunger back at the Codex.
- **Existing live surfaces**:
  - Region identity and modifier: `feeding_hollow` in `RouteContent.REGIONS`.
  - DNA pickup flavor variants: `DNA_PICKUP_FLAVORS["feeding_hollow"]`.
  - Boss voice hooks: `BOSS_INTRO_LINES`, `BOSS_THRESHOLD_BREAK_LINES`, `BOSS_THRESHOLD_FINAL_LINES`.
  - Post-run echo hook: `POST_RUN_REGION_ECHO["feeding_hollow"]`.

## 5) Pale Shelf reaction
- **What it notices most**: Cadence dominance and ruin pressure endurance.
- **World answer**: The Shelf exposes every error and every clean sequence with cold precision.
- **Existing live surfaces**:
  - Region identity and modifier: `pale_shelf` in `RouteContent.REGIONS`.
  - DNA pickup flavor variants: `DNA_PICKUP_FLAVORS["pale_shelf"]`.
  - Boss voice hooks: `BOSS_INTRO_LINES`, `BOSS_THRESHOLD_BREAK_LINES`, `BOSS_THRESHOLD_FINAL_LINES`.
  - Post-run echo hook: `POST_RUN_REGION_ECHO["pale_shelf"]`.

## 6) Drowned Cut reaction
- **What it notices most**: Preservation bias and resonance pressure.
- **World answer**: The Cut treats bond charge as current and reads the Codex by wake, not footprint.
- **Existing live surfaces**:
  - Region identity and modifier: `drowned_cut` in `RouteContent.REGIONS`.
  - DNA pickup flavor variants: `DNA_PICKUP_FLAVORS["drowned_cut"]`.
  - Boss voice hooks: `BOSS_INTRO_LINES`, `BOSS_THRESHOLD_BREAK_LINES`, `BOSS_THRESHOLD_FINAL_LINES`.
  - Post-run echo hook: `POST_RUN_REGION_ECHO["drowned_cut"]`.

## 7) Boss intros / thresholds can shift
- Shift **tone only**, never mechanics.
- Hook surfaces:
  - Intro: `boss_intro_line()` -> `BOSS_INTRO_LINES`.
  - Break threshold: `boss_threshold_break_line()` -> `BOSS_THRESHOLD_BREAK_LINES`.
  - Final threshold: `boss_threshold_final_line()` -> `BOSS_THRESHOLD_FINAL_LINES`.
  - HUD state flavor: `boss_state_opening()` / `boss_state_final()`.
- v1 pattern:
  - Predation-lean: lines become harder, tooth-law, no-shelter.
  - Preservation-lean: lines become authority/reverence tension.
  - Cadence-lean: lines emphasize timing verdict and sequence inevitability.
  - Ruin-lean: lines emphasize fracture, attrition, and blood debt.
  - Resonance-lean: lines emphasize echo/current/sync pressure.

## 8) Post-run summary tone can shift
- Keep current numeric structure from `post_run_summary(stats, region_id, victory)`.
- Append one short axis-tail sentence after the existing region echo:
  - Predation: "The page closes with teeth."
  - Preservation: "The page closes with witnesses."
  - Cadence: "The page closes on perfect timing law."
  - Ruin: "The page closes under pressure scars."
  - Resonance: "The page closes with a second pulse."
- No additional ranking, no morality grade, no campaign branch flag.

## 9) Reward shell language can shift
- Hook surfaces:
  - `reward_bond_body(passive_text)`
  - `reward_eat_body(effect_text)`
  - optional result lines (`bond_result_body`, `eat_result_body`, Quig lines).
- v1 policy:
  - Preserve controls and lock logic exactly.
  - Shift phrasing based on dominant axis only.
  - Keep Bond vs Eat as meaning engine (not good/evil).
- Example direction:
  - Predation-dominant run: Bond copy sounds costly; Eat copy sounds decisive.
  - Preservation-dominant run: Bond copy sounds deliberate; Eat copy sounds clinical and grave.

## 10) Stored later vs surfaced now
- **Surface now only (no persistence required)**:
  - Dominant run axis read.
  - Axis-conditioned line variant for boss/post-run/reward shell.
  - Region-reactive flavor tone selection.
- **Store later (Layer 3 hook)**:
  - Last-run dominant axis per region (optional).
  - Short streak memory for repeated axis dominance (optional).
- **Do not store in v1**:
  - Global morality meter.
  - Permanent fate channel lock.
  - Branching campaign world tree.

## 11) What should be promoted
- Region-true voice (Hollow/Shelf/Cut each answering differently).
- Bond vs Eat tension as the central meaning engine.
- Tendency/surge-informed language (flow, iron, sync, vengeance).
- "Start weak, become feared" expression through reaction tone escalation.

## 12) What should be softened
- Any scoreboard framing that implies objective virtue.
- Any generic apocalypse/fantasy narration detached from region identity.
- Any text that turns the Codex into a hero/chosen-one figure.
- Any heavy prose that hides combat-clean readability.

## 13) What should be deferred (Layer 4 — Later Scope, tagged)
- Full persistent world-fate channels (Predatory/Mythic/Sterile/Haunted) as save-backed systems.
- Multi-run region transformation maps.
- Kaiju-line consequence threading and other flagship-scale persistence.
- Ranch-first or giant cosmology explanations.

## 14) Validation
- [ ] Every reaction hook maps to an existing live surface:
  - `DNA_PICKUP_FLAVORS`
  - `BOSS_INTRO_LINES`
  - `BOSS_THRESHOLD_BREAK_LINES`
  - `BOSS_THRESHOLD_FINAL_LINES`
  - `POST_RUN_REGION_ECHO`
  - `post_run_summary()`
  - `reward_bond_body()` / `reward_eat_body()`
- [ ] No new runtime requirement to ship narrative surfacing v1.
- [ ] No persistent world-state requirement for baseline behavior.
- [ ] Locked core preserved: timing truth, lane integrity, DNA economy, Bond vs Eat.
- [ ] No fake morality system, chosen-one framing, or branching campaign structure.
