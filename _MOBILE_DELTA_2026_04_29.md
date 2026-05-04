WHAT WE FED — MOBILE DELTA

Context:
Since 10 a.m. today, project direction evolved in ChatGPT mobile. Repo may not yet reflect this.

New current design truth:

1. Art style is now LEGENDARY PIXEL FABLE INK.
Detailed top-down pixel-art monster RPG style with PS1-era JRPG, GBA fantasy RPG, creature battler, Golden Sun, Pokémon, and Digimon influence.

2. Old brutal grimdark is not the default.
Bonecut/horror becomes corruption, late-run, high-pressure, or Blight/Omen treatment.

3. Player is The Fed Anomaly.
Orb-like living anomaly. Absorbs, evolves, grows.
Purple/violet-blue shell, amber-gold hunger core, teal/moss rim magic, ivory bone accents, black ink cracks, Bone-Ink Cross Sigil facing marker.

4. Direction rule:
All action sprites and VFX are authored facing down/south by default.
Engine handles rotation where applicable.
No directional sprite sets by default.

5. Animation rule:
Each action uses idle/base + one branch frame.
Not two unique action frames.

Player frames:
- idle_base
- attack_branch
- parry_branch
- hurt_branch

Creature frames:
- idle_base
- attack_branch
- hurt_branch

6. No authored creature defeat frame.
Defeat is code-generated from hurt_branch using flash, squash/shrink, fade/dissolve, essence spawn, and removal.

7. Background rule:
Backgrounds are 1280x720 true top-down background layers.
Walkable-looking combat plane.
No baked obstacles.
No HUD clutter.
Obstacles are separate assets/layers.

8. Asset staging:
Use neutral root-level art drop folders like _ART_DROP_V2/.
Do not assume final repo asset paths.
Agents must inspect repo structure first.

9. Current priority:
Sync docs/canon first, then install one safe asset batch.
