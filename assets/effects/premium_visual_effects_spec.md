# Premium Visual Effects Specifications

## Current State Analysis
Existing visual effects (shot1-4 projectiles) are basic and need:
- Impact weight and feedback
- Energy type differentiation
- Mutation progression effects
- Premium particle systems

## Design Philosophy

### Core Effect Principles
- **Impact Trust**: Effects clearly communicate action success
- **Energy Identity**: Different abilities have distinct visual signatures
- **Mutation Expression**: Effects evolve with player transformation
- **Performance**: Effects enhance, never hinder combat timing

### Energy Type System
- **Physical**: Solid, weighty impacts, debris particles
- **Mutation**: Organic, transformative effects, DNA elements
- **Energy**: Ethereal, flowing effects, light-based particles
- **Support**: Beneficial auras, defensive barriers

## Combat Effect Categories

### Attack Impact Effects

#### Light Attack - "Swift Strike"
**Visual Identity**: Fast, precise, minimal energy
**Duration**: 0.2 seconds total
**Color Scheme**: White core + cyan trail

**Effect Sequence**:
1. **Wind-up** (0.05s): Subtle energy gather at impact point
2. **Impact** (0.05s): Bright white flash, directional sparks
3. **Follow-through** (0.1s): Fading cyan trail, particle drift

**Particle Details**:
- **Primary**: 8-12 white spark particles
- **Secondary**: 4-6 cyan trail particles
- **Size**: 2-4 pixels
- **Speed**: Fast initial burst, then drift

#### Heavy Attack - "Devastating Blow"
**Visual Identity**: Powerful, screen-shaking, explosive
**Duration**: 0.4 seconds total
**Color Scheme**: Orange core + red explosion

**Effect Sequence**:
1. **Wind-up** (0.1s): Growing orange energy sphere
2. **Impact** (0.1s): Explosive burst, screen shake
3. **Shockwave** (0.15s): Expanding ring force
4. **Aftermath** (0.05s): Falling ember particles

**Particle Details**:
- **Primary**: 20-30 orange explosion particles
- **Secondary**: 15-20 red shockwave particles
- **Tertiary**: 10-12 ember fallout particles
- **Size**: 4-8 pixels (larger than light attack)
- **Speed**: Explosive expansion, then gravity fall

#### Perfect Attack - "Critical Execution"
**Visual Identity**: Precision, enhanced damage, special effects
**Duration**: 0.3 seconds total
**Color Scheme**: Gold core + rainbow energy

**Effect Sequence**:
1. **Wind-up** (0.05s): Golden energy concentration
2. **Impact** (0.05s): Brilliant gold flash, rainbow burst
3. **Critical** (0.15s): Sustained golden glow, damage numbers
4. **Recovery** (0.05s): Fading gold particles

**Particle Details**:
- **Primary**: 15-20 gold burst particles
- **Secondary**: 10-15 rainbow energy particles
- **Special**: Floating damage numbers (+50%)
- **Size**: 3-6 pixels
- **Speed**: Directional burst with sustained glow

### Defensive Effects

#### Parry Success - "Defensive Mastery"
**Visual Identity**: Sharp, precise, energy clash
**Duration**: 0.25 seconds total
**Color Scheme**: Blue-white clash + spark shower

**Effect Sequence**:
1. **Anticipate** (0.05s): Blue energy gather
2. **Clash** (0.05s): White flash, directional sparks
3. **Counter** (0.1s): Blue counter-energy pulse
4. **Recovery** (0.05s): Fading blue particles

**Particle Details**:
- **Primary**: 12-15 white clash sparks
- **Secondary**: 8-10 blue counter particles
- **Special**: "PERFECT" text flash
- **Size**: 2-4 pixels
- **Speed**: Sharp directional burst

#### Perfect Parry - "Time Manipulation"
**Visual Identity**: Reality distortion, time freeze effect
**Duration**: 0.5 seconds total
**Color Scheme**: Purple distortion + white freeze

**Effect Sequence**:
1. **Trigger** (0.05s): Purple energy ripple
2. **Freeze** (0.15s): White overlay, time stop effect
3. **Opportunity** (0.2s): Sustained purple glow
4. **Resume** (0.1s): Particle burst, normal speed

**Particle Details**:
- **Primary**: Purple distortion waves
- **Secondary**: White freeze particles
- **Special**: Screen-wide time distortion effect
- **Size**: Variable (distortion waves larger)
- **Speed**: Slow, ethereal movement

### Creature Support Effects

#### Ashclaw Support - "Ember Strike"
**Visual Identity**: Fire-based, coordinated attack
**Duration**: 0.3 seconds total
**Color Scheme**: Orange-red ember burst

**Effect Sequence**:
1. **Signal** (0.05s): Ashclaw ember glow
2. **Strike** (0.1s): Coordinated ember explosion
3. **Burn** (0.1s): Sustained ember damage
4. **Fade** (0.05s): Falling ember particles

