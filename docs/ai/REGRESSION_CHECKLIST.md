# REGRESSION CHECKLIST — WHAT WE FED

## 1. Boot & Flow
- [ ] Game boots to Title Screen.
- [ ] Transition from Title -> Lair works.
- [ ] Transition from Lair -> Route works.
- [ ] Transition from Route -> Combat works.

## 2. Combat Basics
- [ ] Player can input in Lanes 0, 1, 2 (A/S/D).
- [ ] Projectiles arrive and are interactable.
- [ ] Attack/Parry/Dodge inputs register correctly.
- [ ] Ultimate meter builds and triggers.

## 3. Systems Integrity
- [ ] Health reaches zero -> Death stops the song.
- [ ] Rewards (Bond/Eat) appear at the end of combat.
- [ ] DNA/Growth persists or updates correctly.
- [ ] HUD readouts (Combo, Score) update in real-time.

## 3A. Creature Collection & Bond Persistence
- [ ] Bonding a creature adds it to the permanent lair roster.
- [ ] Bonded creatures remain chooseable after starting a future run.
- [ ] Bond level/deepening progress does not reset between runs.
- [ ] Support-slot count is meta progression and does not reset between runs.
- [ ] Active support selection is a subset of bonded creatures, not the permanent collection itself.
- [ ] When more bonded creatures exist than visible lair cards, every bonded creature remains reachable through paging/filtering.
- [ ] Save -> quit -> reload preserves lair roster, bond levels, selected supports, support-slot count, and species DNA totals.
- [ ] Eating grants species DNA without unlocking a permanent bonded support.

## 4. Identity Check
- [ ] Lane indicators are clearly visible.
- [ ] Timing feel matches the beat.
- [ ] No pausing or menu interruption **during** an active in-level combat level (between-level and pre-run management-rich menus are OK and encouraged).
- [ ] **Display Law**: **Combat HUD = Urgency** (live action) | **Management Screens = Comprehension** (between-level strategy).
- [ ] Active combat remains fast, readable, and minimally interrupted.
- [ ] Atmosphere feels dark/oppressive, not "safe."

## 5. Visual Truth Check
- [ ] Screenshot/capture evidence exists when making visual-readability claims.
- [ ] Cardinal threat lanes (N, S, E, W) remain visible through VFX, HUD shells, support triggers, and boss spectacle.
- [ ] Projectiles and timing markers are distinguishable from background, support VFX, and enemy effects.
- [ ] Support effects read as support and do not look like enemy threat unless intentionally overridden.
- [ ] Any Inspector receipt has acceptance criteria and a same-moment re-capture plan.
