# Combat spatial contract and truthful control harness repair

LAB_RECEIPT_CONTRACT_V1:
RESULT: PASS
PROJECT_ID: what-we-fed
MISSION: Repair the production combat spatial contract so the physical player origin, authored timing geometry, projectile-response eligibility, and control-focus proof describe the same playable interaction without broadening normal melee reach or interrupting song-run flow.
ROUTING_DECISION: direct Cody continuation; prior what-we-fed route context `rd_1791874125113_12d1890d`
FILES_CHANGED: scenes/combat/CombatScene.gd; scenes/combat/PlayerCombat.gd; scenes/combat/ZoneManager.gd; scenes/dev/DebugBootScene.gd; _visual_proofs/combat_spatial_contract/; receipts/receipt_20261013_combat_spatial_contract.md
START_HEAD: 3638b50fc28ed8b8a630cfffd9cf4d833c52a740
END_HEAD: pending-finish
COMMIT: pending-finish
VALIDATION_RESULT: PASS
RECOMMENDED_NEXT_ACTION: Use the real mid-song reward preview to inspect one earned-performance reward surface, then repair only a player-observed payoff/readability defect.

## Director Readable

Combat had two competing spatial truths: the timing field was arranged around `ZoneManager`'s arena center, while `PlayerCombat` could remain physically at its scene-default origin. A player could therefore see the center sigil and timing ring in one place while target queries used another. Separately, the visible outer timing ring extended past the regular melee attack range, so an incoming projectile could appear response-ready but be absent from the attack target set.

The repair makes `CombatScene` place both `PlayerCombat.global_position` and its free-movement anchor at the one arena center before setup. Projectile interception now reaches the authored hit-zone distance plus the visible outer ring (and the existing parry-forgiveness modifier) while enemy melee still obeys its earned normal and lunge ranges. This protects timing truth without turning the player into a broad-range melee attacker.

The live control harness now owns one real threat at a time, pauses competing song/escalation producers, records the accepted input lane rather than a transient post-dodge facing value, and returns a failing exit code if any step fails. It exercised N attack, E parry, S dodge, and W attack against the production projectile path.

## Technical Receipt

- Initial causal evidence: `ZoneManager` derives the arena center from the viewport, while `PlayerCombat`'s scene-default physical transform was `(0, 0)`; projectile eligibility used the normal melee `attack_range` despite the visible timing ring extending farther from the same hit zone.
- `CombatScene._setup_player_combat()` now applies `zone_manager.get_arena_center()` to both player physical anchors, preserving the timing sigil as the authoritative play space.
- `_get_targets_in_cone()` gives only unresolved projectiles an interception eligibility range covering `HIT_ZONE_DISTANCE + RING_OUTER_RADIUS +` the existing parry-forgiveness bonus. Enemy/lunge eligibility remains governed by the original close-range limits.
- `debug_fire_lane()` remains debug-build-only but no longer requires the normal scheduler to be running; this is required because the control harness correctly stops competing schedulers before it fires a deliberate production-path projectile.
- Fresh-profile intro-bond routing is deferred out of `CombatScene._ready`, preventing the observed busy-scene-tree removal error. Explicit DevHarness state remains isolated from that onboarding handoff.
- The accepted live `control_focus` run completed all four directional actions with `input_lane` equal to the requested lane and the expected projectile outcomes. A harness failure now maps into `get_tree().quit(1)`; the induced-failure branch itself was not separately forced in this unit.
- Visual witness: `_visual_proofs/combat_spatial_contract/screenshots/control_focus_centered_player.png` is a real 1280×720 `CombatScene` F12 capture with sibling metadata. It visibly places the player on the central sigil; its metadata records the cardinal timing geometry around that arena center. The package deliberately does not claim a manual feel or outer-ring attack-VFX review.
- Existing concurrent audio imports, enemy-marker visual-proof `.import` files, and the enemy-marker capture UID were inspected and excluded from this commit.
- The native visual-audit retention routine removed two old tracked captures during the windowed run; both exact files were restored from `HEAD` before closeout. The generated source capture was hash-checked against the retained package copy before its duplicate runtime-cache pair was removed.

## WHAT WE FED Agent Report

Agent: Codex (SYMBIOTE discovery, ALFRED repair, CYBORG runtime and visual proof)
Date: 2026-10-13
Branch/commit if available: master / pending-finish
Task type: Patch

Files inspected:

- `scenes/combat/CombatScene.gd`
- `scenes/combat/PlayerCombat.gd`
- `scenes/combat/ZoneManager.gd`
- `scenes/dev/DebugBootScene.gd`
- `autoloads/VisualAuditAutoload.gd`
- `tools/capture_audit_frame.gd`
- `docs/ai/REPORT_CONTRACT.md`
- `docs/ai/VISUAL_TRUTH_LOOP.md`

