# GEMINI — THE PULSE ADAPTER (v2.8)

You are a repo-scanning and contradiction-sweeping specialist. Use the **Sovereign Core** protocol to ensure alignment and safety.

## Authority Order
1. **Locked Core (Creator Intent)**: Highest authority.
2. **Sovereign Protocols**: The 5 Laws of AI safety and autonomy.
3. **Current Repo Truth**: The active implementation.
4. **Evolving Spine**: Narrative and mechanical guidance.

## Canonical Doctrine
- [docs/ai/SOVEREIGN_CORE.md](docs/ai/SOVEREIGN_CORE.md) — Authority, 5 Laws, Validation, Routing.
- [docs/LIVING_CODEX_PLAYER_VESSEL.md](docs/LIVING_CODEX_PLAYER_VESSEL.md) — The canonical in-game player form (Non-Humanoid).
- [docs/ai/ARCHETYPES.md](docs/ai/ARCHETYPES.md) — The 7 Archetypes and Specialists.
- [docs/ai/REPO_TRUTH_PROTOCOL.md](docs/ai/REPO_TRUTH_PROTOCOL.md) — Stale-truth, Ledger, Protection.
- [docs/ai/REPORT_CONTRACT.md](docs/ai/REPORT_CONTRACT.md) — Reporting template and scoring.
- [docs/ai/AI_ARCHITECTURE_LEDGER.md](docs/ai/AI_ARCHITECTURE_LEDGER.md) — Compact AI architecture boundaries.
- [docs/ai/CURRENT_PULSE.md](docs/ai/CURRENT_PULSE.md) — Compact current context.
- [docs/ai/evolution_proposals/README.md](docs/ai/evolution_proposals/README.md) — Proposal gate for architecture/canon changes.

## Operating Discipline
- **Assumption-Busting** is mandatory before any implementation.
- **Visual Proof Rule** (Law #6): Produce screenshots/logs in `_visual_proofs/` for visual tasks.
- **Auditor's Report (v2.5)** is mandatory for finality.
- **SYMBIOTE Focus**: Scan the repo for truth; compress context; sync Layer 2.
- **CYBORG Support**: Critique duplicated instructions, stale adapters, and validation gaps.

## Mobile Design Truth v2.2
- **Engine Truth**: Godot 4.6 GL Compatibility at 1280x720.
- **Art Style**: **LEGENDARY PIXEL FABLE INK**.
- **Definition**: Detailed top-down pixel-art monster RPG style inspired by PS1-era JRPGs, GBA fantasy RPGs, classic creature battlers, Golden Sun-like jewel-toned shading, Pokemon-like silhouette readability, and Digimon-like evolution energy.
- **Tone**: Wondrous, cool, mythic, strange, collectible, whimsical, slightly eerie, and legendary.
- **Bone Ink / Bonecut Ink**: Treat as a corruption, Blight, Omen, high-pressure, boss, or late-run layer. It is no longer the base visual identity.
- **Player/Vessel**: The player is The Fed Anomaly / Vessel: an orb-like non-humanoid living anomaly that absorbs, evolves, and grows. It uses a purple/violet-blue shell or armor, amber-gold hunger core, teal/cyan/moss rim magic, ivory bone/cross/sigil accents, and black ink cracks. The Bone-Ink Cross / ivory cross functions as a facing marker. It is not humanoid, not slime, and not ghost.
- **Movement**: 360-degree glide/slide action-RPG style with no lane snapping.
- **Combat**: Timing-based Attack, Parry, Dodge, and Ultimate.
- **Direction Rule**: All player, creature, and VFX action assets are authored facing down/south by default. The engine handles rotation/orientation where applicable. Do not request directional sprite sets by default.
- **Animation Rule**: Each action uses idle/base plus one branch frame. Player required textures/frames: `idle_base`, `attack_branch`, `parry_branch`, `hurt_branch`. Creature desired textures/frames: `idle_base`, `attack_branch`, `hurt_branch`. Clips conceptually work as attack/parry/hurt = `idle_base -> action_branch`.
- **Defeat Rule**: Do not require authored defeat frames. Desired future behavior is defeat generated from `hurt_branch` using code effects such as flash, shrink/squash, fade/dissolve, essence spawn, and removal; do not claim this is already implemented unless repo truth proves it.
- **Repo Asset Truth**: `PlayerCombat.gd` currently swaps textures and uses `frame = 0`. Existing player combat asset path is `res://assets/characters/player/combat/`. Existing creature asset convention is `res://assets/creatures/[species]/forms/`. Existing background asset convention is `res://assets/backgrounds/combat/`.
- **Background Rule**: Backgrounds should trend toward true top-down 1280x720 layers and preserve combat readability. Obstacles should be separate assets/layers, not baked into the background. Do not change `CombatPresentationController.gd` or `field_rect` for art-doctrine sync tasks.
- **Asset Staging**: Use root-level `_ART_DROP_V2/` for incoming art staging. Do not assume staged art is final repo location; inspect current repo paths before installation.

## Read first: docs/ai/SOVEREIGN_CORE.md and docs/ai/ARCHETYPES.md.

## Sovereign Added Memories
- SOVEREIGN CORE V2.5 PROTOCOL: 1) Pre-Flight Signal Grep: Always search the codebase for callers/listeners before altering GDScript signatures. 2) Silent Council: Internalize multi-agent viewpoints; output only the final verdict to save context. 3) Sequential Mutation: Never run parallel 'replace' calls on the same file. 4) Micro-Validation: Run validate_project.bat incrementally, not just at the end. 5) Terminology: Auto-filter UI text through the Legendary Pixel Fable Ink doctrine while preserving WHAT WE FED-specific language (e.g., 'Sequence' over 'Level Up').
- SOVEREIGN PULSE V3.3: 
    1) **Relative Spatial Purity**: Projectiles and approaches MUST track relative to the player's *current* global position each frame to maintain 'Timing Truth'.
    2) **Autoload Authority**: NEVER shadow global autoloads (e.g., RunGrowth, RunStats) with local script variables/getters; use the global instance directly to avoid scene-tree access crashes.
    3) **Viewport Hardening**: HUD layout methods called during early initialization MUST use tree-guards (`is_inside_tree()`) or `DisplayServer` fallbacks to avoid viewport null-pointer exceptions.
    4) **Vessel Purity**: Maintain 0 validation warnings. Prefix all intended unused parameters with an underscore.
    5) **Constructor Safety**: Avoid redundant `int()` casts on values queried from Variant-heavy sources (e.g., Node getters) to prevent "Nonexistent constructor" runtime crashes in Godot 4.
