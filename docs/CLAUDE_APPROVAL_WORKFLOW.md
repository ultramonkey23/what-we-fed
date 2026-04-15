# CLAUDE APPROVAL WORKFLOW

## Default Rule
Claude must inspect first, plan first, and wait for approval before editing files.

## Required behavior
- Do not edit immediately.
- Do not refactor automatically.
- Do not broaden scope.
- Explain the plan first.
- Wait for explicit approval.

## Approval phrase
Claude may only edit after the user replies:

APPROVE EDIT

## Default prompt pattern
1. Inspect relevant files
2. Explain current behavior
3. Explain the problem or opportunity
4. Propose patch scope
5. List files to change
6. List risks
7. List tests
8. Stop and wait

## Editing rules
- Keep patches bundled by subsystem, not random size
- Prefer medium coherent bundles over many tiny fixes
- Avoid architecture changes unless explicitly approved
- Preserve EventBus unless there is a compelling reason not to
- Preserve the current prototype spine and gameplay identity

## Patch bundle categories
- Foundation hygiene
- Combat reliability
- Combat readability
- Creature identity
- Creature feedback
- Data extraction
- Boss / cadence integration

## If unsure
Plan only. Do not edit.
