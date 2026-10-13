# Live reward shell readability repair

LAB_RECEIPT_CONTRACT_V1:
RESULT: PASS
PROJECT_ID: what-we-fed
MISSION: Repair the observed live reward-shell clipping so its existing real-time creature, DNA-gate, and B/E/N decision information is simultaneously readable without replacing song-run flow with a pause-era reward screen.
ROUTING_DECISION: direct Cody continuation; burst-plan `POWER_OVER_RESISTANCE_WRITE_ALLOWED`
FILES_CHANGED: data/CombatFeelContent.gd; systems/CombatPresentationController.gd; _visual_proofs/live_reward_shell_readability/; receipts/receipt_20261013_live_reward_shell_readability.md
START_HEAD: abab2f03dcb8bae5a3f4aa8522927cfb5eaf094d
END_HEAD: pending-finish
COMMIT: pending-finish
VALIDATION_RESULT: PASS
RECOMMENDED_NEXT_ACTION: Exercise one live Bond/Eat response through a reward offer and verify that song pressure resumes without hidden choice state or reward-shell residue.

## Director Readable

The live reward shell existed and received real offer data, but it was only 132×64 pixels while its own mandatory title, context, DNA gate, and decision/timer rows need 92 pixels before margins. With clipping enabled, the player could see a creature name and lore fragment but not consistently see whether Bond was affordable or which B/E/N response remained.

The shell is now 224×112, with a compact vertical allocation designed for the four owned lines. The after capture visibly carries creature identity, one-line context, `BOND DNA 0/10`, and `BOND LOCKED | E/N | 4s` together in the existing lower-right transient lane. This preserves the live three-second decision shape; no full-screen reward overlay, new menu, or pause-era growth flow was introduced.

The performance offer is explicitly restored to its own authored compact size and stack position when the creature shell is absent, so enlarging one transient owner cannot silently enlarge another.

## Technical Receipt

- Initial visual evidence: the windowed `reward_preview` harness produced a valid `CombatScene` F12 capture in which the 132×64 live offer showed only the creature heading and a clipped body fragment. Its DNA gate and B/E/N/timer rows were outside the clipped shell.
- Source diagnosis: the shell had four rows with 22 + 22 + 18 + 18 minimum heights, three 4-pixel gaps, and top/bottom safe margins inside a 64-pixel clipped panel. This is an implementation geometry fault, not evidence that live rewards lack player value.
- `CombatFeelContent` now derives a 224×112 live shell. `CombatPresentationController` gives the identity, two-line compact body, DNA gate, and timed-choice labels 20/30/16/16 pixel allocations with 2-pixel separation.
- `center_performance_offer_shell()` now uses `compact_performance_offer_size()` and its dedicated stack-position function rather than borrowing the enlarged live-offer geometry.
- After visual evidence: native `VisualAuditAutoload` capture from `CombatScene` at 1280×720 (`png_error: 0`) visibly shows all four decision lines in the same lower-right live shell. Before/after images and factual capture metadata are preserved together.
- The full native regression suite, smoke boot, import/validation, and data validation passed after the presentation change.
- The visual-audit retention routine was allowed to run during validation. Exact tracked snapshots it removed were restored before closeout; generated proof-image `.import` caches are intentionally excluded.

## WHAT WE FED Agent Report

Agent: Codex (SYMBIOTE visual diagnosis, ALFRED presentation repair, CYBORG runtime proof)
Date: 2026-10-13
Branch/commit if available: master / pending-finish
Task type: Patch

Files inspected:

- `docs/ai/CURRENT_PULSE.md`
- `docs/NEXT_PHASE_PLAN.md`
- `scenes/combat/CombatScene.gd`
- `systems/VictoryRewardDirector.gd`
- `systems/PerformanceRewardDirector.gd`
- `data/CombatFeelContent.gd`
- `systems/CombatPresentationController.gd`
- `data/PresentationTextContent.gd`
- `docs/ai/REPORT_CONTRACT.md`
- `docs/ai/VISUAL_TRUTH_LOOP.md`

Files changed:

