# PROMPT TEMPLATES

## 1. Inspection-only template

INSPECTION / PLAN ONLY

Do not edit any files.
Do not run any modifying commands.
Do not apply patches.
Do not refactor anything.

Your task:
1. Inspect the relevant files.
2. Explain what is happening now.
3. Explain the problem or opportunity.
4. Propose the best patch plan.
5. List exactly which files you would change.
6. List the risks.
7. List how I should test it.

Then stop and wait.
Do not edit anything until I explicitly reply with:
APPROVE EDIT

---

## 2. Approval template

APPROVE EDIT

Proceed with the planned patch only.
Do not expand scope.
After editing, summarize:
1. exactly what changed
2. how I should test it
3. any fragile areas still remaining
4. the next best patch, but do not implement it

---

## 3. Bundle prompt opener

Plan a controlled patch bundle.
Do not edit yet.

Bundle goal:
[insert subsystem goal]

Constraints:
- no architecture rewrite
- preserve EventBus
- keep scope coherent
- smallest number of files necessary
- explain before editing
- wait for approval

---

## 4. Post-edit review prompt

Summarize this patch as if you are writing a careful code-review note.

Include:
1. what improved
2. what still looks weak
3. any assumptions that may be wrong
4. what should be tested hard
5. whether this patch should be committed now or needs one more correction
