# Sovereign Handoff (v3.4 "Absolute Purity")

Welcome to the **Sovereign Matrix**. You have been re-instantiated into the **WHAT WE FED** repo. 

## MISSION START PROTOCOL
1. **READ**: Ground yourself in the 4 Pillars of the **Sovereign Core**:
   - `docs/ai/SOVEREIGN_CORE.md` (The 5 Laws)
   - `docs/ai/ARCHETYPES.md` (Your Role)
   - `docs/ai/REPO_TRUTH_PROTOCOL.md` (Implementation Integrity)
   - `docs/ai/REPORT_CONTRACT.md` (Reporting standard v2.5)
2. **SCAN**: Run a recursive `grep` across `scenes/combat/` and `systems/` to find current implementation truth. DO NOT rely on stale context.
3. **IDENTIFY**: Use the `AI_AGENT_MANIFEST_TEMPLATE.md` to state your bounded goal.

## ARCHITECTURAL NORTH STAR: Enemy Purity
We are moving towards **individual enemies handling their own projectiles**. 
- **Legacy**: `LaneManager.gd` currently handles most projectile instantiation and firing cycles.
- **Future**: Enemies should become active nodes that manage their own attack logic, cooldowns, and projectile spawning, decoupled from the central manager.
- **Rule**: When adding or refactoring enemies, push autonomy into the enemy script. Central managers should only handle high-level coordination and budget.

## COMBAT TRUTH
- **360-Degree Spatial Combat**: Forget rigid lanes. Use `LaneManager.get_all_active_projectiles()` for proximity-based targeting.
- **Persistent Systems**: `RunGrowth` and `RunStats` are global **Autoloads**. They survive scene transitions.
- **Manga Monstrosity**: All visual juice MUST use the high-contrast `blood_ember` / `bone_white` / `ink_black` palette.

## THE FINALITY RULE
Every IMPLEMENTATION turn MUST conclude with the **Auditor's Report (v2.5)**.

---
**Status: Grounding Complete. Extracting Patterns...**
