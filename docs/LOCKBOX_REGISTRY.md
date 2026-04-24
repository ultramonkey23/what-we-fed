# LOCKBOX REGISTRY

## Purpose
- Provide a repo-side control scaffold for Lockbox tracking and implementation gating.
- Track only status metadata and process state until authoritative Lockbox card content is imported.

## Status Values
- `not_started`
- `scaffolded`
- `in_review`
- `approved_for_impl`
- `implemented`
- `verified`
- `blocked`

## Implementation Gate
- A Lockbox item cannot move to implementation work unless:
  - source text is copied from Command Center/export,
  - scope is mapped to concrete repo files,
  - validation criteria are defined.

## Lockbox Status Change Gate
- Any status change requires:
  - evidence note (what changed),
  - source reference (where truth came from),
  - updater and date.

## Current Known Count
- `37` Lockbox cards known from provided context.

## Source-of-Truth Note
- Exact full Lockbox card text must be copied from Command Center/export before implementation use.
- Do not invent or paraphrase full card text as authoritative content.

## Known Phase List
- Phase 0: project-control documentation scaffold.
