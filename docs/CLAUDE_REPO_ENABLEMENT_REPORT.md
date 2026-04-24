# Claude Repo Enablement Report

Installed April 24, 2026 as a Claude-native collaboration layer for WHAT WE FED.

## What Was Added
- `CLAUDE.md`: concise always-loaded project memory with authority order, locked core, current repo truth, agent routing, validation commands, and load-on-demand references.
- Scoped `CLAUDE.md` files in `scenes/`, `scenes/combat/`, `scenes/ui/`, `systems/`, `data/`, `assets/`, and `art/`: local rules that load only when Claude works in those areas.
- `.claude/agents/brain.md`, `symbiote.md`, `cyborg.md`, `alfred.md`: project subagents in Claude Code markdown/frontmatter format.
- `.claude/skills/*/SKILL.md`: reusable procedures for repeated repo burdens.
- `.claude/settings.json`: shared Claude Code settings with project metadata and advisory `PostToolUse` hooks.
- `.claude/hooks/claude_workflow_guard.py`: hook script that prints targeted validation/readability reminders after Claude edits sensitive files.

## How Claude Should Behave Differently
- Start from concise repo truth instead of loading long doctrine by default.
- Route tasks through BRAIN, SYMBIOTE, CYBORG, or ALFRED before acting.
- Load procedures through skills only when relevant.
- Pick up local rules automatically when reading or editing high-risk paths.
- Receive automatic reminders after combat, HUD/VFX, asset, and data edits.
- Report validation honestly and avoid claiming feel/readability without runtime or visual evidence.

## Human Review Points
- Confirm the hook command works in the preferred Claude Code shell on this Windows setup.
- Tune hook sensitivity if reminders become noisy.
- Add more scoped rules only after repeated friction proves they are needed.
