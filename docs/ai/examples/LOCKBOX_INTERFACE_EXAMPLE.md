# LOCKBOX INTERFACE EXAMPLE

## Fake Lockbox Item
Card: "Add predator intimidation reward after elite kill."
Status: LOCKED FOR LATER
Goal: make elite kills feel more feared and creature-specific.

## LOCKED FOR LATER
This cannot be implemented by a repo agent.

Reason: LOCKED FOR LATER is design intent only. The agent may read the item, but may not treat it as repo truth, create gameplay, change status, or expand it into a reward-system rewrite.

Allowed output:
- "This is design intent only."
- "Route to Command Center v1 for priority/status movement."
- "No implementation handoff exists yet."

## READY FOR AUDIT
Command Center v1 moves the item to READY FOR AUDIT and asks Gemini for repo fit.

Gemini audit prompt includes:
- Lockbox card/status
- current repo truth source
- files to inspect, such as `systems/RunStats.gd`, `data/PerformanceRewardContent.gd`, and relevant reward docs
- forbidden files, such as scenes, combat files, `project.godot`, and input maps
- validation expected: read-only inspection and one bounded next step

Gemini output may conclude:
- current repo supports a reward-copy-only handoff
- current repo does not support an implementation safely yet
- human playtest is needed because the question is feel/readability/fun

## READY FOR HANDOFF
If the audit supports action, the item becomes READY FOR HANDOFF.

Bounded Codex/Claude task:
- "Update the named reward text table only."
- allowed files: one named data or docs file from the audit
- forbidden files: combat, scenes, `project.godot`, input maps, and unrelated systems
- validation required: static diff check plus project data validation if applicable
- report ending: full WHAT WE FED AGENT REPORT

The handoff does not say the Lockbox item is implemented repo truth. It says the current repo evidence supports one bounded implementation task.

## VALIDATED COMPLETE
The item is not complete when the code or docs are changed.

VALIDATED COMPLETE requires:
- agent report passes the Report Ingestion Gate
- scorer returns PASS or an accepted WARN
- validation level matches the claim
- Command Center v1 accepts the status update

Without Command Center v1 acceptance, the repo may have completed work, but the Lockbox card is not VALIDATED COMPLETE.
