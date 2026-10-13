# Live reward shell: before / after

Both captures are native `VisualAuditAutoload` frames from the windowed `reward_preview` DebugHarness in `CombatScene` at 1280×720.

- **Before — `before_live_offer_clipped.png`:** the 132×64 live shell can show a creature heading and fragment of its lore line, but its fixed four-line content exceeds the panel height after margins. The DNA gate and the B/E/N timer response are clipped from the player-facing surface.
- **After — `after_live_offer_complete.png`:** the 224×112 transient shell visibly carries creature identity, a compact context line, `BOND DNA 0/10`, and `BOND LOCKED | E/N | 4s` together. It remains in the existing lower-right live-combat lane; no full-screen reward overlay or pause-era flow was introduced.

The after capture happened to render a GORE FANE runtime offer rather than the preset's nominal Knellspine seed. It is therefore evidence that the active live-offer shell can display all four decision lines, not proof that the preview's requested species selection is deterministic. Bond/Eat resolution and the subsequent song-pressure resume were not manually exercised in this unit.