Files changed:

- `scenes/combat/CombatScene.gd`
- `scenes/combat/PlayerCombat.gd`
- `scenes/combat/ZoneManager.gd`
- `scenes/dev/DebugBootScene.gd`
- `_visual_proofs/combat_spatial_contract/`
- `receipts/receipt_20261013_combat_spatial_contract.md`

Validation run: windowed `control_focus` DebugHarness with native F12 `VisualAuditAutoload` capture; headless `debug_harness.bat --debug-control-sequence --debug-autoquit-seconds 2`; all seven `tools/test_*.gd` probes through `tools/godot.ps1 test`; `smoke_project.bat`; `validate_project.bat` including data validation; `git diff --check`.

Validation level: 3

Validation result: PASS — the real CombatScene harness accepted N/E/S/W actions in their requested lanes, produced expected projectile-clearance results, exited successfully, and emitted a factual screenshot/metadata witness. The complete native test suite, headless boot, import/validation, and data validation also passed.

Confirmed repo truth:

- `ZoneManager` owns the timing-field center and uses it to derive cardinal hit zones.
- `PlayerCombat` now starts and moves from that same center rather than the default scene origin.
- Projectile response eligibility spans the visible authored ring without changing melee enemy reach.
- The control harness tests the accepted combat-input signal outcome, avoiding its previous false comparison to facing after a free-movement dodge.
- A failed control step can no longer leave a green process exit merely because the harness printed a failure.

Unverified assumptions:

- No human/device play-feel assessment was performed; a passing debug sequence does not establish controller feel, small-screen readability, or full song-run pressure.
- The visual package proves central placement, not the visual quality of an attack effect at the extreme outer response boundary.
- Godot reported `ObjectDB instances leaked at exit` in the debug-harness runs. It is an existing accepted wrapper warning, but its root cause was not investigated or resolved here.
- The failure-to-exit-1 branch is source-reviewed but was not deliberately induced after the repair.

Recommended next step: use the `reward_preview` harness at a player-visible live reward moment, capture it, and select one evidence-backed performance-payoff/readability repair without restoring pause-era reward flow.

Risks:

- The new projectile intercept range is intentionally tied to current authored timing constants; a future timing-ring radius change should keep this relationship, not hard-code a replacement number.
- Windowed capture was successful once; a later F12 multi-sample attempt did not reach the game window and was excluded from evidence.

## Auditor's Report (v2.5)

- **Task Type**: Patch
- **Blast Radius**: Tier 2
- **Evidence Type**: Runtime-Verified
- **Visual Proof**: `_visual_proofs/combat_spatial_contract/` — native CombatScene screenshot, factual metadata, runtime trace, and constrained readability notes.
- **Self-Critique Results**:
  - [x] Assumption-Busted (Verified Layer 2 Live Truth)
  - [x] Identity Anchor Integrity (Timing/DNA/Beat-Feel)
  - [x] Anti-Sludge (Combat-Clean/HUD-Minimal)
  - [x] GDScript 2.0 Compliance (Typing/Signals/EventBus)
  - [x] Signal Tracing (Emitted AND connected)
  - [x] Null-Safety (@onready/%UniqueName verified)
  - [x] Visual Proof Rule (Screenshots/Logs for visual tasks)
- **Verified Facts**: CombatScene, PlayerCombat, and ZoneManager now consume one center coordinate; the live N/E/S/W harness reaches the requested combat input lanes and reports expected projectile results; the proof image is a successful native capture from CombatScene.
- **Unverified Risks**: manual feel, outer-ring VFX readability, mobile/device behavior, and the root cause of the existing harness shutdown warning remain unproven.
- **Next Bounded Move**: inspect one live performance reward offer in `reward_preview` and repair the most consequential observed payoff/readability defect.

## Self-Upgrade Check

- **Repo Truth Changed**: yes — physical player placement, projectile timing-window eligibility, fresh-profile scene handoff, and harness failure semantics now match the observed combat contract.
- **Player Understanding Changed**: yes — a visible timing response is now anchored to the same physical position and response range that combat resolves.
- **Current Pulse Update Needed**: no — the broad playable-pre-alpha pulse remains accurate; this receipt preserves the narrower recovered truth.
- **Agent Rule Update Needed**: no.
- **New Eval Case Needed**: no — the existing live `control_focus` path now directly exercises and fails on the detected spatial/input drift instead of masking it.
- **Soul / Taste Lesson Learned**: yes — timing readability is a single spatial promise across visuals, input resolution, and target eligibility; repairing only one layer makes combat dishonest.
- **Recommended Doctrine Patch**: none.
- **One-Sentence Learning**: A timing ring is truthful only when its visual center, physical player anchor, and accepted-response range are derived from the same live geometry.
