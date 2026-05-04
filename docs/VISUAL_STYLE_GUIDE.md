# WHAT WE FED - VISUAL STYLE GUIDE

## Purpose
This guide defines the active visual direction for "What We Fed" art upgrades, ensuring assets stay readable, creature-driven, and aligned with Mobile Design Truth v2.2.

---

## Core Visual Philosophy

### Primary Aesthetic DNA
- **LEGENDARY PIXEL FABLE INK**: Detailed top-down pixel-art monster RPG style inspired by PS1-era JRPGs, GBA fantasy RPGs, classic creature battlers, Golden Sun-like jewel-toned shading, Pokemon-like silhouette readability, and Digimon-like evolution energy.
- **Tone**: Wondrous, cool, mythic, strange, collectible, whimsical, slightly eerie, and legendary.
- **Readable Creature Power**: Organic, evolving forms with clear silhouettes and gameplay-readable intent.
- **Ascendant Power**: Visual escalation from weak prey to feared predator
- **Corruption Layer**: Bone Ink / Bonecut Ink belongs to corruption, Blight, Omen, boss, high-pressure, or late-run escalation. It is not the default visual identity.

### Monster RPG Cohesion Rules
- **Silhouette First**: Player, creatures, rewards, and threats must read at gameplay scale before detail is added.
- **Monster Intent Readability**: Bond/Eat, threat states, and apex moments must be visually distinct in less than a second.
- **Accent Discipline**: Use amber-gold hunger, teal/cyan/moss rim magic, violet shell tones, ivory sigils, and corruption accents as role-based signals, not ambient noise.
- **Readable Wonder**: Add mythic polish and jewel-toned shading, but never hide field/directional truth.
- **Asset Doctrine**:
    - No AI image is used raw.
    - No procedural effect may hide combat truth.
    - No asset is accepted until it reads clearly at gameplay scale.
    - Bone Ink / Bonecut Ink is a later/corrupted treatment only.
- **Single Source Styling**: Route style choices through `systems/UIStyle.gd` semantic roles; avoid ad hoc inline scene styling.

### Monster Token Families
- **Base surfaces**: violet-blue shells, jewel-toned shadows, readable top-down shapes
- **Hunger accents**: amber-gold cores and warm attack flashes
- **Magic accents**: teal/cyan/moss rim light
- **Corruption accents**: black ink cracks, Bone Ink / Bonecut Ink, Blight/Omen marks
- **Text hierarchy**: high-outline, high-contrast labels for critical combat reads

### Color Palette
**Primary Creature-Fable Theme:**
- Violet shell tones, amber-gold hunger, teal/cyan/moss magic, ivory sigils, and controlled black ink cracks.
- Darkness supports readability and escalation; it is not the default whole identity.

**Creature-Specific Palettes:**
- Ashclaw: Charcoal gray + ember orange + blood red
- Bond Remnant: Ethereal blue + white + shadow purple
- Player/Vessel: Purple/violet-blue shell + amber-gold hunger core + teal/cyan/moss rim magic + ivory bone/cross/sigil accents

**UI Elements:**
- Panel backgrounds: #0F0F0F with subtle gradients
- Borders: #2A2A2A with glow effects
- Text: #E0E0E0 (primary), #FFFFFF (highlights)
- Interactive elements: Energy colors with hover states

---

## Character Visual Direction

### Player Character Evolution
The player is The Fed Anomaly / Vessel: orb-like, non-humanoid, not slime, not ghost. It absorbs, evolves, and grows.

**Stage 1: Weak Vessel**
- Compact shell posture
- Muted colors, tattered appearance
- Minimal energy effects
- Vulnerable silhouette

**Stage 2: Learning Anomaly**
- Stronger shell profile
- First mutation signs (subtle)
- Basic energy aura
- Readable combat poses

**Stage 3: Shaped Predator**
- Confident, aggressive shell stance
- Clear mutation features
- Dynamic energy effects
- Distinct combat identity

**Stage 4: Ascendant Monster**
- Imposing, transformed silhouette
- Full mutation expression
- Overwhelming presence
- Iconic power signature

### Animation Principles
- **Timing Trust**: Clear frame-by-frame progression
- **Impact Weight**: Heavy hits feel substantial
- **Flow State**: Smooth transitions between states
- **Readability**: Silhouettes clear even in chaos
- **Direction Rule**: Player, creature, and VFX action assets are authored facing down/south by default. The engine handles rotation/orientation where applicable.
- **Branch Rule**: Each action uses idle/base plus one branch frame. Do not require two unique authored frames per action.
- **Defeat Rule**: Do not require authored defeat frames. Desired future behavior is code-generated defeat from `hurt_branch` effects, but do not claim it exists unless repo truth proves it.

---

## Creature Design Standards

### Ashclaw Evolution
**Baby Form:**
- Small, vulnerable appearance
- Developing claws (nubs)
- Large eyes (curiosity)
- Subtle ember glow

**Teen Form:**
- Awkward growth phase
- Uneven claw development
- Emerging aggression
- Unstable energy patterns

**Adult Form:**
- Fully developed predator
- Distinctive claw silhouette
- Controlled ember aura
- Confident, menacing posture

