# DETERMINISTIC WORKFLOWS — WHAT WE FED

This document defines the "Agent OS" workflows that must be followed for every session and PR.

## 1. Session Initialization (Mandatory)
Every terminal AI session MUST begin by grounding in these files:
0. `docs/ai/TERMINAL_AI_BOOTSTRAP.md` (Fast-load contract)
1. `AGENTS.md` (Master Contract)
2. `PROJECT_SETUP_AND_VALIDATION.md` (Environment/Tools)
3. `docs/ai/NEXT_MOVE_ROUTER.md` (Strategic Priority)

## 2. The "One Best Next Move" Workflow
Before starting any Level 3+ (Feature) or Level 4 (Content) task:
1. Use `SOVEREIGN_CORE.md` to classify the bottleneck.
2. State the "One Best Move" and "What Should Wait."
3. Propose a **Surgical Plan** (text-only) and wait for a Directive.

## 3. The Bug-Fix Loop (Level 1)
Follow `docs/ai/BUGFIX_WORKFLOW.md` strictly:
1. **Blocker First**: No cleanup until the crash is gone.
2. **Surgical Patch**: Minimal change.
3. **Verify**: Run `smoke_project.bat`.

## 4. The Validation Standard (Mandatory for PRs)
Every completed task MUST include a filled-out `docs/ai/VALIDATION_STANDARD.md`.
- **Status**: State 🟢 Runtime, 🟡 Static, or 🔴 Unverified.
- **Identity Lock**: Confirm the change protects **Lane Truth** and **Timing Truth**.

## 5. Specialist Role Invocation
Agents should explicitly announce their role when starting a sub-task:
- "Invoking **HUD Surgeon** for Lane 0 visibility."
- "Invoking **GDScript Surgeon** for EventBus signal typing."
- "Invoking **Crash Hunter** for CombatScene null-pointer localization."
- "Invoking **Inspector** for screenshot-backed lane/support readability."

## 6. Maintenance Checklist
- Update `docs/ai/REGRESSION_CHECKLIST.md` after adding a new core system.
- Refine `docs/ai/GDSCRIPT_ENGINEERING_RULES.md` if a new common pattern (e.g., Godot 4.3 features) is adopted.
