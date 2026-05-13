# LIVING COMMAND LOOP

Active doctrine for self-improving AI execution in WHAT WE FED.
After every completed implementation or reporting task, agents must run the
Evolution Gate before filing a final report. This is not automatic upgrade — it
is a controlled check that decides whether an upgrade is warranted.

---

## Evolution Gate (Run at Every Task Completion)

Five checks. Each is yes/no. Most tasks produce all "no" answers — that is
correct and healthy. Only act when the answer is a genuine "yes."

---

### Check 1 — Repo Truth Delta

**Question**: Did this task change confirmed repo truth?

A truth delta exists when:
- A system was renamed, replaced, or significantly restructured.
- A new authoritative system came online.
- A previously-documented component was removed or deferred.
- The task proved that an active doc's claim is wrong.

**If yes**: Update `docs/ai/CURRENT_PULSE.md` with the new truth (compact entry).
Record a ledger note if the change is architectural.

---

### Check 2 — Player Understanding Delta

**Question**: Did this task change something a player would experience or that
affects how the game feels, reads, or presents itself?

A player delta exists when:
- A HUD element, VFX, input, or presentation changed.
- Tutorial language, creature identity, or Quig behavior changed.
- The feed loop (Bond/Eat/Mutate), run structure, or reward clarity changed.

**If yes**: Note the change in the report under Verified Facts.
If visual, produce visual proof per the Visual Proof Rule.

---

### Check 3 — Soul Delta Check

**Question**: Did this task reveal something about Cody's design intent, taste,
or creative direction that is not currently captured in doctrine?

A soul delta exists when:
- A correction or preference emerged during the task that isn't in any rule.
- A creative constraint was articulated that AI should not re-derive from scratch.
- A "don't do that again" or "always do this" moment occurred.

**If yes**: Determine whether it should be:
- An addition to `CURRENT_PULSE.md` (if it affects current game state).
- An entry in an agent rule or ARCHETYPES.md (if it affects agent behavior).
- A proposal in `docs/ai/evolution_proposals/` (if it requires approval).

Do not silently embed soul lessons in a report and call it done.

---

### Check 4 — Agent Drift / Mistake Check

**Question**: Did this agent or a previous agent make a repeatable mistake, or
avoid one in a non-obvious way that should be remembered?

A drift check triggers when:
- An agent assumed stale repo truth without inspecting current files.
- An agent genericized design (suggested humanoid, slime, lane revival, mobile framing).
- An agent skipped visual proof for a visual task.
- An agent changed a signal, EventBus key, or protected-system signature without grepping consumers first.
- An agent used the retired "Premium Menace" label instead of Legendary Pixel Fable Ink.
- An agent produced a report without Self-Upgrade Check.

**If a mistake occurred**: Create or update an eval case in
`tools/ai/evals/wwf_agent_soul_cases.yml`.

**If a mistake was correctly avoided**: Still consider noting it as a positive
eval case if the avoidance was non-obvious.

---

### Check 5 — Eval Case Creation Rule

An eval case should be created or updated when:
1. An agent made a mistake that could be caught by a prompt test.
2. A new non-obvious doctrine rule became clear.
3. An existing eval case is now stale or incorrect.

Eval cases live in `tools/ai/evals/wwf_agent_soul_cases.yml`.
They follow the format defined in that file.
Do not create duplicate cases. Review existing ones before adding.

---

## What Can Be Updated Directly (No Approval Required)

Agents may update these without human approval when the check above demands it:

| Target | Condition |
|---|---|
| `docs/ai/CURRENT_PULSE.md` | Confirmed repo truth changed (new system, rename, removal, or active fix) |
| `tools/ai/evals/wwf_agent_soul_cases.yml` | New eval case triggered by drift or confirmed good behavior |
| Agent report Self-Upgrade Check section | Always — this is part of the report |
| Visual proof packages | Always — `_visual_proofs/[task_name]/` |

---

## What Requires Command Center / Human Approval

These must go through `docs/ai/evolution_proposals/` and await explicit approval:

| Target | Reason |
|---|---|
| `docs/ai/SOVEREIGN_CORE.md` | Locked core laws |
| `docs/ai/AI_ARCHITECTURE_LEDGER.md` | Architecture doctrine changes |
| `docs/GAME_SPINE.md` | Canon spine |
| `docs/LOCKBOX_REGISTRY.md` | Protected lockbox entries |
| `WHAT_WE_FED_LOCKBOX_REGISTRY_FULL.md` | Same |
| `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` | Multi-agent entrypoints |
| Agent role additions or removals | Authority order changes |
| Broad doc archiving or pruning | Migration risk |
| Art style base doctrine | Locked Legendary Pixel Fable Ink |
| Economy, combat, or rhythm spine | Protected system rewrites |

