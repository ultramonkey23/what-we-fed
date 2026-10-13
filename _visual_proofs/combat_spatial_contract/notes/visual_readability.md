# Control-focus spatial witness

`control_focus_centered_player.png` is a native `VisualAuditAutoload` F12 capture taken from `res://scenes/combat/CombatScene.tscn` at 1280×720 during the live `control_focus` harness.

Observed in the frame: the player is visibly centered on the arena's central visual sigil rather than at the top-left origin. The adjacent metadata records the north hit zone at `(640, 250)`, east at `(750, 360)`, and the remaining cardinal lane geometry around the same arena center. This is consistent with the repaired `PlayerCombat` physical origin being the `ZoneManager` arena center.

Limit: the capture is a spatial/readability witness, not a manual play-feel assessment and not a visual inspection of an attack VFX at the outer edge of the timing ring. The N/E/S/W response and projectile clearance claims are established by the live control sequence in `logs/control_focus_runtime.log`.
