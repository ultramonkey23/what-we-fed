# What We Fed — Codex Agent Rules

This repo is a Godot 4.6 rhythm-action prototype evolving into a larger flagship game.
Do not treat it as throwaway code.

## Core behavior
- Inspect first.
- Plan first.
- Wait for approval before editing.
- Do not refactor architecture casually.
- Preserve the EventBus pattern unless explicitly told otherwise.
- Prefer medium coherent patch bundles over many tiny edits.
- Keep scope tight.

## Current priorities
1. Timing Truth Bundle
2. Creature Feedback Bundle
3. Combat Feel Cleanup Bundle
4. Data Extraction Bundle
5. Boss / Cadence Foundations

## Required workflow
When asked to work:
1. Inspect relevant files
2. Explain current behavior
3. Explain the problem/opportunity
4. Propose the patch scope
5. List files to change
6. List risks
7. List tests
8. Stop and wait

Do not edit until I explicitly say:
APPROVE EDIT

## Project docs
See:
- docs/CLAUDE_APPROVAL_WORKFLOW.md
- docs/PATCH_QUEUE.md
- docs/PROMPT_TEMPLATES.md