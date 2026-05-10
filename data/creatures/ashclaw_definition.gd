extends CreatureDefinition
class_name AshclawDefinition

# ASHCLAW — Predator Striker
# First per-creature definition file.
#
# This file NAMES and DOCUMENTS existing Ashclaw behavior.
# It does NOT replace:
#   - CREATURES["ashclaw"] in CombatContent.gd (base stats, sprite paths, capture threshold)
#   - "ashclaw_strike" in SupportEffectResolver.gd (bleed stack + Rupture chain runtime)
#   - bond_passive / eat_effect / mutation entries in CombatContent.gd
#   - CREATURE_CLASS_PROFILE["ashclaw"] (GLASS CANNON stat modifiers)
#
# Mapping from CombatContent to named framework:
#   support_role.effect_id "ashclaw_strike"         → Species Trait: Rend the Opening
#   support_role.effect_id "ashclaw_strike"         → Support Technique: Claw Lunge
#   bond_passive.type "damage_on_ultimate" (5.0)    → Bond Passive: Predator's Patience
#   eat_effect.type "damage_flat" (2.0)             → DNA Echo: Fang Echo
#   mutation "ashclaw_frenzy"                       → Existing reward-path mutation (preserved, not moved)
#   trigger_on ["perfect_parry", "perfect_timed_attack"] → Trigger Grammar
#   potential_max_grade "alpha" → creature level cap 8

func get_species_id() -> String:
	return "ashclaw"

func get_display_name() -> String:
	return "Ashclaw"

func get_role() -> String:
	return "Predator Striker"

# Primary appetite. Design label maps to runtime affinity: "flesh".
# "Fang" does not exist as a discrete runtime stat.
# Runtime mapping: damage_on_ultimate (bond passive) + timed hit damage bonuses.
func get_mawtype() -> String:
	return "Fang"

func get_secondary_appetites() -> Array[String]:
	return ["Nerve", "Bond"]

func get_synergy_tags() -> Array[String]:
	return ["bleed", "rupture", "punish", "predator", "fang"]

# Unusual: stronger than Common threshold starters.
# Available in feeding_hollow_01 (encounter 1), so not Elite.
# Earnable early but requires exact-species DNA spend (8.0 threshold).
func get_power_tier() -> String:
	return "Unusual"

func get_unlock_rule() -> String:
	return "Spend 8 Ashclaw DNA to first-bond. Archive re-bond is free. DNA threshold from CombatContent.dna_threshold."

# --- Species Trait ---
# "Rend the Opening" names the core Ashclaw trigger loop.
# Runtime: SupportEffectResolver "ashclaw_strike" — bleed stacks globally, Rupture at 5+ stacks.
# Trigger: perfect_parry or perfect_timed_attack (from support_role.trigger_on).
func get_species_trait() -> Dictionary:
	return {
		"name": "Rend the Opening",
		"summary": "Ashclaw smells the opening. Perfect timing turns prey soft.",
		"trigger": "perfect_parry or perfect_timed_attack",
		"effect_id": "ashclaw_strike",
		"full_text": "Ashclaw rewards clean violence. Each qualifying strike builds blood-scent on all targets (bleed stacks, +3 base, +4 on cadence surge). At 5 stacks: Rupture — direct damage at 2.2× bond mult plus global cleave at 45% power. Reads as BLOOD SCENT (building) or ASHCLAW RUPTURE (chain)."
	}

# --- Bond Passive ---
# "Predator's Patience" names the existing damage_on_ultimate bond passive.
# Runtime: CombatContent bond_passive type "damage_on_ultimate", value 5.0.
# Mawtype note: "Fang" appetite maps to damage_on_ultimate. No discrete Fang stat exists.
func get_bond_passive() -> Dictionary:
	return {
		"name": "Predator's Patience",
		"summary": "Bond: Ashclaw waits for your cleanest violence.",
		"stat_type": "damage_on_ultimate",
		"value": 5.0,
		"full_text": "Ashclaw withholds until the Vessel commits everything. When Ultimate fires, Ashclaw's bond adds +5 damage. Patience rewarded.",
		"mawtype_note": "Fang appetite maps to damage_on_ultimate. No runtime Fang stat exists in this codebase."
	}