### General Creature Rules
- **Silhouette Clarity**: Recognizable from outline alone
- **Role Expression**: Visual design hints at combat role
- **Evolution Logic**: Each stage shows meaningful progression
- **Species Identity**: Consistent design language across forms

---

## UI/Visual Effects Direction

### Combat Panels
**Premium Styling:**
- Dark matte backgrounds with subtle noise
- Glowing border elements (energy-based)
- Hierarchical information layout
- Smooth transition animations

**Information Hierarchy:**
1. Critical info (health, timing) - prominent placement
2. Support status - secondary visibility
3. Run progression - tertiary but clear
4. Flavor elements - ambient enhancement

### Visual Effects Philosophy
**Combat Effects:**
- Impact-driven particle systems
- Energy trails that show attack paths
- Status effects with clear visual language
- Screen shake for heavy impacts

**Mutation Effects:**
- Organic transformation sequences
- Energy absorption/consumption visuals
- DNA strand integration patterns
- Evolution aura transitions

---

## Background Art Direction

### Combat Environments
**Atmospheric Requirements:**
- True top-down 1280x720 readable background layers
- Environmental storytelling without hiding combat threats
- Dynamic lighting that supports combat readability
- World-state reflection (living, hunger, corruption, Omen)

**Visual Elements:**
- Ruined architecture with creature influence
- Biological growth patterns on structures
- Atmospheric particles (ash, spores, energy)
- Distance layering for depth perception
- Obstacles should be separate assets/layers, not baked into the background.

### Environmental Storytelling
- **Predation Evidence**: Scratches, remains, feeding grounds
- **Creature Habitats**: Nests, territorial markings
- **World Corruption**: Mutation spread, unstable zones
- **Power Resonance**: Areas affected by strong entities

---

## Technical Art Standards

### Resolution & Scaling
- **Base Resolution**: 1280x720 with pixel-perfect scaling
- **Asset Density**: High-res source, optimized for performance
- **Animation Framerate**: 60fps for combat, 30fps for ambient
- **Consistency**: Unified art pipeline across all assets

### File Organization
```
_ART_DROP_V2/
  staging_only/
assets/
  characters/
    player/
      combat/
        player_idle.png
        player_attack.png
        player_hurt.png
        player_parry.png
  creatures/
    ashclaw/
      forms/
        ashclaw_baby_premium.png
        ashclaw_teen_premium.png
        ashclaw_adult_premium.png
  ui/
    combat/
      panels/
        combat_panel_premium_top_left.png
        combat_panel_premium_top_right.png
        combat_panel_premium_reward.png
  backgrounds/
    combat/
      cbg_premium_1.png
      cbg_premium_2.png
      cbg_premium_3.png
  effects/
    combat/
      impact_heavy.png
      impact_light.png
      energy_trail.png
      mutation_effect.png
```

---

## Quality Assurance Checklist

### Asset Review Criteria
- [ ] Aligns with LEGENDARY PIXEL FABLE INK
- [ ] Maintains readability during combat
- [ ] Shows clear progression/evolution
- [ ] Authored facing down/south where it is an action asset
- [ ] Uses idle/base + one branch frame for action animation needs
- [ ] Does not require authored defeat frames
- [ ] **Visual Proof Rule**: Screenshots/Logs provided in `_visual_proofs/`
- [ ] Technical specifications met
- [ ] Consistent with established style guide

### Performance Considerations
- [ ] Optimized for target resolution
- [ ] Memory-efficient animation cycles
- [ ] Minimal impact on combat timing
- [ ] Scalable for different hardware

---

## Implementation Priority

### Phase 1: Foundation (Immediate)
1. UI panel premium upgrades
2. Player character animation refinement
3. Core visual effects (impacts, basic mutations)

### Phase 2: Enhancement (Short-term)
1. Creature evolution visual upgrades
2. Background art enhancement
3. Advanced visual effects

### Phase 3: Polish (Long-term)
1. Environmental storytelling elements
2. Advanced particle systems
3. World-state visual consequences

---

## Anti-Drift Rules

### Visual Elements to Avoid
- Generic fantasy RPG styling
- Pure grimdark or horror as the default state
- Overly cute, generic, or cartoonish designs
- Sterile, corporate-looking UI
- Inconsistent creature design language
- Directional sprite-set requests by default
- Two unique authored frames per action as a requirement
- Authored defeat-frame requirements

### Must Preserve
- Wondrous, cool, mythic, strange creature-fable identity
- Clear combat readability
- Creature identity and evolution logic
- Legendary, collectible, slightly eerie presentation
- "Start weak, become feared" visual progression

---

## Reference Influences (Direction, Not Imitation)

### Visual Energy From:
- **Solo Leveling**: Shadow powers, ascendant authority
- **Digimon**: Iconic evolution sequences
- **My Hero Academia**: Power silhouettes, impact clarity
- **Ben 10**: Distinct transformation fantasy
- **Golden Sun / GBA fantasy RPGs**: Jewel-toned readability and compact action clarity
- **Classic creature battlers**: Strong silhouettes and collectible monster identity
- **Hades**: Dark premium UI styling
- **Dead Cells**: Fluid combat animation

### Adapt, Don't Copy:
Take the energy and clarity principles, but maintain "What We Fed's" unique creature-driven predation identity.