**Particle Details**:
- **Primary**: 15-20 orange ember particles
- **Secondary**: 10-12 red burn particles
- **Special**: Coordinated attack indicator
- **Size**: 3-5 pixels
- **Speed**: Explosive burst, then drift

#### Bond Remnant Support - "Protective Pulse"
**Visual Identity**: Defensive, healing, protective
**Duration**: 0.4 seconds total
**Color Scheme**: Blue-white protective energy

**Effect Sequence**:
1. **Activate** (0.05s): Blue energy gather around player
2. **Barrier** (0.15s): Expanding protective sphere
3. **Heal** (0.15s): Sustained blue glow, health gain
4. **Fade** (0.05s): Dissipating blue particles

**Particle Details**:
- **Primary**: 20-25 blue barrier particles
- **Secondary**: 15-18 white heal particles
- **Special**: Protective sphere visual
- **Size**: 4-6 pixels
- **Size**: Slow, protective movement

### Mutation Progression Effects

#### Level-Up Evolution - "Ascension Moment"
**Visual Identity**: Transformative, biological, powerful
**Duration**: 1.0 seconds total
**Color Scheme**: DNA purple + energy gold

**Effect Sequence**:
1. **Trigger** (0.1s): Purple energy gather
2. **Transformation** (0.4s): DNA helix formation, body change
3. **Ascension** (0.3s): Gold power surge, new form reveal
4. **Settle** (0.2s): Fading energy, new form established

**Particle Details**:
- **Primary**: 30-40 purple DNA particles
- **Secondary**: 25-30 gold ascension particles
- **Special**: DNA helix visual effect
- **Size**: 6-10 pixels (larger for importance)
- **Speed**: Complex transformation patterns

#### Ultimate Ability - "Predator's Dominion"
**Visual Identity**: Overwhelming, screen-filling, dominant
**Duration**: 1.5 seconds total
**Color Scheme**: Dark purple + oppressive red

**Effect Sequence**:
1. **Charge** (0.2s): Dark energy accumulation
2. **Release** (0.3s): Screen-wide energy wave
3. **Dominion** (0.7s): Sustained oppressive field
4. **Aftermath** (0.3s): Fading power, battlefield change

**Particle Details**:
- **Primary**: 50+ screen-wide energy particles
- **Secondary**: 40+ oppressive field particles
- **Special**: Screen-wide visual transformation
- **Size**: Variable (screen-filling effects)
- **Speed**: Slow, overwhelming movement

## Technical Implementation

### Particle System Architecture
```
assets/effects/presets/
  combat/
    light_attack.preset
    heavy_attack.preset
    perfect_attack.preset
    parry_success.preset
    perfect_parry.preset
  support/
    ashclaw_strike.preset
    bond_remnant_pulse.preset
  progression/
    level_up_evolution.preset
    ultimate_ability.preset
```

### Performance Optimization
**Particle Budgeting**:
- **Light Combat**: 20-30 particles max
- **Heavy Combat**: 40-60 particles max
- **Ultimate Effects**: 80-100 particles max
- **Background Effects**: 10-15 particles max

**LOD System**:
- **High Quality**: Full particle count, all effects
- **Medium Quality**: 70% particles, reduced complexity
- **Low Quality**: 50% particles, simplified effects

### Animation Timing Standards
- **Combat Actions**: 60fps, precise timing
- **Support Effects**: 30fps acceptable
- **Background Effects**: 20fps acceptable
- **Ultimate Effects**: 60fps for impact

## Quality Assurance

### Visual Standards
- [ ] Effects clearly communicate action success
- [ ] Energy types visually distinct
- [ ] Combat timing never hindered
- [ ] Screen readability maintained

### Performance Requirements
- [ ] Frame rate remains stable
- [ ] Memory usage within limits
- [ ] Loading times minimal
- [ ] Scalability across hardware

### Artistic Consistency
- [ ] Matches dark creature power fantasy
- [ ] Energy colors consistent with theme
- [ ] Effects scale with mutation progression
- [ ] Premium quality maintained

## Implementation Priority

### Phase 1: Core Combat
1. Light/Heavy attack effects
2. Basic parry effects
3. Simple support effects

### Phase 2: Enhanced Features
1. Perfect timing effects
2. Advanced support visuals
3. Basic mutation effects

### Phase 3: Premium Polish
1. Ultimate ability effects
2. Advanced mutation progression
3. Environmental interaction effects

## File Organization
```
assets/effects/
  sprites/
    particles/
      spark_white.png
      spark_cyan.png
      ember_orange.png
      dna_purple.png
      energy_gold.png
    overlays/
      screen_shake.png
      time_freeze.png
      protective_barrier.png
  presets/
    combat_effects.preset
    support_effects.preset
    progression_effects.preset
  shaders/
    particle_shader.gdshader
    energy_shader.gdshader
    distortion_shader.gdshader
```
