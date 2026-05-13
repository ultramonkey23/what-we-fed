---
applyTo: "**"
---

# WHAT WE FED — Copilot Adapter (v2.3)

Creator authority comes first:
1. User / creator intent
2. Current repo truth
3. Current live-build truth
4. Evolving spine
5. Older canon / source docs

Default read order (Trinity):
1. `docs/ai/SOVEREIGN_CORE.md` — laws, routing, validation posture
2. `docs/ai/AI_ARCHITECTURE_LEDGER.md` — architecture boundaries, spatial combat authority
3. `docs/ai/CURRENT_PULSE.md` — compact active truth

Then `AGENTS.md` for lead-lane routing and
`docs/ai/LIVING_COMMAND_LOOP.md` for post-task self-upgrade.

## Non-negotiables
- Player is The Fed Anomaly / Vessel: non-humanoid, orb-like, feeding/bonding/mutating. Not a humanoid, slime, or ghost.
- Combat is 360-degree spatial action. Not strict lane combat.
- Base art style is Legendary Pixel Fable Ink. Not "Premium Menace."
- Quig references the creator as "the monkeydog." Never by real name.
- ZoneManager owns spatial authority (`scenes/combat/ZoneManager.gd`). `LaneManager.gd` retained for Godot UID safety only.
- GDScript must be statically typed. All arrays `Array[Type]`. Signals use `StringName`.

## Role lanes
- **BRAIN**: architecture, authority conflicts, multi-system planning.
- **ALFRED/Surgeon**: bounded implementation. One file. One objective.
- **SYMBIOTE/Scout**: repo truth discovery before implementation.
- **INSPECTOR**: visual proof, HUD readability, art-doctrine audit.

## Guardrails (Preserve Always)
- Timing truth (SongConductor.gd is the beat clock — do not bypass it).
- Spatial threat readability (sector clarity, not fixed-lane assumptions).
- Support readability and combat honesty.
- No-pause active combat; intentional between-level management.
- Fantasy spine: start weak, become feared (Bond/Eat, DNA economy, run variety).

## Reporting Contract
Follow the **Auditor’s Report (v2.5)** defined in `docs/ai/REPORT_CONTRACT.md`.
Include the **Self-Upgrade Check** block after every substantial task.
Do not claim visual validation without screenshot/capture evidence or an Inspector receipt.
Run `tools/ai/check_soul_integrity.py` if active AI docs were modified.