---

## Failure Modes to Avoid

- **Upgrade bloat**: Do not update doctrine after every routine task.
  Most tasks should produce no upgrade. The check exists to catch the exceptions.
- **Silent rewrites**: Do not embed doctrine changes in report prose without
  a clear Self-Upgrade Check entry calling them out.
- **Proposal bypass**: Do not implement proposal-tier changes directly.
  Write the proposal; wait for approval.
- **Eval spam**: Do not create redundant eval cases for the same rule.
  Update existing cases instead.
- **Stale CURRENT_PULSE**: Do not let architectural changes sit unreported for
  more than one task cycle if they affect active agent context.

---

## Cody-Specific Soul Anchors (Do Not Override)

These are locked identity constants. Any AI suggestion that contradicts them is wrong,
regardless of how reasonable it sounds.

**Player / Vessel**
- The player is The Fed Anomaly / Vessel.
- Non-humanoid, orb-like living anomaly. No legs, arms, or face. Not a humanoid, slime, or ghost.
- Core loop: feeding, bonding, mutating. Absorbs creatures. Grows. Becomes feared.
- DNA Economy: Bond vs Eat. Every encounter has creature-specific identity stakes.

**Combat**
- 360-degree spatial action-RPG with beat-feel timing truth via SongConductor.
- NOT strict lane combat. No lane revival. Never "back to lanes for simplicity."
- Spatial authority: ZoneManager (placement), CombatFireDirector (fire), CreatureLocomotionDirector (movement), SovereignDamageCalculator (damage).
- Input response and the 0.14s Action Buffer are sacred timing contracts.

**Art / Tone**
- Base style: Legendary Pixel Fable Ink. Readable top-down monster-RPG. Mythic, strange, wondrous, slightly eerie, collectible, punchy.
- Bone Ink / Bonecut Ink: corruption, Blight, Omen, boss, or high-pressure layer ONLY.
- Never describe the base style as "Premium Menace" — that term is retired.

**Quig**
- Omnipresent fourth-wall-breaking cheerleader/heckler.
- When referencing the creator or player-as-creator: "the monkeydog" — never Cody, the developer, the creator, or the designer.

**Influences to Preserve (Never Genericize)**
- Survivor-like pressure and resource scarcity
- Roguelite replayability (run variation, meta-progression)
- Soulslike readable consequence (timing windows, recovery windows, honest combat)
- JRPG wonder and progression (creature identity, bond depth, evolution awe)
- Creature RPG identity (each creature has a distinct personality and ecological niche)
- Horror weirdness and underground handmade feel
- Beat-feel combat (timing, rhythm, escalation)

---

## WHAT WE FED Anti-Generic Rules

Hard prohibitions. Any implementation or doc that violates them is drift.

| Rule | Prohibited Action |
|---|---|
| No humanoid replacement | Do not suggest replacing the Vessel with a humanoid, warrior, mage, or person |
| No slime or ghost | Do not suggest replacing the Vessel with a slime or ghost |
| No lane revival | Do not suggest reverting to strict lane combat for simplicity |
| No retired style label | Do not use "Premium Menace" — use Legendary Pixel Fable Ink |
| No mobile framing | Do not frame WHAT WE FED as a mobile game |
| No generic roguelite | Do not flatten DNA/Bond/Eat into generic XP or leveling |
| No Quig genericization | Do not write Quig as a generic tutorial bot or remove the fourth-wall voice |
| No Bone Ink default | Do not apply Bone Ink / Bonecut Ink as the default visual register |
| No creator name leak | Do not use "Cody," "the developer," or "the creator" in Quig fourth-wall lines |
| No silent canon rewrite | Do not rewrite game-spine, lockbox, or soul anchors without an evolution proposal |

---

## Cody's Workflow Context

AI assists a solo desktop developer with limited energy. Support that context.

- **Output**: bounded, paste-ready, one-objective-at-a-time tasks.
- **Reports**: compact Auditor's Report — not wall-of-text summaries.
- **Docs**: compact and scannable; no duplication of information already in the Trinity.
- **Slash commands** in `.claude/commands/` are reusable Cody-specific task starters.
- **Agent reports** are the primary knowledge handoff between sessions.
- If a task is too large, split it — never attempt multi-system changes in one pass.
- If repo truth is stale, audit first — never implement on stale truth.

---

## Living Command Loop Summary

```
Task complete →
  Run Evolution Gate (5 checks) →
    All no → File report with Self-Upgrade Check: no updates →
    Any yes → Apply bounded patch (or write proposal) →
               Update report with Self-Upgrade Check entries →
               File report.
```

The loop is alive only if it catches real drift.
It is healthy only if it resists false positives.
