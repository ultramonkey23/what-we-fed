# LOCKBOX_REGISTRY

## Purpose
- Repo-side scaffold for tracking Lockbox implementation readiness and status transitions.
- Process/control registry only; not a source of full Lockbox card content.

## Status Values
- `not_started`
- `scaffolded`
- `in_review`
- `approved_for_impl`
- `implemented`
- `verified`
- `blocked`

## Implementation Gate
- No Lockbox item may enter implementation unless:
  - exact card text is copied from Command Center/export,
  - scope is mapped to concrete repo files,
  - validation criteria are defined.

## Lockbox Status Change Gate
- Any status change requires:
  - evidence note,
  - source reference,
  - updater identity,
  - date.

## Current Known Count
- `37`

## Source-Text Requirement Note
- Exact full Lockbox card text must be copied from Command Center/export before implementation use.
- Do not invent full Lockbox card text in this registry.

## Known Phase List
- Phase 0: project-control documentation scaffold.
