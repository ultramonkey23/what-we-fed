# AGENT EVOLUTION LOG

Tracks accepted changes to WHAT WE FED AI architecture. This log records architecture governance, not gameplay implementation history.

## 2026-05-04 - AI Architecture Evolution Foundation

**Status:** Accepted foundation pass.

**Changes accepted:**
- Legendary Pixel Fable Ink doctrine sync established as current base art direction for active AI context.
- Bone Ink / Bonecut Ink confirmed as corruption, Blight, Omen, boss, high-pressure, or late-run layer only.
- Visual Proof Rule recorded as active in current doctrine where already present, and preserved as mandatory for visual/demo polish tasks when technically possible.
- `docs/ai/AI_ARCHITECTURE_LEDGER.md` created as compact active AI architecture boundary map.
- `docs/ai/CURRENT_PULSE.md` created as compact current-context file so agents do not need to load massive historical ledgers as active context.
- `docs/ai/evolution_proposals/README.md` created as the controlled proposal gate for future architecture/canon/doc changes.
- Broad doc pruning, archival, and historical-ledger migration were intentionally not performed.

**Approval rule:**
Future architecture or canon changes may be proposed through `docs/ai/evolution_proposals/`, but must not be implemented without explicit human or Command Center approval.

**Validation note:**
This was a documentation-only foundation pass. It did not modify gameplay code, scenes, assets, import settings, EventBus, autoloads, combat systems, rhythm systems, economy systems, or visual systems.

---

## 2026-05-04 — Documentation prune Phase 1

**Status:** Accepted (archive move + entrypoint pointer trim; no gameplay changes).

**Files archived (git mv, not deleted):**
- `docs/CURRENT_REPO_TRUTH_LEDGER.md` → `docs/ai/archive_legacy/truth_history/CURRENT_REPO_TRUTH_LEDGER.md`
- `docs/ai/CURRENT_TRUTH_SNAPSHOT.md` → `docs/ai/archive_legacy/truth_history/CURRENT_TRUTH_SNAPSHOT.md`
- `docs/ai/SOVEREIGN_HANDOFF.md` → `docs/ai/archive_legacy/truth_history/SOVEREIGN_HANDOFF.md`

**Phase 1 plans directory:** `docs/ai/archive_legacy/plans_v1_v2/` created. Listed `*_V1.md` filenames from the audit were **not present** in the repo at execution time (no additional files archived).

**Entrypoints pointer-trimmed:** `AGENTS.md`, `GEMINI.md`, `CLAUDE.md`, `.clinerules` — Trinity-first (`SOVEREIGN_CORE`, `AI_ARCHITECTURE_LEDGER`, `CURRENT_PULSE`); preserved Legendary Pixel Fable Ink, Visual Proof Rule, proposal gate, Auditor's Report / validation honesty.

**Supporting doc path hygiene (non-entrypoint):** `CURRENT_PULSE.md`, `AI_ARCHITECTURE_LEDGER.md`, `REPO_TRUTH_PROTOCOL.md`, `LOCKBOX_REGISTRY.md`, snapshot generator script/workflow, `docs/ai/archive_legacy/README.md`, `docs/ai/archive_legacy/agents/BRAIN.md`, example prompt text, `.claude/skills/score-report/SKILL.md` — updated only where they still pointed at old truth-file locations. **`WHAT_WE_FED_LOCKBOX_REGISTRY_FULL.md` intentionally not edited.**

**Remaining Phase 2+ decisions:** Broad lockbox export / full registry consolidation; Kaiju ascension canon (`docs/THE_HOLLOW_EGG_KAIJU_ASCENSION_CANON.md`) and related scope; any future migration of absent `*_V1.md` plan files when they exist in-tree; optional further entrypoint/cursor-rule deduplication beyond Phase 1 scope.

**Validation note:** Documentation and tooling path updates only. No gameplay code, scenes, assets, import settings, EventBus, autoloads, combat, rhythm, economy, visual, player, enemy, or background systems modified.

---

## 2026-06-19 — archive_legacy retirement + dead-systems prune

**Status:** Accepted (we are beyond demo stage; staged release posture).

**Files retired:**
- `systems/MutationSynergySystem.gd` + `.uid` — fully unreferenced; mutation IDs did not match `data/CombatContent.gd`.
- `systems/EncounterOptimizer.gd` + `.uid` — fully unreferenced; `_initialize_pools` was a no-op and pools had no release path.
- `examples/NewSystemsDemo.gd` + `.uid`, `examples/demo_encounter_stack/CombatSystemIntegration.gd` + `.uid`, `examples/demo_encounter_stack/MutationTracker.gd` + `.uid` — orphan demo entries; `EncounterGenerator.gd` retained for the live `debug_generated_boss_encounter` harness preset.
- `docs/archive_legacy/` (whole directory) and `docs/ai/archive_legacy/` (whole directory, including `truth_history/`, `agents/`, `plans_v1_v2/`, `ROLE_PACKS/`).
- `docs/UPGRADE_IMPLEMENTATION_GUIDE.md` — referenced only the deleted demo stack.
- `tools/generate_snapshot.bat` and `docs/ai/workflows/SNAPSHOT_GENERATOR.md` — wrote to the deleted archive_legacy/truth_history path.

**Entrypoints and tooling pointer-pruned:** `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.clinerules`, `.claude/commands/soul-integrity-check.md`, `tools/ai/check_soul_integrity.py`, `docs/LOCKBOX_REGISTRY.md`, `docs/ai/REPO_TRUTH_PROTOCOL.md`, `docs/ai/AI_ARCHITECTURE_LEDGER.md`, `docs/ai/SIGNAL_MAP.md`, `REPO_SYSTEM_MAP.md` — all archive_legacy and deleted-demo references removed; compact-active-truth flow (CURRENT_PULSE + AI_ARCHITECTURE_LEDGER) is now the only sanctioned ledger surface.

**Validation note:** `smoke_project.bat` SMOKE OK, `validate_project.bat` VALIDATE OK + DATA VALIDATION OK. The only gameplay code touch in this pass was the prior `SovereignDamageCalculator` + `CombatScene` HP-marker cache (committed separately as `12cf0b1`).
