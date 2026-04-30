# LIVING CODEX: THE PLAYER VESSEL (V1.1)

## 1. CANON STATUS
**IMPLEMENTED IN-GAME.**
This document describes the *actual, current* in-game player sprite. It is **NOT** concept art or a placeholder. All future AI agents, art passes, animations, VFX, UI elements, and story beats **MUST** align with this specific visual form. Do not generate or assume a humanoid protagonist.

## 2. FILE PATHS & REFERENCES
- **Implemented Sprite Paths:**
  - `res://assets/characters/player/combat/player_idle.png`
  - `res://assets/characters/player/combat/player_attack.png`
  - `res://assets/characters/player/combat/player_parry.png`
  - `res://assets/characters/player/combat/player_hurt.png`
- **Script Reference:** `res://scenes/combat/PlayerCombat.gd`
- **Combat Asset Root:** `res://assets/characters/player/combat/`
- **Current Implementation Note:** `PlayerCombat.gd` currently swaps textures and uses `frame = 0`.

## 3. VISUAL IDENTITY & SHAPE LANGUAGE
- **The Form**: The player is The Fed Anomaly / Vessel: an orb-like non-humanoid living anomaly that absorbs, evolves, and grows.
- **Shape Language**: A round, segmented, heavy armature.
- **Color & Texture**:
  - **Outer Shell**: Purple/violet-blue segmented shell or armor.
  - **Inner Core**: A glowing amber-gold hunger core.
  - **Focus**: A central ivory bone/cross/sigil shape spanning the core. The Bone-Ink Cross / ivory cross functions as a facing marker.
  - **Energy**: Teal, cyan, or moss rim magic bordering the structure.
  - **Surface Stress**: Black ink cracks may imply pressure, hunger, or corruption.
- **Readability**: The sprite features a heavy, thick outline to ensure high contrast and immediate readability in a chaotic combat field.
- **Not This**: The Vessel is not humanoid, not slime, and not ghost.
- **Base Art Style**: LEGENDARY PIXEL FABLE INK: detailed top-down pixel-art monster RPG style inspired by PS1-era JRPGs, GBA fantasy RPGs, classic creature battlers, Golden Sun-like jewel-toned shading, Pokemon-like silhouette readability, and Digimon-like evolution energy.
- **Tone**: Wondrous, cool, mythic, strange, collectible, whimsical, slightly eerie, and legendary.
- **Corruption Layer**: Bone Ink / Bonecut Ink belongs to corruption, Blight, Omen, high-pressure, boss, or late-run states. It is not the default visual identity.

## 4. GAMEPLAY FUNCTION & MOVEMENT
- **Movement Rules**: The Vessel does not walk. Movement must feel like a heavy, compact object gliding, sliding, or rolling across the field.
- **Movement Truth**: Combat movement is 360-degree glide/slide action-RPG movement with no lane snapping.
- **Dodge Roll Rules**: Dodging should read as a physical shell roll, spin, or burst of momentum. No humanoid tumbling.
- **Hitbox/Collision Guidance**: The hitbox aligns with the dense, round outer shell. The ivory cross is the absolute center of mass.

## 5. COMBAT & VFX RULES
- **Attack/VFX Rules**: All energy blasts, strikes, and offensive VFX must visually originate from the glowing orange core or the central ivory cross focus. Energy-blast visuals must strictly match actual hit logic and boundaries.
- **Hurt/Damage Rules**: Damage responses should manifest as the purple shell fracturing, the cyan rim flickering, or the orange core dimming. 
- **Scale/Readability Rules**: The Vessel must remain a compact, highly visible focal point inside the timing sigil. Do not obscure the core shape with excessive particle noise.
- **Direction Rule**: All player, creature, and VFX action assets are authored facing down/south by default. The engine handles rotation/orientation where applicable. Do not request directional sprite sets by default.
- **Animation Rule**: Each action uses idle/base plus one branch frame. Player required textures/frames are `idle_base`, `attack_branch`, `parry_branch`, and `hurt_branch`. Clips conceptually work as attack/parry/hurt = `idle_base -> action_branch`.
- **Defeat Rule**: Do not require authored defeat frames. Desired future behavior is defeat generated from `hurt_branch` using code effects such as flash, shrink/squash, fade/dissolve, essence spawn, and removal; do not claim this is already implemented unless repo truth proves it.

## 6. REWARD ECOLOGY RESPONSES
- **Bond Response**: Visual and audio feedback should suggest the Vessel is providing shelter, enforcing a pact, or forming a sacred connection.
- **Eat Response**: Feedback must suggest hunger, violent absorption, or dark mutation as the Vessel consumes lineage.
- **Level/EXP Response**: Growth should visually pulse through the ivory core, into the purple shell, and finally flare along the cyan rim.

## 7. STORY FUNCTION
The player is an **Admitted Outsider**—a real-world consciousness translated through the "game" interface into this biomechanical DNA archive. You are a foreign mind piloting an invasive, non-native feeding idol. You are not a hero; you are a sequence-bearer harvesting the world to sustain your own re-instantiation.

## 8. AI ASSET-GENERATION & CODE-AGENT RULES

### Generation Prompt (For New Assets)
*"Top-down 2D pixel-art game sprite authored facing down/south by default. The Fed Anomaly / Vessel: orb-like non-humanoid living anomaly with a purple/violet-blue segmented shell or armor, amber-gold hunger core, teal/cyan/moss rim magic, ivory bone/cross/sigil facing marker, and black ink cracks. Legendary Pixel Fable Ink style: detailed top-down monster RPG readability, jewel-toned shading, collectible creature silhouette, mythic evolution energy. No legs, no arms, no face, not humanoid, not slime, not ghost."*

### Negative Prompt / Avoid List
*"Humanoid, human, face, eyes, arms, legs, bipedal, walking, sword, generic RPG hero, realistic, soft shading, low contrast, messy particles."*

### Do-Not-Do List (Code Agents)
- **DO NOT** edit the player's collision shape to fit a humanoid aspect ratio.
- **DO NOT** add "walking" or "running" state animations—use "gliding" or "spinning."
- **DO NOT** generate UI icons depicting a human head or body for the player.
- **DO NOT** write narrative text that references the player's hands, feet, or human physiology.
- **DO NOT** obscure the ivory cross focus during combat; it is the visual anchor for Timing Truth.
- **DO NOT** request directional player sprite sets by default.
- **DO NOT** require authored defeat frames.