# --- Support Technique ---
# "Claw Lunge" names the ashclaw_strike support effect.
# Runtime: SupportEffectResolver "ashclaw_strike". Trigger handled by RunGrowth → CombatScene.
func get_support_technique() -> Dictionary:
	return {
		"name": "Claw Lunge",
		"summary": "Claw Lunge: Ashclaw tears into an opened target.",
		"effect_id": "ashclaw_strike",
		"trigger_on": ["perfect_parry", "perfect_timed_attack"],
		"effect_value": 10.0,
		"hud_hint": "Parry/timed hit",
		"feedback_text": "ASHCLAW",
		"full_text": "After a perfect parry or timed hit, Ashclaw lashes across all enemies. Bleed stacks accumulate. At threshold: Rupture chain fires. Claw Lunge does not play the game for the player — it rewards the read.",
		"readout_name": "Ashclaw"
	}

# --- DNA Echo ---
# "Fang Echo" names the eat_effect: damage_flat (2.0).
# Eating is a separate path from bonding. Echo is not a bond benefit.
# Eating also: +lineage DNA (half dna_threshold), predation debt +1, absorbed_types record.
func get_dna_echo() -> Dictionary:
	return {
		"name": "Fang Echo",
		"summary": "Eat: The claw becomes memory under the shell.",
		"effect_type": "damage_flat",
		"value": 2.0,
		"full_text": "Eating Ashclaw does not bond it. The Vessel absorbs the fang as body-memory: +2 flat damage on all attacks, a ghost of the cut carried forward.",
		"eat_vs_bond": "Eat path: Fang Echo (damage_flat +2) + lineage DNA + predation debt. Bond path: Claw Lunge + Predator's Patience + roster entry. These paths are mutually exclusive in a single combat reward."
	}

# --- Creature Level Behavior ---
# Runtime: GameState.get_creature_level_mult(level) = 1.0 + (level-1) * 0.04
# Ashclaw grade: alpha → cap 8 (from GameState.CREATURE_LEVEL_MAX_BY_GRADE).
# Creature level is combat/support scaling, separate from bond level.
func get_creature_level_behavior() -> String:
	return "Each creature level adds 4% to Claw Lunge potency (bleed damage and Rupture damage scale with bond_mult from SupportEffectResolver). Cap: 8 levels (alpha grade). Creature XP: 8.0 per enemy kill while Ashclaw is active bonded creature."

# --- Bond Level Perks ---
# Runtime: GameState.get_bond_level_mult(level) = 1.0 + (level-1) * 0.20
# Bond level is lair-trained only — not granted in combat.
# Bond level is separate from creature level. Both stack independently.
func get_bond_level_perks() -> Dictionary:
	return {
		1: {"perk_name": "First Pact", "summary": "Ashclaw responds. Claw Lunge active at base potency."},
		2: {"perk_name": "Scent Learned", "summary": "+20% Claw Lunge potency. Ashclaw reads the fight faster."},
		3: {"perk_name": "Shared Kill", "summary": "+40% Claw Lunge potency. Growth stage: teen."},
		4: {"perk_name": "Marked Territory", "summary": "+60% Claw Lunge potency. Growth stage: adult."},
		5: {"perk_name": "Apex Convergence", "summary": "+80% Claw Lunge potency. Exceptional variant available."}
	}

# --- Codex/Lair Flavor ---
# Mirrors existing CombatContent description/signal_flavor/wrong_detail.
func get_codex_flavor() -> Dictionary:
	return {
		"lair_text": "Ashclaw does not pace. It stands at the back of the space and watches the door.",
		"archive_text": "It learned to cut before it learned the cost of stopping.",
		"signal_flavor": "The air near its claws smells of ozone and old, dry blood.",
		"wrong_detail": "claws worn completely flat but still cutting",
		"quig_offer": "Quig: \"Mind the claws. It reads fear as a cue.\""
	}

# --- Witnessed Mutation Hook (data-only) ---
# Future condition seed. No runtime implementation.
# The existing ashclaw_frenzy mutation travels via the reward system — this is separate.
func get_witnessed_mutation_hook() -> Dictionary:
	return {
		"id": "ash_awakening",
		"name": "Ash Awakening",
		"condition_text": "Trigger 10 perfect parries while Ashclaw is active bonded creature in a single run.",
		"future_effect_hint": "Claw Lunge gains a second hit. Rupture threshold drops from 5 to 4 stacks.",
		"status": "data_only_not_implemented"
	}

# on_combat_event: Ashclaw behavior is fully handled by SupportEffectResolver "ashclaw_strike".
# Return empty to defer — no duplicate logic here.
func on_combat_event(_event_id: String, _ctx: Dictionary) -> Dictionary:
	return {}
