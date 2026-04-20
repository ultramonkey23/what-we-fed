# TIMING CONSTANTS REFERENCE

## Canonical Timing Windows

All timing evaluations in What We Fed use the following progress-based ranges.
Progress = 0.0 at enemy spawn → 1.0 at hit zone (beat mark) → 1.0+ toward player.

### Attack Timing (Projectile.gd)

```gdscript
const ATTACK_GOOD_MIN: float = 0.96
const ATTACK_PERFECT_MIN: float = 0.98
const ATTACK_PERFECT_MAX: float = 1.02
const ATTACK_GOOD_MAX: float = 1.04
```

| Range | Quality | Meaning |
|-------|---------|---------|
| 0.96–0.98 | good | Early side of good zone (approaching perfect) |
| 0.98–1.02 | perfect | Exact timing window; beat mark ± 2% progress |
| 1.02–1.04 | good | Late side of good zone (leaving perfect) |

### Parry Timing (Projectile.gd)

```gdscript
const PARRY_GOOD_MIN: float = 0.96
const PARRY_PERFECT_MIN: float = 0.98
const PARRY_PERFECT_MAX: float = 1.02
const PARRY_GOOD_MAX: float = 1.04
```

**Identical to attack.** Parry has the same timing windows as attack.

### Recovery Times (PlayerCombat.gd)

After an action resolves, the player is locked out for this duration (seconds):

```gdscript
# Attack recovery
const BASIC_ATTACK_RECOVERY: float = 0.28      # Default attack (off-timing or no projectile)
const TIMED_ATTACK_RECOVERY: float = 0.14      # Good/perfect attack hit
const PERFECT_ATTACK_RECOVERY: float = 0.08    # Perfect timing bonus
const EARLY_ATTACK_RECOVERY: float = 0.24      # Before good zone
const LATE_ATTACK_RECOVERY: float = 0.32       # After good zone (late hit penalty)

# Parry recovery
const GOOD_PARRY_RECOVERY: float = 0.22        # Good parry
const PERFECT_PARRY_RECOVERY: float = 0.14     # Perfect parry
const FAILED_PARRY_RECOVERY: float = 0.32      # Missed parry (stamina wasted)

# Other actions
const DODGE_RECOVERY: float = 0.22             # Dodge (does not spend stamina)
const ULTIMATE_RECOVERY: float = 0.45          # Ultimate unleash
```

**Note:** Recovery times are anti-spam tuning, not skill reward. Shorter = faster followup possible.

### Follow-up Windows (PlayerCombat.gd)

```gdscript
const FOLLOW_UP_WINDOW: float = 0.55  # Parry → attack counter window
const CHAIN_BYPASS_WINDOW: float = 0.60  # Support triggered bypass grace period
```

---

## Visual Mapping to Geometry

The timing windows are implemented as normalized progress values.
Rings are rendered based on actual distance geometry, then converted to progress equivalents.

### Ring Rendering (CombatScene.gd)

```gdscript
const RING_OUTER_RADIUS: float = 30.0   # Visual good zone boundary (pixels)
const RING_GOOD_RADIUS: float = 24.0    # Inner good zone band (pixels)
const RING_PERFECT_RADIUS: float = 15.0 # Visual perfect zone boundary (pixels)
```

### Ring-to-Progress Conversion (CombatScene.gd:_update_timing_ring_proximity)

```gdscript
var intercept_dist: float = enemy_x - hit_zone_x

# These are calculated every frame based on actual projectile distance.
var outer_entry: float = 1.0 - RING_OUTER_RADIUS / intercept_dist
var outer_exit: float = 1.0 + RING_OUTER_RADIUS / intercept_dist
var perfect_entry: float = 1.0 - RING_PERFECT_RADIUS / intercept_dist
var perfect_exit: float = 1.0 + RING_PERFECT_RADIUS / intercept_dist
```

**How this works:**
- Ring pixels are converted to progress % by dividing ring radius by intercept distance
- This makes timing fair at any projectile speed or difficulty
- Larger intercept distance → smaller % contribution from fixed pixel radius
- This preserves timing windows independent of zoom/scale

**Example:**
- If intercept_dist = 300 pixels and RING_OUTER_RADIUS = 30 pixels
- Then outer_entry ≈ 1.0 - 0.10 = 0.90, outer_exit ≈ 1.0 + 0.10 = 1.10
- The good zone spans ±0.10 progress → ±3% from beat mark

---

## Progress Calculation (Projectile.gd:_process_incoming)

```gdscript
var intercept_distance: float = enemy_x - hit_zone_x
if intercept_distance > 0.0:
    progress = (enemy_x - position.x) / intercept_distance
```

**Interpretation:**
- `progress = 0.0` when projectile is at enemy_x (just fired)
- `progress = 1.0` when projectile is at hit_zone_x (beat mark / hit zone)
- `progress = 2.0` when projectile is 1× the intercept distance past hit_zone_x

Progress is time-independent. It only depends on position geometry, not elapsed frames.

---

## Timing Evaluation Functions

### Attack Evaluation (Projectile.gd:evaluate_attack_timing)

```gdscript
func evaluate_attack_timing() -> String:
    if progress < ATTACK_GOOD_MIN:        # 0.96
        return "early"
    elif progress < ATTACK_PERFECT_MIN:   # 0.98
        return "good"
    elif progress <= ATTACK_PERFECT_MAX:  # 1.02
        return "perfect"
    elif progress <= ATTACK_GOOD_MAX:     # 1.04
        return "good"
    return "miss"
```

### Parry Evaluation (Projectile.gd:evaluate_parry_timing)

```gdscript
func evaluate_parry_timing() -> String:
    if progress < PARRY_GOOD_MIN:         # 0.96
        return "early"
    elif progress < PARRY_PERFECT_MIN:    # 0.98
        return "good"
    elif progress <= PARRY_PERFECT_MAX:   # 1.02
        return "perfect"
    elif progress <= PARRY_GOOD_MAX:      # 1.04
        return "good"
    return "miss"
```

---

## Key Constraints

1. **Perfect zone is always centered at progress 1.0** (beat mark)
2. **Perfect zone is always ±0.02 progress** (0.98–1.02)
3. **Good zone is always ±0.04 progress** (0.96–1.04)
4. **No grace zones exist beyond the good zone boundary (0.96–1.04)**
5. **All calculations are geometry-based, not time-based**

---

## Tuning Safety Rules

If you modify any of these constants, check:

1. **ATTACK/PARRY thresholds must always be 0.96–1.04** (good) and 0.98–1.02 (perfect)
2. **Ring radii must scale with 0.96–1.04 geometry**
   - If you change RING_OUTER_RADIUS, verify it maps to ~0.04 progress at typical intercept_dist
   - If you change RING_PERFECT_RADIUS, verify it maps to ~0.02 progress
3. **Recovery times do NOT affect timing perception** (they're anti-spam, not skill reward)
4. **Follow-up windows are independent of attack/parry timing** (they're action state, not judgment)

---

## References

- Primary timing logic: `scenes/combat/Projectile.gd` (lines 162–191)
- Visual ring system: `scenes/combat/CombatScene.gd` (lines 30–32, 256–350)
- Recovery tuning: `scenes/combat/PlayerCombat.gd` (lines 8–27)
- Debug verification: Enable `DEBUG_TIMING = true` in Projectile.gd

---

**Last updated:** Timing Truth Bundle, Phase 3 (Alignment Documentation)
**Status:** All timing windows verified honest and aligned to visual indicators
