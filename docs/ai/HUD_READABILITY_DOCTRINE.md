# HUD & READABILITY DOCTRINE — WHAT WE FED

## 1. The Sacred Center (Lanes 0, 1, 2)
- The center of the screen is for **Combat Truth**. No HUD element, pop-up, or VFX slab may obscure it.
- **Lane Truth**: Every lane (0, 1, 2) must be clearly readable. If an incoming threat is hidden by a UI element, that element must be moved or made translucent.

## 2. Shells over Slabs
- Use thin, edge-aligned "shells" for UI. Avoid solid opaque "slabs."
- The UI must feel like it's "teeth" or "projections" in the dark static, not a safe Windows-style window.

## 3. Information Hierarchy
1. **Timing & Lane Threats**: (Incoming projectiles, beat indicators). Highest priority.
2. **Combat State**: (Health, Combo, Stamina). Visible but secondary.
3. **Reward & Support**: (DNA gains, Bond triggers). Edge-aligned, non-distracting.
4. **Flavor**: (Region names, lore). Tertiary, can be hidden during intense beats.

## 4. VFX Discipline
- VFX must be "punchy" but "short."
- No screen-shake that makes a lane unreadable for more than 0.1s.
- No particle explosions that hide the lane floor highlights.

## 5. Support Readability
- Bonded support actions must use a **Cooler/Blue/Teal** palette to distinguish them from **Hot/Red/Orange** enemy threats.
- Support readouts must never overlap with the player's health or combo meter.

## 6. Verification
- Evaluate HUD changes by running `run_project.bat`.
- If you can't see the lane floor highlights clearly during a "drop" or "intense" phase, the HUD has failed.
