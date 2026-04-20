# Premium Character Animation Specifications

## Current State Analysis
Existing player sprites are high-resolution but lack:
- Fluid animation transitions
- Impact weight and feedback
- Mutation progression visual cues
- Energy effects integration

## Enhanced Animation Framework

### Core Animation Principles
1. **Timing Trust**: Every frame serves a clear purpose
2. **Impact Weight**: Heavy attacks feel substantial
3. **Flow State**: Smooth transitions between states
4. **Readability**: Silhouettes clear even during effects

### Animation States Redesign

#### IDLE STATE (8 frames, 0.8s loop)
**Current Issues**: Static, lifeless
**Premium Enhancement**:
- Frame 1-2: Breathing cycle (subtle chest rise)
- Frame 3-4: Weight shift (left to right)
- Frame 5-6: Ready stance adjustment
- Frame 7-8: Anticipatory micro-movement
- **Visual Details**: Subtle energy aura, mutation indicators

#### ATTACK STATE (6 frames, 0.4s total)
**Current Issues**: Limited impact feedback
**Premium Enhancement**:
- Frame 1: Wind-up (coiled energy)
- Frame 2: Launch (explosive start)
- Frame 3: Impact (weapon/slash extended)
- Frame 4: Follow-through (momentum carry)
- Frame 5: Recovery (return to stance)
- Frame 6: Settle (back to ready)
- **Visual Details**: Motion blur, impact particles, energy trail

#### HURT STATE (4 frames, 0.3s total)
**Current Issues**: Basic flinch animation
**Premium Enhancement**:
- Frame 1: Impact shock (rigid body response)
- Frame 2: Recoil (forced movement)
- Frame 3: Stagger (loss of balance)
- Frame 4: Recovery (regaining composure)
- **Visual Details**: Red flash, damage particles, screen shake

#### PARRY STATE (5 frames, 0.25s total)
**Current Issues**: Simple block pose
**Premium Enhancement**:
- Frame 1: Anticipate (reading attack)
- Frame 2: Engage (defensive position)
- Frame 3: Impact (clash effect)
- Frame 4: Counter (riposte opportunity)
- Frame 5: Reset (back to stance)
- **Visual Details**: Spark effects, energy clash, perfect parry glow

### Mutation Visual Integration

#### Stage 1: Weak Prey
- **Aura**: Faint, barely visible
- **Colors**: Muted, desaturated
- **Movement**: Hesitant, smaller motions
- **Effects**: Minimal, subtle

#### Stage 2: Learning Survivor
- **Aura**: Noticeable but controlled
- **Colors**: Slightly saturated, energy hints
- **Movement**: More confident, purposeful
- **Effects**: Basic impact particles

#### Stage 3: Shaped Predator
- **Aura**: Distinct energy field
- **Colors**: Saturated, mutation colors visible
- **Movement**: Aggressive, efficient
- **Effects**: Enhanced particles, energy trails

#### Stage 4: Ascendant Monster
- **Aura**: Overwhelming presence
- **Colors**: Vibrant, multiple energy types
- **Movement**: Dominant, powerful
- **Effects**: Complex particle systems, environmental impact

### Technical Specifications

#### Resolution & Scaling
- **Base Resolution**: 192x192 pixels per frame
- **Export Scale**: 1x (high-res source)
- **Game Scale**: 50% for target 1280x720
- **Aspect Ratio**: Maintain consistency

#### Animation Timing
- **Combat Actions**: 60fps target (16ms per frame)
- **Idle Animations**: 30fps acceptable (33ms per frame)
- **Transitions**: 2-3 frames between states
- **Impact Frames**: 1-2 frames for hit feedback

#### File Structure
```
assets/characters/player/combat/premium/
  idle/
    idle_stage1_001.png
    idle_stage1_002.png
    ... (8 frames per stage)
  attack/
    attack_stage1_001.png
    attack_stage1_002.png
    ... (6 frames per stage)
  hurt/
    hurt_stage1_001.png
    hurt_stage1_002.png
    ... (4 frames per stage)
  parry/
    parry_stage1_001.png
    parry_stage1_002.png
    ... (5 frames per stage)
```

### Visual Effects Integration

#### Energy Aura System
- **Idle**: Subtle breathing pulse
- **Combat**: Intensifies with actions
- **Perfect Timing**: Bright flash
- **Mutation**: Color shifts with stage

#### Impact Particles
- **Light Attacks**: Small spark clusters
- **Heavy Attacks**: Explosive debris
- **Perfect Parry**: Energy ring expansion
- **Critical Hits**: Screen-filling effects

#### Motion Blur
- **Fast Attacks**: Subtle trail effect
- **Critical Moments**: Enhanced blur
- **Recovery Actions**: Fading trails

### Quality Assurance Checklist

#### Animation Review
- [ ] Frame timing feels natural
- [ ] Impact has appropriate weight
- [ ] Transitions are smooth
- [ ] Silhouettes remain readable
- [ ] Energy effects enhance, not clutter

#### Performance Testing
- [ ] Memory usage within limits
- [ ] Animation playback smooth
- [ ] Effects don't impact combat timing
- [ ] Scaling works across resolutions

#### Artistic Consistency
- [ ] Matches style guide aesthetic
- [ ] Mutation progression visible
- [ ] Energy colors consistent
- [ ] Character identity preserved

### Implementation Priority

#### Phase 1: Core Animations
1. Enhanced idle state (all stages)
2. Improved attack sequence
3. Better hurt/recovery

#### Phase 2: Advanced Features
1. Parry enhancement
2. Energy aura system
3. Impact particle effects

#### Phase 3: Polish
1. Motion blur integration
2. Advanced mutation visuals
3. Environmental interaction effects
