# GDScript Review Rubric

Use this rubric to evaluate AI-generated code or self-review before finalizing a task in the WHAT WE FED project.

## 1. Context Assessment
Before reviewing code, explicitly state:
- **Confirmed:** Facts verified directly via reading files or running scripts.
- **Strong Inference:** Likely truths based on project patterns (e.g., "Assumed `EnemyBase.gd` inherits `Node2D` based on methods called").
- **Unknown:** Blind spots requiring human clarification or runtime testing.

## 2. Correctness & Safety
- [ ] Does the code compile without parse errors?
- [ ] Are null guards and `is_instance_valid()` checks in place for dynamic references?
- [ ] Are signals safely connected and disconnected?
- [ ] Is typed GDScript used correctly without bypassing the type system with unwarranted casts?

## 3. Godot-Native Quality
- [ ] Does it leverage built-in Godot features (Signals, Groups, Timers, Tweens) instead of reinventing them?
- [ ] Are node operations respectful of the SceneTree lifecycle (`_ready`, `queue_free`)?
- [ ] Is it avoiding heavy `_process()` polling in favor of event-driven logic?

## 4. Scene Integration Risk
- [ ] Does this change assume node hierarchy changes that haven't been made in the `.tscn`?
- [ ] Does it override `@export` variables in a way that breaks existing inspector configurations?

## 5. Gameplay Regression Risk (Project Identity)
- [ ] **Timing:** Does this alter the `SongConductor`'s authority or introduce "floaty" input windows?
- [ ] **Cardinal Directions:** Does it violate the strict cardinal logic (N, S, E, W)?
- [ ] **Economy:** Does it bypass or break the species-specific DNA predation loop?

## 6. UI & Readability Risk
- [ ] Does it introduce screen clutter (excessive particles, screen shakes) that hides threats?
- [ ] Does it replace **active combat** with sterile pause-menu flow? (Structured **between-level** menus for rewards/inventory are intentional; mid-fight song pauses are not.)

## 7. Upgrade vs. Vanity Churn
- [ ] **Rule:** Is this a tangible fix/feature, or is it "clean code" restructuring that offers no runtime value?
- **Action:** Reject vanity churn. Revert to minimal, surgical grounded edits.

## 8. Validation Quality
- [ ] Has the agent clearly defined how this must be tested (e.g., "Run `debug_harness.bat`, spawn creature X, verify Y")?
- [ ] Have batch scripts (`smoke_project.bat`) been utilized to verify parser integrity?