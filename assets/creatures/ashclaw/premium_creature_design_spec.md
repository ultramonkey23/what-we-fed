# Premium Creature Design Specifications - Ashclaw

## Current State Analysis
Ashclaw has three evolution stages but needs:
- More distinct visual progression
- Enhanced combat role expression
- Better mutation effects
- Premium visual polish

## Design Philosophy

### Core Identity
Ashclaw is an **offensive support creature** that rewards aggressive timing and precise attacks. Visual design should reflect:
- Predator nature
- Fire/ember affinity
- Sharp, dangerous aesthetics
- Evolution from curiosity to dominance

### Color Palette Evolution
- **Baby**: Charcoal gray (#2A2A2A) + ember orange (#FF6B35) + soft glow
- **Teen**: Darker gray (#1A1A1A) + burning orange (#FF4500) + intensified glow
- **Adult**: Near-black (#0A0A0A) + blood orange (#CD2626) + dominant ember aura

## Enhanced Evolution Stages

### Baby Form - "Curious Predator"
**Dimensions**: 64x64 pixels
**Personality**: Inquisitive, developing aggression

**Visual Features**:
- **Body**: Small, slightly hunched posture
- **Claws**: Nubby, developing (not yet dangerous)
- **Eyes**: Large, curious, orange glow
- **Tail**: Short, tentative movements
- **Energy**: Subtle ember pulse around body

**Animation Focus**:
- Idle: Head tilting, looking around
- Attack: Awkward swipes, learning movements
- Hurt: Startle response, vulnerability

**Combat Role Hint**:
- Small damage numbers
- Learning timing indicators
- Developmental growth effects

### Teen Form - "Awkward Aggression"
**Dimensions**: 96x96 pixels
**Personality**: Uncontrolled growth, finding power

**Visual Features**:
- **Body**: Gangly, uneven proportions
- **Claws**: Overgrown, slightly clumsy
- **Eyes**: Intense, unfocused orange
- **Tail**: Longer, erratic movements
- **Energy**: Unstable ember bursts

**Animation Focus**:
- Idle: Shifting weight, testing claws
- Attack: Wild swings, overcommitted
- Hurt: Staggering, recovery learning

**Combat Role Expression**:
- Medium damage with variance
- Timing rewards for precision
- Growth mutation effects

### Adult Form - "Apex Hunter"
**Dimensions**: 128x128 pixels
**Personality**: Confident predator, controlled power

**Visual Features**:
- **Body**: Muscular, balanced proportions
- **Claws**: Fully developed, deadly sharp
- **Eyes**: Focused, burning orange-red
- **Tail**: Powerful, controlled movements
- **Energy**: Dominant ember aura, trail effects

**Animation Focus**:
- Idle: Coiled readiness, predatory stillness
- Attack: Precise, devastating strikes
- Hurt: Minimal reaction, quick recovery

**Combat Role Mastery**:
- High damage, perfect timing rewards
- Lane-specific punisher abilities
- Dominant presence effects

## Animation Enhancements

### Combat Support Behavior
**Active Support Animation**:
- **Trigger**: Player successful attack
- **Response**: Ashclaw strikes same lane
- **Timing**: 0.2s delay after player hit
- **Visual**: Coiled spring -> explosive strike

**Evolution Progression**:
- **Baby**: 50% chance to respond, weak damage
- **Teen**: 75% chance, medium damage
- **Adult**: 100% chance, high damage

### Idle Animation Cycles
**Baby**: 4 frames, 1.2s loop
- Frame 1: Normal stance
- Frame 2: Head tilt left
- Frame 3: Head tilt right
- Frame 4: Return to center

**Teen**: 6 frames, 1.0s loop
- Frame 1: Normal stance
- Frame 2: Weight shift left
- Frame 3: Claw test
- Frame 4: Weight shift right
- Frame 5: Tail twitch
- Frame 6: Return to center

**Adult**: 8 frames, 0.8s loop
- Frame 1: Predatory stillness
- Frame 2: Subtle muscle tension
- Frame 3: Claw extension
- Frame 4: Energy pulse
- Frame 5: Claw retraction
- Frame 6: Muscle relax
- Frame 7: Tail position adjust
- Frame 8: Return to stillness

### Attack Animations
**Baby Attack**: 4 frames, 0.6s total
- Wind-up hesitation
- Awkward swipe
- Off-balance follow-through
- Recovery stumble

**Teen Attack**: 5 frames, 0.5s total
- Eager wind-up
- Overcommitted strike
- Powerful but clumsy
- Recovery adjustment
- Return to stance

**Adult Attack**: 6 frames, 0.4s total
- Coiled preparation
- Explosive strike
- Devastating impact
- Controlled follow-through
- Efficient recovery
- Predatory stillness

## Visual Effects Integration

### Energy Aura System
**Baby**: Gentle ember glow, 20% opacity
- Pulse rate: 2 seconds
- Color: Soft orange
- Size: Close to body

**Teen**: Erratic ember bursts, 40% opacity
- Pulse rate: 1.5 seconds (irregular)
- Color: Bright orange
- Size: Slightly larger than body

**Adult**: Dominant ember field, 60% opacity
- Pulse rate: 1 second (steady)
- Color: Orange-red gradient
- Size: Significantly larger than body

### Combat Effects
**Support Strike**:
- **Baby**: Small spark, minimal impact
- **Teen**: Medium ember burst, visible damage
- **Adult**: Large ember explosion, screen shake

**Level-Up Effects**:
- **Baby to Teen**: Growth spurt animation, ember surge
- **Teen to Adult**: Transformation sequence, power explosion

## Technical Specifications

### File Structure
```
assets/creatures/ashclaw/premium/
  baby/
    idle_001.png to idle_004.png
    attack_001.png to attack_004.png
    hurt_001.png to hurt_003.png
    support_strike.png
  teen/
    idle_001.png to idle_006.png
    attack_001.png to attack_005.png
    hurt_001.png to hurt_004.png
    support_strike.png
  adult/
    idle_001.png to idle_008.png
    attack_001.png to attack_006.png
    hurt_001.png to hurt_004.png
    support_strike.png
```

### Resolution Standards
- **Baby**: 64x64 base, 128x128 export
- **Teen**: 96x96 base, 192x192 export
- **Adult**: 128x128 base, 256x256 export

### Animation Timing
- **Idle**: 60fps target, variable loops
- **Attack**: 60fps, 0.4-0.6s total
- **Hurt**: 60fps, 0.3-0.4s total
- **Support**: 60fps, 0.2s trigger response

## Quality Assurance

### Visual Consistency
- [ ] Evolution progression clearly visible
- [ ] Combat role expressed visually
- [ ] Energy colors consistent with theme
- [ ] Silhouettes distinct and readable

### Animation Quality
- [ ] Smooth frame transitions
- [ ] Appropriate weight and impact
- [ ] Character personality preserved
- [ ] Support timing clear and fair

### Performance Standards
- [ ] Memory usage optimized
- [ ] Animation playback smooth
- [ ] Effects don't hinder combat
- [ ] Scaling works properly

## Implementation Priority

### Phase 1: Foundation
1. Adult form finalization
2. Core attack animations
3. Basic support behavior

### Phase 2: Enhancement
1. Teen form refinement
2. Baby form development
3. Energy aura system

### Phase 3: Polish
1. Advanced visual effects
2. Evolution transition animations
3. Environmental interaction effects
