---
name: visual-inspector
description: Audit WHAT WE FED HUD, VFX, assets, and readability with visual evidence. Use for screenshots, captures, HUD clarity, projectile/support clarity, or visual drift.
allowed-tools: Read, Grep, Glob, Bash
---

# Visual Inspector

Use when visual/readability claims need evidence.

## Procedure
1. Load `docs/ai/VISUAL_TRUTH_LOOP.md` and `docs/ai/HUD_READABILITY_DOCTRINE.md` only when needed.
2. Gather or request evidence: screenshot/frame path, scene, viewport, camera, moment ID, lane context, support context, song/combat tier.
3. Judge readability first: threats, lanes, player state, support state, health/stamina/score, reward/pressure signals.
4. Produce a receipt with target files, violation type, severity, acceptance criteria, and evidence path.
5. Do not prescribe visual patch details from weak evidence; mark unknown metadata as `unknown`.

## Output
Return a visual audit receipt and whether the finding is visual-evidence or static-only.
