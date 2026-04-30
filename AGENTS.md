# AGENTS — WHAT WE FED (v2.8)

This is the canonical roster and protocol entrypoint for all AI Agents.

## Project Soul
- **Identity**: You are the **Living Codex**, an invasive system extracting patterns.
- **Art Style**: **LEGENDARY PIXEL FABLE INK**.
- **Tone**: Wondrous, cool, mythic, strange, collectible, whimsical, slightly eerie, and legendary.
- **Combat**: 360-degree Action-RPG beat-feel. No lane-snapping.
- **Economy**: DNA is species-specific predation currency. Bond vs Eat.
- **Goal**: Start weak, become feared.

## Mobile Design Truth v2.2
- **Engine Truth**: Godot 4.6 GL Compatibility at 1280x720.
- **Style Definition**: LEGENDARY PIXEL FABLE INK is a detailed top-down pixel-art monster RPG style inspired by PS1-era JRPGs, GBA fantasy RPGs, classic creature battlers, Golden Sun-like jewel-toned shading, Pokemon-like silhouette readability, and Digimon-like evolution energy.
- **Bone Ink / Bonecut Ink**: This is a corruption, Blight, Omen, high-pressure, boss, or late-run layer. It is not the default visual identity.
- **Player Truth**: The player is The Fed Anomaly / Vessel: an orb-like non-humanoid living anomaly that absorbs, evolves, and grows. It has a purple/violet-blue shell or armor, an amber-gold hunger core, teal/cyan/moss rim magic, ivory bone/cross/sigil accents, and black ink cracks. The Bone-Ink Cross / ivory cross is a facing marker. It is not humanoid, not slime, and not ghost.
- **Movement Truth**: 360-degree glide/slide action-RPG movement with no lane snapping.
- **Combat Truth**: Timing-based Attack, Parry, Dodge, and Ultimate.
- **Authoring Direction**: All player, creature, and VFX action assets are authored facing down/south by default. The engine handles rotation/orientation where applicable. Do not request directional sprite sets by default.
- **Animation Rule**: Each action uses idle/base plus one branch frame. Player required textures/frames are `idle_base`, `attack_branch`, `parry_branch`, and `hurt_branch`. Creature desired textures/frames are `idle_base`, `attack_branch`, and `hurt_branch`. Clips conceptually work as `idle_base -> *_branch`.
- **Defeat Rule**: Do not require authored defeat frames. Desired future behavior is defeat generated from `hurt_branch` using code effects such as flash, shrink/squash, fade/dissolve, essence spawn, and removal; do not claim this is implemented unless repo truth proves it.
- **Current Asset Truth**: `PlayerCombat.gd` currently swaps textures and uses `frame = 0`. Existing player combat assets live under `res://assets/characters/player/combat/`; creature forms use `res://assets/creatures/[species]/forms/`; combat backgrounds use `res://assets/backgrounds/combat/`.
- **Background Rule**: Backgrounds should trend toward true top-down 1280x720 background layers that preserve combat readability. Obstacles should be separate assets/layers, not baked into the background. Do not change `CombatPresentationController.gd` or `field_rect` unless a task explicitly requires it.
- **Art Staging**: Use root-level `_ART_DROP_V2/` as staging for incoming art. Staged art is not final repo placement; inspect current repo paths before installation.

## THE SOVEREIGN CORE (Mandatory)
All agents MUST follow the **Sovereign Core** protocol:
1. **Pre-Flight Signal Grep**
2. **The Silent Council**
3. **Strict Sequential Mutation**
4. **Micro-Validation**
5. **Legendary Pixel Fable Ink Filter**

## Canonical Doctrine
- [docs/ai/SOVEREIGN_CORE.md](docs/ai/SOVEREIGN_CORE.md) — Authority, 5 Laws, Validation, Routing.
- [docs/LIVING_CODEX_PLAYER_VESSEL.md](docs/LIVING_CODEX_PLAYER_VESSEL.md) — The canonical in-game player form (Non-Humanoid).
- [docs/ai/ARCHETYPES.md](docs/ai/ARCHETYPES.md) — The 7 Archetypes and Specialists.
- [docs/ai/REPO_TRUTH_PROTOCOL.md](docs/ai/REPO_TRUTH_PROTOCOL.md) — Stale-truth, Ledger, Protection.
- [docs/ai/REPORT_CONTRACT.md](docs/ai/REPORT_CONTRACT.md) — Reporting template and scoring.

## The Specialist Squad
- **SIGNAL** (Vibe Coder)
- **BRAIN** (Architect)
- **AUDITOR** (Cyborg)
- **SURGEON** (Alfred)
- **VISUALS** (Inspector)
- **VOID** (Crash Hunter)
- **SCOUT** (Symbiote)

*See ARCHETYPES.md for full descriptions and pointers.*
