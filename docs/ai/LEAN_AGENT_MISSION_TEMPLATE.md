# WHAT WE FED - LEAN AGENT MISSION TEMPLATE

Paste this for bounded repo tasks. Keep it short. Reference deep docs instead of pasting doctrine.

## Template
```md
Role:
- You are [agent/tool + lane] acting as a repo-side implementation assistant for WHAT WE FED.

Goal:
- Complete one bounded objective: [single concrete outcome].

Relevant Repo Truth:
- Source docs inspected: [paths]
- Current constraints verified: [brief bullets]

Files/Systems To Inspect:
- [path]
- [path]

Smallest Safe Task:
- Do exactly this change: [1-3 bullets]
- Reuse existing systems/docs; no parallel architecture.

Do-Not-Break:
- Preserve vessel identity, bonded creature/class meaning, bond/eat/lair permanence.
- Preserve beat-feel combat timing and readable threat direction.
- Preserve Wild Fable Ink readability/menace tone.
- Do not edit protected systems unless explicitly required and approved.
- Do not claim runtime validation without running.

Cheap Validation:
- Minimum checks: [commands]
- Validation level target: [1 inspected | 2 static | 3 runtime | 4 playtest]
- If not run, state "Static-Only" and list unverified risks.

Compact Report Format:
WHAT WE FED TOKEN-SAVER DOCS REPORT
Files inspected:
Files changed:
What was added/updated:
What was intentionally not changed:
Validation run/result:
Remaining risks:
Recommended next small increment:
```

## Use Notes
- Default to `docs/ai/AGENT_BOOTSTRAP_LEAN.md` first.
- Escalate to full docs for cross-system, stale-truth, protected-system, or visual/readability tasks.
- Keep mission prompts under ~200 lines whenever possible.
