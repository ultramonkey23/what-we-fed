# AGENT ROUTING MATRIX
Quick lookup for routing repo work to the right agent. Read before assigning any task.

Full operating rules: `docs/ai/AI_CONTROL_PLANE.md`

---

| Task Category | Correct Agent | Allowed Work | Forbidden Work | Required Evidence | Report Required |
|---|---|---|---|---|---|
| **Fresh repo audit** | Gemini (SYMBIOTE) | Read any file, map dependencies, identify conflicts | Edit files, claim runtime truth without run | None needed to start | Yes — list files read, conflicts found, recommended next |
| **Static architecture diagnosis** | Gemini or Claude (BRAIN) | Inspect structure, identify risks, propose bounded options | Implement without approval, speculate as truth | Inspected files list | Yes — include unverified assumptions |
| **Runtime validation plan** | Claude or Codex (CYBORG) | Write validation steps, identify test commands | Claim validation occurred before it runs | Current repo state (fresh audit or git status) | Yes — include validation ladder level |
| **Manual playtest checklist** | Human | Play the build, note feel/bugs/readability | Trust static docs alone for feel judgment | Runnable build | Yes — use `HUMAN_PLAYTEST_PROTOCOL.md` template |
| **Bug fix** | Codex (ALFRED/CYBORG) | Fix the named issue in named files | Touch unrelated systems, rename APIs | Reproduced bug evidence | Yes — include validation level and result |
| **Cleanup** | Codex or Claude (ALFRED) | Remove dead code, fix style, tighten types | Rename exported signals, change scene wiring | Inspected file list | Yes |
| **Complex feature implementation** | Claude (ALFRED + BRAIN) | Implement across multiple files with integration | Broad refactor, skip report, claim feel from static | Fresh audit OR inspected files + changed files list | Yes — mandatory |
| **Combat refactor** | Human approval required first | Bounded change to one named function/signal | Any broad rewrite of CombatScene.gd, PlayerCombat.gd, LaneManager.gd, SongConductor.gd | Fresh audit + human green-light | Yes — include stale-truth check |
| **Documentation update** | Claude or Gemini | Update named doc to match current repo truth | Invent implementation facts, add gameplay speculation | Current repo state to validate claims | Yes — brief |
| **Prompt/system upgrade** | Claude (CYBORG) | Edit docs/ai files, improve routing/report/validation | Edit gameplay, scenes, scripts, data, or project.godot | Inspected existing AI docs | Yes |
| **Lockbox/game-design task** | Command Center v1 | Manage design tasks, priorities, content direction | Be converted into repo implementation without a handoff | N/A — handled outside repo agents | N/A unless converted to implementation handoff |
| **Lockbox interface / conversion** | Command Center v1 owns decision; Gemini audits; Claude/Codex implement only after handoff | Audit fit, produce handoff, validate completion | Change Lockbox status/canon/priority without Command Center v1; treat design intent as repo truth | Current repo truth, card status, files inspected, validation plan, scored report | Yes |

---

## Combat Refactor Warning
The following files are fragile. Any task that touches them requires:
1. A fresh audit from Gemini first.
2. Explicit human approval of scope.
3. One bounded change at a time.
4. Validation at Level 3 or higher.

**Fragile files:** `CombatScene.gd`, `PlayerCombat.gd`, `LaneManager.gd`, `GameState.gd`, `SongConductor.gd`, `CombatContent.gd`

---

## Lockbox/Game-Design Task Conversion
A Lockbox task becomes a repo task only when all of the following are true:
- The design is confirmed (not speculative).
- Repo truth for the affected system has been inspected.
- The implementation scope is bounded and named.
- Validation requirements are explicit.
- An agent report is required at the end.

Without these, keep it in Command Center v1.
