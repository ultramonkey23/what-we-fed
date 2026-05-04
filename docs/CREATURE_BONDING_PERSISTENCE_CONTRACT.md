# Creature Bonding Persistence Contract

## Authority
Bonding is a permanent creature relationship, not a run reward that expires. Eating is predation economy. Bonding is collection, identity, and support access. Support-slot count controls how many bonded creatures can enter a run; it must never delete or hide the permanent collection.

## State Boundaries
- `lair_roster` is the permanent bonded-creature collection.
- `roster` is the current run's active creature projection.
- `active_lair_creature_ids` is the selected subset of bonded creatures for the next run.
- `meta_support_slots` is meta progression and controls the active support limit.
- Species DNA remains species-specific and should not become a generic collector currency.
- Bond level, spliced traits, exceptional variants, ascension flags, predation debt, and known creature identity are meta state once earned.

## Reset Rules
- Starting, ending, or resetting a run may clear `roster`.
- Starting, ending, or resetting a run must not clear `lair_roster`.
- Starting, ending, or resetting a run must not reduce bond levels.
- Starting, ending, or resetting a run must not reduce `meta_support_slots`.
- Profile wipe/debug reset may clear meta progression only when that is the explicit intent.

## Selection Rules
- Every bonded creature must remain chooseable on future runs.
- Selection UI must page, filter, or otherwise expose the full permanent collection when it exceeds visible slots.
- Removing a creature from active supports must not release it from the lair.
- Support slots limit active choices only.
- If active selections become invalid because a creature was intentionally released, the game should repair selection from remaining bonded creatures.

## Save Contract
Persistent profile serialization must include:
- Permanent bonded roster entries.
- Bond level and slow-leveling progress.
- Active support selections.
- Meta support-slot count.
- Species DNA totals.
- Predation debt.
- Spliced traits, exceptional variants, ascension state, and known creature identity.

## Regression Checks
- Bond a new creature, start a new run, and confirm it remains in the lair.
- Deepen a bond, start a new run, and confirm the bond level did not reset.
- Unlock or grant another support slot, start a new run, and confirm the slot count did not reset.
- Select multiple supports up to the current slot limit, start a run, and confirm all selected supports seed the run roster.
- Exceed visible lair cards with bonded creatures and confirm every bonded creature is still reachable.
- Save, quit, reload, and confirm lair roster, bond levels, support slots, selected supports, and DNA totals persist.

## Anti-Patterns
- Do not make bonded creatures temporary run loot.
- Do not duplicate bonded creatures to represent bond rank.
- Do not silently overwrite a permanent support selection when more than one support slot exists.
- Do not use generic currency in place of species DNA for bond meaning.
- Do not move creature permanence into a deferred ranch-only system.
