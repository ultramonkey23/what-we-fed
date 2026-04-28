# HANDOFF TEMPLATES (v1.2 Universal Workflow)

Use these templates to keep cross-tool handoffs consistent and bounded.
Every agent (Claude, Gemini, Cursor, Copilot, Codex) MUST use the same Universal Reporting Block at the end of their task.

## 1. Task Initialization & Mutation Budget

When starting a task, state your budget and guardrails:

```md
## Mutation budget
- Level: <low|medium|high>
- Why this level: <brief rationale>

## Controlled mutation guardrails
- Timing truth test: <pass/fail/pending>
- Lane readability test: <pass/fail/pending>
- Support readability test: <pass/fail/pending>
- DNA / Bond-Eat meaning test: <pass/fail/pending>
- Combat-clean, management-rich test: <pass/fail/pending>
```

*Rule: Low mutation tasks stay single-path. Medium/high mutation tasks must include dual-track output (Safe path vs Mutation path) before proceeding.*

## 2. The Shared Validation Block (The Reporting Law)

At the completion of any task (Inspect, Spec, Patch, Validate, or Evolve), you MUST provide the **Auditor's Report (v2.5)** as defined in `docs/ai/REPORT_CONTRACT.md`.

This report is the canonical standard for all AI tools in the repo.

### Required Fields for Handoff Completion
In addition to the Auditor's Report, cross-agent handoffs must include:
- **Read**: Files or systems investigated.
- **Confirmed**: Verified facts from current live build or code.
- **Strong Inference**: Educated assumptions, explicitly marked as unverified.
- **Changes made**: Brief list of targeted modifications.
- **What was not changed**: Explicitly state what was intentionally left alone to prevent drift.
- **Next Bounded Move**: One clear recommendation for the next agent.

## Shared Handoff Rule
- Use the **Handoff Compiler** (`docs/ai/workflows/HANDOFF_COMPILER.md`) to generate a rigid **Execution Packet**.
- Keep handoffs short, executable, and evidence-based.
- Do not fragment reporting formats based on the AI tool used. The Shared Validation Block is the single standard.
- Always end with one recommended bounded next move.

## Visual Handoff Addendum
Use this only when visual evidence is part of the task.

```md
## Visual evidence packet
- Evidence paths: <png/jpg/webp/mp4/frame sequence paths>
- Metadata paths: <capture seed json paths, or unknown>
- Moment ID: <moment being judged>
- Scene / viewport / camera: <known values or unknown>
- Lane / song / support context: <known values or unknown>
- Expected visual contract: <HUD readability, support color, boss spectacle, premium menace, etc.>
- Required output: Inspector Visual Audit Receipt from `docs/ai/VISUAL_TRUTH_LOOP.md`
```

Visual patching should flow: BRAIN route -> INSPECTOR receipt -> ALFRED/Shader Surgeon patch -> CYBORG re-capture validation.
