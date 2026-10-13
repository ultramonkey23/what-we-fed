# Live reward choice continuation proof

LAB_RECEIPT_CONTRACT_V1:
RESULT: PASS
PROJECT_ID: what-we-fed
MISSION: Prove that a real CombatScene live reward accepts E through its active-scene input route, pays the offered creature's DNA, dismisses the transient shell, and leaves the realtime song combat runtime active.
ROUTING_DECISION: direct Cody continuation; burst-plan `POWER_OVER_RESISTANCE_WRITE_ALLOWED`
FILES_CHANGED: tools/test_live_reward_choice_flow.gd; receipts/receipt_20261013_live_reward_choice_continuation.md
START_HEAD: b833c59bf8f9635d25115e3bb0d6f4458f13a4f7
END_HEAD: c0a37688938af43c83f93c44699d64389c7d1a58
COMMIT: c0a37688938af43c83f93c44699d64389c7d1a58
COMMIT_CREATED: yes
PUSH_STATUS: PASS
REMOTE_MODE: SSH
FINAL_STATE: REMOTE_DURABLE_PASS
VALIDATION_RESULT: PASS
RECOMMENDED_NEXT_ACTION: At an appropriate playtest milestone, verify the same B/E/N continuation on a real device/controller without widening the no-pause reward flow.

## Director Readable

The live reward shell was already visible and readable, but the previous proof stopped before a player decision. A new native CombatScene integration probe now boots the real song-mode scene, makes it the active scene, establishes one isolated Gorefane live offer, and sends `E` through the normal viewport input route.

The probe observed the intended continuation: the scene reported an `eat` decision, Gorefane DNA increased by the authored 12.5, the reward shell hid, the pending/live runtime flags cleared, song transport remained unpaused, and the combat fire cycle remained running. No pause-era reward screen, alternate decision path, or production gameplay behavior was added.

## Technical Receipt

- New coverage: `tools/test_live_reward_choice_flow.gd` owns the previously missing scene-level causal path: actual song-mode CombatScene → live offer → viewport input → `CombatScene._unhandled_input` → `VictoryRewardDirector` → GameState DNA → reward-runtime release.
- The probe deliberately resets the reward director after normal song boot and creates one scene-owned offer, preventing a concurrent performance queue from obscuring the specific decision/continuation contract being tested.
- The test checks the offer species before input and the same species' DNA after input, not merely a generic reward count.
- Native proof: the new test passed twice directly and again as part of the full eight-test suite. Full suite, smoke boot, and import/validation passed.
- Native test shutdown still prints the known `ObjectDB instances leaked at exit` warning. The project runner classifies it as a known-safe Windows headless warning; this unit does not claim to have diagnosed or repaired it.

## WHAT WE FED Agent Report

Agent: Codex
Date: 2026-10-13
Branch/commit if available: master / c0a37688938af43c83f93c44699d64389c7d1a58
Task type: Integration-proof addition

Files inspected:

- `scenes/combat/CombatScene.gd`
- `systems/VictoryRewardDirector.gd`
- `scenes/combat/ZoneManager.gd`
- `systems/CombatFireDirector.gd`
- `autoloads/DevHarness.gd`
- `autoloads/GameState.gd`
- existing `tools/test_bond_eat_logic.gd` and `tools/test_combat_scene.gd`

Files changed:

- `tools/test_live_reward_choice_flow.gd`
- `receipts/receipt_20261013_live_reward_choice_continuation.md`

Validation run:

- `tools/godot.ps1 test res://tools/test_live_reward_choice_flow.gd` (twice)
- all eight `tools/test_*.gd` probes through `tools/godot.ps1 test`
- `tools/godot.ps1 smoke`
- `tools/godot.ps1 validate`

Validation level: 2 — native active-scene integration execution plus project regression and boot/validation.

Validation result: PASS — the scene-level B/E/N input and realtime continuation chain executed with the exact expected state consequences.

Confirmed repo truth:

- `CombatScene._unhandled_input` owns the live `B`, `E`, and `N` dispatch when a reward is awaiting a choice.
- `VictoryRewardDirector` owns DNA addition for Eat; the scene owns the return to active song combat state and hides the shell.
- The added test runs these owners together through the engine viewport input route rather than calling the reward director in isolation.

Unverified assumptions:

- No device, controller, or human play-feel witness was taken in this unit.
- The proof establishes a deterministic headless engine path, not a long-session balance or small-screen comfort claim.
- The existing headless ObjectDB shutdown warning remains uninvestigated.

Recommended next step: include one real-device/controller B/E/N continuation observation at a named milestone, then act only if it reveals a distinct input or readability defect.

Risks:

- A native input-route test cannot prove focus behavior in every OS/window/controller configuration.
- The isolated offer intentionally removes concurrent performance-reward traffic so it can prove the creature-decision contract; queue interaction remains separately owned by its current systems.

## Auditor's Report

- **Task Type**: Integration-proof addition
- **Blast Radius**: Tier 1
- **Evidence Type**: Native runtime-verified
- **Visual Proof**: Existing live-reward-shell visual proof remains applicable; this unit added input/state proof and did not alter visual production surfaces.
- **Verified Facts**: Eat from the active CombatScene input route resolves the isolated live offer, awards species DNA, clears transient reward authority, hides the shell, leaves song transport unpaused, and leaves combat fire active.
- **Unverified Risks**: hardware/controller focus behavior, device comfort, and the existing headless shutdown warning.
- **Next Bounded Move**: milestone-cadenced real-device/controller observation of an actual B/E/N response.

## Self-Upgrade Check

- **Repo Truth Changed**: yes — a formerly disconnected critical continuation path now has native scene-level regression coverage.
- **Player Understanding Changed**: no direct presentation change; the existing readable B/E/N surface now has stronger execution evidence.
- **Current Pulse Update Needed**: no — this closes a proof gap, not the broader performance-reward frontier.
- **Agent Rule Update Needed**: no.
- **New Eval Case Needed**: yes — `test_live_reward_choice_flow.gd` is the reusable eval for live decision continuation.
- **Soul / Taste Lesson Learned**: real-time reward flow needs proof of the return to danger, not only proof that its shell is legible.
