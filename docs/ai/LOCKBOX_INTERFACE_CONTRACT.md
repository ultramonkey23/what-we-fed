# LOCKBOX INTERFACE CONTRACT

## Purpose
Define how AI agents may use Lockbox items without confusing design intent with repo truth.

## Ownership Boundary
- Command Center v1 owns Lockbox cards, status, canon, and priority.
- AI Control Plane owns routing, validation, report scoring, and stale-truth protection.
- Repo Truth Ledger owns confirmed implementation truth only.

## Core Rule
Lockbox items are design intent until converted into an audit or implementation handoff backed by current repo truth.

## Allowed Agent Use
Agents may:
- read a Lockbox item included in a prompt
- audit whether current repo truth supports it
- convert it into a bounded implementation handoff if evidence supports it
- validate completed work against the original card goal

Agents may not:
- mark Lockbox items complete without scored reports
- treat Lockbox language as implemented repo truth
- implement directly from LOCKED FOR LATER status
- broaden a Lockbox card into unrelated work
- change Lockbox priority or canon

## Conversion Pipeline
LOCKED FOR LATER -> READY FOR AUDIT -> READY FOR HANDOFF -> IN IMPLEMENTATION -> VALIDATED COMPLETE

### LOCKED FOR LATER
- Decision owner: Command Center v1.
- Evidence required: Lockbox card/status and reason it remains deferred.
- Agent may do: read the item if included in a prompt and preserve it as design intent only.
- Stop condition: any request to implement, scope, prioritize, or canonize the card.

### READY FOR AUDIT
- Decision owner: Command Center v1 moves the item into audit readiness; AI Control Plane routes the audit.
- Evidence required: Lockbox card/status, current repo truth source, files to inspect, and stale-truth risks.
- Agent may do: run a read-only audit, compare design intent to current repo truth, and identify one bounded next step.
- Stop condition: repo truth is stale, missing, contradictory, or the question requires feel/rhythm/readability/fun judgment.

### READY FOR HANDOFF
- Decision owner: Command Center v1 accepts the audit direction; AI Control Plane shapes the handoff.
- Evidence required: audit result, files inspected, allowed files, forbidden files, validation plan, and implementation boundary.
- Agent may do: produce a bounded Codex/Claude implementation prompt or task handoff.
- Stop condition: scope expands beyond the card goal, forbidden files are needed, or validation cannot be named honestly.

### IN IMPLEMENTATION
- Decision owner: assigned repo agent owns the bounded repo change; Command Center v1 still owns Lockbox status/canon/priority.
- Evidence required: accepted handoff, current repo truth, allowed files, forbidden files, and validation target.
- Agent may do: implement only the named repo task and produce a complete agent report.
- Stop condition: stale repo truth, changed design intent, unexpected fragile-system impact, or need for human playtest.

### VALIDATED COMPLETE
- Decision owner: Command Center v1 accepts status completion after scored report review.
- Evidence required: completed agent report, ingestion result, scorer result, validation evidence, and comparison to original card goal.
- Agent may do: validate evidence, score or ingest reports, and recommend acceptance or rework.
- Stop condition: report fails ingestion, scorer returns FAIL, validation level does not match the claim, or Command Center v1 has not accepted completion.

## Required Evidence
- current repo truth source
- Lockbox card/status
- files inspected
- validation level
- scorer result or ingestion result
- one bounded next step

## Failure Modes
- design intent mistaken for repo truth
- stale repo truth used for implementation
- agent expands scope
- validation claims exceed evidence
- Lockbox card becomes a giant rewrite
- status changes happen outside Command Center v1

## Stop Conditions
Stop and route to Gemini if repo truth is stale.
Stop and route to human playtest if the question is feel, rhythm, readability, or fun.
Stop and route to Command Center v1 if the task is priority/canon/design-status management.

## Completion Rule
A Lockbox item is not complete until Command Center v1 accepts a scored agent report and validation evidence.