- `data/CombatFeelContent.gd`
- `systems/CombatPresentationController.gd`
- `_visual_proofs/live_reward_shell_readability/`
- `receipts/receipt_20261013_live_reward_shell_readability.md`

Validation run: windowed `reward_preview` DebugHarness with native F12 captures before and after; all seven `tools/test_*.gd` probes through `tools/godot.ps1 test`; `smoke_project.bat`; `validate_project.bat` including data validation; `git diff --check`.

Validation level: 3

Validation result: PASS — the live reward surface was observed in its actual CombatScene body before and after the repair, the after frame contains the complete decision contract, and the complete native suite plus project/data validation passed.

Confirmed repo truth:

- The live reward shell is a persistent `CombatPresentationController` owner fed by `CombatScene` and `VictoryRewardDirector`; it is not a missing UI path.
- Its old dimensions could not contain its own title, body, DNA, and response/timer rows after margins and clipping.
- The repaired shell visibly exposes creature identity, compact context, DNA availability, and B/E/N timing together while remaining in the live lower-right combat lane.
- The independent performance-offer shell retains its own authored geometry when the live creature offer is not active.

Unverified assumptions:

- The after preview rendered a GORE FANE runtime offer rather than the preset's nominal Knellspine seed. The visual proof establishes active-shell legibility, not deterministic preview-species selection.
- No manual device/small-screen review, Bond/Eat resolution, or song-pressure-resume observation was performed in this unit.
- The debug run still reports existing `ObjectDB instances leaked at exit` and one resource still in use; neither warning was diagnosed or claimed fixed.

Recommended next step: respond to a live creature offer with Bond or Eat under the debug harness, observe the immediate feedback and song-pressure rehydration, and repair only a reproduced continuation fault.

Risks:

- The larger shell occupies more lower-right playfield during its short offer window; the after witness proves content legibility but not long-session/controller comfort.
- The body remains intentionally compact; extended creature lore belongs to management surfaces, not the live timing window.

## Auditor's Report (v2.5)

- **Task Type**: Patch
- **Blast Radius**: Tier 1
- **Evidence Type**: Runtime-Verified
- **Visual Proof**: `_visual_proofs/live_reward_shell_readability/` — native before/after CombatScene captures, factual metadata, runtime trace, and constrained visual notes.
- **Self-Critique Results**:
  - [x] Assumption-Busted (Verified Layer 2 Live Truth)
  - [x] Identity Anchor Integrity (Timing/DNA/Beat-Feel)
  - [x] Anti-Sludge (Combat-Clean/HUD-Minimal)
  - [x] GDScript 2.0 Compliance (Typing/Signals/EventBus)
  - [x] Signal Tracing (Emitted AND connected)
  - [x] Null-Safety (@onready/%UniqueName verified)
  - [x] Visual Proof Rule (Screenshots/Logs for visual tasks)
- **Verified Facts**: the live shell's required content now fits in its clipped bounds, its player-facing capture contains all four decision lines, and the separate performance surface no longer inherits live-offer geometry.
- **Unverified Risks**: preview determinism, Bond/Eat continuation, device comfort, and the existing debug-shutdown warning remain unproven.
- **Next Bounded Move**: exercise one live Bond/Eat choice through song-pressure resume and inspect the actual continuation surface.

## Self-Upgrade Check

- **Repo Truth Changed**: yes — the current live reward shell now exposes its complete short-window decision contract without a flow rewrite.
- **Player Understanding Changed**: yes — the player can now see what creature is offered, whether Bond is available, and how much time/which response remains before acting.
- **Current Pulse Update Needed**: no — reward clarity remains an active broader frontier; this repair closes one demonstrated clipping defect rather than the full gap.
- **Agent Rule Update Needed**: no.
- **New Eval Case Needed**: no — the existing `reward_preview` body plus retained before/after visual proof now covers the discovered layout contract.
- **Soul / Taste Lesson Learned**: yes — live reward readability is not more text or a larger menu; it is making the irreversible Bond/Eat decision legible inside the existing pressure window.
- **Recommended Doctrine Patch**: none.
- **One-Sentence Learning**: A live reward can preserve urgency only if its creature, cost, and available response fit together in the same visible moment.
