# WHAT WE FED - VISUAL STYLE GUIDE

## Purpose
This guide defines the premium visual direction for "What We Fed" art upgrades, ensuring all assets align with the game's dark creature power fantasy.

---

## Core Visual Philosophy

### Primary Aesthetic DNA
- **Dark & Oppressive**: High contrast, shadow-heavy environments
- **Premium Menace**: Clean, sharp edges with atmospheric depth
- **Wild Fable Machine Ink**: AI-generated imagery as organic source material (creatures, portraits, mutations) + Computer-generated procedural art for readable effects, UI frames, and indicators.
- **Biological Horror**: Organic, mutated forms with readable silhouettes
- **Ascendant Power**: Visual escalation from weak prey to feared predator
- **Stylish & Cool**: Influenced by Solo Leveling, Digimon evolution, MHA silhouettes
- **Manga Monstrosity**: Ink-heavy contrast, dramatic framing, and aggressive silhouette clarity unified by pixel-art treatment and palette discipline.

### Manga + Cool Monster Cohesion Rules
- **Ink Contrast First**: Major panels and labels should read against near-black ink foundations before accent colors are introduced.
- **Monster Intent Readability**: Bond/Eat, threat states, and apex moments must be visually distinct in less than a second.
- **Accent Discipline**: Use ember, mutation magenta, and bond teal as role-based accents, not ambient noise.
- **Readable Drama**: Add punch with sharp highlights and outline-heavy typography, but never hide field/directional truth.
- **Wild Fable Machine Ink Doctrine**:
    - No AI image is used raw.
    - No procedural effect may hide combat truth.
    - No asset is accepted until it reads clearly at gameplay scale.
    - Bonecut Ink is not the default style; it is a later/corrupted treatment inside the Wild Fable Machine Ink pipeline.
- **Single Source Styling**: Route style choices through `systems/UIStyle.gd` semantic roles; avoid ad hoc inline scene styling.

### Manga Monster Token Families
- **Base surfaces**: ink black, deep violet shells
- **Alert accents**: ember red/orange and apex gold
- **Mutation accents**: magenta/purple energy
- **Bond accents**: teal resonance
- **Text hierarchy**: high-outline, high-contrast labels for critical combat reads

### Color Palette
**Primary Dark Theme:**
- Deep blacks: #0A0A0A, #121212
- Shadow grays: #1A1A1A, #2A2A2A, #3A3A3A
- Blood accents: #8B0000, #CD2626
- Energy highlights: #00FFFF (cyber), #FF00FF (mutation), #FFFF00 (power)

**Creature-Specific Palettes:**
- Ashclaw: Charcoal gray + ember orange + blood red
- Bond Remnant: Ethereal blue + white + shadow purple
- Player forms: Human skin tones + mutation colors + energy auras

**UI Elements:**
- Panel backgrounds: #0F0F0F with subtle gradients
- Borders: #2A2A2A with glow effects
- Text: #E0E0E0 (primary), #FFFFFF (highlights)
- Interactive elements: Energy colors with hover states

---

## Character Visual Direction

### Player Character Evolution
**Stage 1: Weak Prey**
- Smaller, hunched posture
- Muted colors, tattered appearance
- Minimal energy effects
- Vulnerable silhouette

**Stage 2: Learning Survivor**
- More upright stance
- First mutation signs (subtle)
- Basic energy aura
- Readable combat poses

**Stage 3: Shaped Predator**
- Confident, aggressive posture
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
- Oppressive, claustrophobic spaces
- Environmental storytelling (remnants of past battles)
- Dynamic lighting that supports combat readability
- World-state reflection (corruption, stability)

**Visual Elements:**
- Ruined architecture with creature influence
- Biological growth patterns on structures
- Atmospheric particles (ash, spores, energy)
- Distance layering for depth perception

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
assets/
  characters/
    player/
      combat/
        player_idle_premium.png
        player_attack_premium.png
        player_hurt_premium.png
        player_parry_premium.png
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
- [ ] Aligns with dark creature power fantasy
- [ ] Maintains readability during combat
- [ ] Shows clear progression/evolution
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
- Bright, cheerful color schemes
- Overly cute or cartoonish designs
- Sterile, corporate-looking UI
- Inconsistent creature design language

### Must Preserve
- Dark, oppressive atmosphere
- Clear combat readability
- Creature identity and evolution logic
- Premium, stylish presentation
- "Start weak, become feared" visual progression

---

## Reference Influences (Direction, Not Imitation)

### Visual Energy From:
- **Solo Leveling**: Shadow powers, ascendant authority
- **Digimon**: Iconic evolution sequences
- **My Hero Academia**: Power silhouettes, impact clarity
- **Ben 10**: Distinct transformation fantasy
- **Hades**: Dark premium UI styling
- **Dead Cells**: Fluid combat animation

### Adapt, Don't Copy:
Take the energy and clarity principles, but maintain "What We Fed's" unique creature-driven predation identity.
