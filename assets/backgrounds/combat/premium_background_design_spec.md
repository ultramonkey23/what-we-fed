# Premium Combat Background Design Specifications

**Production rule:** Every biome **triplet** (Base / Pressure / Apex) must satisfy the [Battlefield Alignment Addendum](#battlefield-alignment-addendum-required-for-all-biome-triplets). Where this document’s mood or layering language conflicts with that addendum, the addendum wins for **combat readability** and **lane shell** layout.

## Current State Analysis
Existing combat backgrounds (cbg1-3) are functional but lack:
- Atmospheric depth and oppression
- Environmental storytelling
- World-state reflection
- Premium visual polish

## Design Philosophy

### Core Atmospheric Goals
- **Oppressive Claustrophobia**: Spaces feel confining and dangerous — achieved through **perimeter pressure**, **sky/atmosphere**, and **distant scale**, not by packing the **central combat corridor** (see [addendum](#battlefield-alignment-addendum-required-for-all-biome-triplets)).
- **Biological Horror**: Environment shows creature influence
- **World Consequence**: Backgrounds reflect player actions
- **Premium Depth**: Multiple layers create visual richness — **edge and depth** carry density; the **lane shell** stays readable

### Visual Hierarchy
1. **Foreground**: Combat substrate and near-edge framing; must stay **legible** as a three-lane battlefield plane ([addendum](#battlefield-alignment-addendum-required-for-all-biome-triplets): not a busy illustrative foreground in the central corridor).
2. **Midground**: Environmental storytelling, **edge-weighted** structures and activation
3. **Background**: Atmospheric depth, world context; stable horizon anchors
4. **Sky/Atmosphere**: Mood lighting, particle effects; escalation-friendly pressure

## Battlefield Alignment Addendum (Required for All Biome Triplets)

**Each** biome triplet must be painted to a **locked combat substrate**.

_Note:_ Elsewhere in this spec, **Early / Mid / Late** game describes **narrative world-state** drift. **Base / Pressure / Apex** are the **three locked plates** for one biome’s combat triplet; horizon, floor angle, and landmark anchors stay fixed while intensity follows the addendum below.

- Do **not** treat the background as a free scenic illustration.
- Treat it as a **gameplay-aligned battlefield plate**.

### Core combat-space rules
- The **center combat corridor** must remain the **quietest and most readable** region.
- The **floor/substrate** must visibly support a **three-lane combat shell**.
- **Tall silhouettes**, **hard vertical props**, or **contrast spikes** must stay **out of the main combat read band**.
- The **same horizon line**, **floor angle**, and **landmark anchors** must remain **consistent** across Base / Pressure / Apex states.
- The scene should feel like **one place escalating**, not three different places.

### Composition constraints
- **Horizon** should stay **stable** across all three states.
- **Major landmark silhouettes** should stay **anchored in the same positions** across all three states.
- The **floor** must read as a **playable battlefield plane**, not an illustration foreground.
- **Strongest detail density** belongs at:
  - side framing
  - far distance
  - edge-weighted midground structures
- **Lowest detail density** belongs in the **central combat corridor**.

### Lane-read constraints
- The **gameplay center** must remain **low-clutter** and **mid-value stable**.
- Avoid **tall props**, **strong foreground silhouettes**, or **bright accent breaks** in the **central lane-read** region.
- Keep the **visual center supportive**, not dominant.
- Any escalation should intensify mostly through:
  - perimeter activity
  - edge-weighted accents
  - atmospheric pressure
  - landmark activation
- Escalation must **not** primarily come from **central clutter**.

### Floor/substrate rules
- The **base substrate** must feel like a **real battlefield surface**.
- It should visually support the **four-cardinal center-intercept battlefield** through shallow perspective, markings, seams, cracks, channel lines, or material rhythm that point pressure toward the center.
- The floor should **help explain where combat belongs**.
- Avoid **noisy ground detail** directly behind the **core target/shot zones**.

### State escalation rules
- **Base:** calmest, clearest, most breathable
- **Pressure:** stronger edge activity, stronger structural activation, slightly tighter tension
- **Apex:** strongest perimeter intensity and landmark activation, while **central combat readability remains protected**

<a id="triplet-approval-rule"></a>

### Approval rule (reject any version that)

- Feels like a **different location** per state
- Gets “cooler” by making the **center busier**
- Introduces **tall vertical clutter** into combat space
- Weakens readability of the **implied lane/read corridor**

## Enhanced Combat Environments

### Environment 1: "Predation Ground"
**Theme**: Ancient hunting territory, marked by countless battles
**Atmosphere**: Heavy, oppressive, blood-stained

**Visual Elements**:
- **Architecture**: Ruined temple structure, claw-marked walls
- **Ground**: Scratched stone, dark stains, scattered remains
- **Lighting**: Dim, filtered through cracked ceiling
- **Particles**: Ash drift, dust motes in light beams
- **Story Elements**: Previous battle scars, feeding grounds

**Color Palette**:
- Primary: Charcoal (#1A1A1A), rust (#8B4513)
- Secondary: Blood red (#8B0000), deep shadow (#0A0A0A)
- Accents: Faint ember glow (#FF6B35), atmospheric haze

**World-State Reflections**:
- **Early Game**: Subtle damage, minimal creature influence
- **Mid Game**: Increased claw marks, creature nests visible
- **Late Game**: Heavy corruption, environmental mutation

### Environment 2: "Mutation Chamber"
**Theme**: Biological transformation zone, unstable and dangerous
**Atmosphere**: Unsettling, organic, constantly changing

**Visual Elements**:
- **Architecture**: Organic growth overtaking structure
- **Walls**: Pulsating biomass, vein-like structures
- **Ground**: Uneven, soft, biological surface
- **Lighting**: Bioluminescent glow from biomass
- **Story Elements**: Failed transformation remnants, DNA residue

**Color Palette**:
- Primary: Dark purple (#4B0082), sickly green (#2F4F2F)
- Secondary: Mutation pink (#FF69B4), shadow black (#000000)
- Accents: Energy cyan (#00FFFF), bio yellow (#ADFF2F)

**World-State Reflections**:
- **Early Game**: Small growth patches, minimal mutation
- **Mid Game**: Significant biomass, active pulsing
- **Late Game**: Overgrown chamber, unstable energy

### Environment 3: "Ascendant Arena"
**Theme**: Final proving ground, where monsters are forged
**Atmosphere**: Epic, dangerous, transformation-focused

**Visual Elements**:
- **Architecture**: Massive scale, ancient and mysterious
- **Walls**: Carved with predator history, energy channels
- **Ground**: Polished obsidian, reflects combat energy
- **Lighting**: Dramatic from above, energy sources
- **Story Elements**: Ascension marks, power residue

**Color Palette**:
- Primary: Obsidian black (#0A0A0A), royal purple (#663399)
- Secondary: Gold energy (#FFD700), silver highlights (#C0C0C0)
- Accents: Power white (#FFFFFF), shadow red (#8B0000)

**World-State Reflections**:
- **Early Game**: Dormant arena, minimal energy
- **Mid Game**: Activating runes, glowing channels
- **Late Game**: Fully active, overwhelming power

## Technical Specifications

### Resolution & Scaling
- **Base Resolution**: 1920x1080 for source assets
- **Game Scaling**: 70% for 1280x720 target
- **Layer Separation**: Foreground/Midground/Background
- **Parallax**: Subtle movement for depth — keep **horizon** and **floor vanishing** behavior **consistent** across Base / Pressure / Apex so escalation does not read as a camera or set swap ([addendum](#battlefield-alignment-addendum-required-for-all-biome-triplets))

### Layer Structure
```
Layer 1: Sky/Atmosphere (farthest)
- Gradient background
- Atmospheric haze
- Distant elements

Layer 2: Background Architecture
- Major structures
- Environmental features
- World-state elements

Layer 3: Midground Details
- Storytelling elements
- Interactive features
- Particle sources

Layer 4: Foreground (closest)
- Battlefield **substrate** / ground plane (lane bands, seams, material rhythm)
- **Side** framing and near-edge reads only — avoid tall verticals or high-contrast breaks in the **central lane-read band** ([addendum](#battlefield-alignment-addendum-required-for-all-biome-triplets))
- Combat bounds implied by floor and edge composition, not busy center props
```

### Animation Elements
**Static Backgrounds**:
- Subtle color shifts
- Atmospheric particle drift
- Lighting pulse effects

**Dynamic Elements**:
- Energy channel flows
- Biomass pulsing (Mutation Chamber)
- Ash/ember particle systems
- World-state progression changes

## Visual Effects Integration

### Atmospheric Particles
**Predation Ground**:
- Ash drift: Slow, gentle movement
- Dust motes: Light beam interaction
- Blood mist: Combat aftermath

**Mutation Chamber**:
- Spores: Biological particles
- Energy motes: Bioluminescent floaters
- DNA fragments: Scientific elements

**Ascendant Arena**:
- Energy sparks: Power channel effects
- Light rays: Dramatic lighting
- Power residue: Combat aftermath

### Lighting Systems
**Dynamic Lighting**:
- Combat impacts create temporary light
- Energy abilities affect ambient lighting
- Boss or high-intensity moments may push lighting hard — bias dramatic shifts toward **perimeter**, **sky**, and **landmarks** so the **central corridor** keeps **mid-value stability** ([addendum](#battlefield-alignment-addendum-required-for-all-biome-triplets))

**Static Lighting**:
- Base ambient lighting sets mood
- Directional light creates depth
- Colored lights reinforce theme

### World-State Progression
**Visual Evolution System**:
- Backgrounds change based on player progress
- Corruption spreads with aggressive predation
- Stability increases with careful bonding

**Trigger Conditions**:
- **Creature Extinction**: Environmental decay
- **Overfeeding**: Biomass overgrowth
- **Balance**: Harmonious environmental state

## Quality Assurance

### Visual Standards
- [ ] Combat area remains clearly visible
- [ ] **Triplet:** one locked substrate — stable horizon, floor angle, and landmark anchors across Base / Pressure / Apex
- [ ] **Triplet:** center combat corridor stays lowest detail / lowest vertical noise; escalation reads on **perimeter** and **landmarks**, not central clutter
- [ ] **Triplet:** floor reads as a **three-lane** playable plane (markings/seams/rhythm); no noisy ground in core target/shot bands
- [ ] Atmospheric effects enhance, don't distract
- [ ] Color palettes support readability
- [ ] Performance remains optimal

### Technical Requirements
- [ ] Memory usage within limits
- [ ] Loading times acceptable
- [ ] Scaling works across resolutions
- [ ] Effects don't impact combat timing

### Artistic Consistency
- [ ] Matches dark creature power fantasy
- [ ] Environmental storytelling clear
- [ ] World-state reflection meaningful
- [ ] Premium quality maintained
- [ ] **Triplet:** passes [approval / reject gate](#triplet-approval-rule) (one place escalating; center not the “cool” layer; no tall vertical clutter in combat read; lane corridor intact)

## Implementation Priority

### Phase 1: Foundation
1. Predation Ground enhancement
2. Basic atmospheric effects
3. Core lighting systems

### Phase 2: Expansion
1. Mutation Chamber development
2. Advanced particle systems
3. World-state integration

### Phase 3: Polish
1. Ascendant Arena creation
2. Dynamic lighting systems
3. Environmental interaction effects

## File Organization
```
assets/backgrounds/combat/premium/
  predation_ground/
    background_layer.png
    midground_layer.png
    foreground_layer.png
    atmosphere_layer.png
    effects/
      ash_drift.png
      dust_motes.png
      lighting_overlay.png
  mutation_chamber/
    background_layer.png
    midground_layer.png
    foreground_layer.png
    biomass_layer.png
    effects/
      spores.png
      energy_motes.png
      pulsing_overlay.png
  ascendant_arena/
    background_layer.png
    midground_layer.png
    foreground_layer.png
    energy_channels.png
    effects/
      power_sparks.png
      light_rays.png
      residue_particles.png
```

## Performance Considerations

### Optimization Strategies
- **Layer Baking**: Combine static elements
- **Effect Culling**: Disable distant particles
- **LOD System**: Simplify at distance
- **Memory Management**: Stream large backgrounds

### Quality vs Performance
- **High Quality**: All layers, full effects
- **Medium Quality**: Reduced particle count
- **Low Quality**: Simplified lighting only
