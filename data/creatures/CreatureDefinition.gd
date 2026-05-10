extends RefCounted
class_name CreatureDefinition

# Shared creature contract for per-creature behavior files.
# Each creature extends this and overrides the methods it needs.
# Methods not overridden return safe empty/default values.
#
# How to add a new creature:
#   1. Create data/creatures/<species_id>_definition.gd
#   2. extends CreatureDefinition
#   3. Override any hooks relevant to that creature's identity
#   4. The creature's base stats + support resolver stay in CombatContent.gd + SupportEffectResolver.gd
#   5. The definition file provides: named role, mawtype, species trait, bond passive, support technique,
#      DNA echo, creature/bond level behavior, codex flavor, optional witnessed mutation seed
#
# This contract does not replace CombatContent.gd CREATURES entries.
# It enriches them with named, readable identity that survives refactors.

func get_species_id() -> String:
	return ""

func get_display_name() -> String:
	return ""

# Role is a design label, not a runtime stat.
# Examples: "Predator Striker", "Anchor Ward", "Phantom Counter"
func get_role() -> String:
	return ""

# Primary appetite / mawtype. Design label for what this creature hungers for.
# May not exist as a runtime stat — each definition should note the runtime mapping.
# Examples: "Fang", "Gorge", "Hush", "Bond", "Cadence"
func get_mawtype() -> String:
	return ""

func get_secondary_appetites() -> Array[String]:
	return []

func get_synergy_tags() -> Array[String]:
	return []

# Power tier is a design label only. Not a runtime modifier.
# Valid values: "Common", "Unusual", "Elite", "Boss-Born", "Omen", "Mythic"
func get_power_tier() -> String:
	return "Common"

# Unlock rule describes the design condition for first bonding.
# Not a runtime enforcement — just documents the intended unlock path.
func get_unlock_rule() -> String:
	return ""

# Named species trait: the passive behavior that defines this creature's combat identity.
# Returns: { "name", "summary", "trigger", "effect_id", "full_text" }
# "effect_id" must match an entry in SupportEffectResolver if it uses the support system.
func get_species_trait() -> Dictionary:
	return {}

# Named bond passive: the always-on benefit the Vessel gains while bonded.
# Returns: { "name", "summary", "stat_type", "value", "full_text" }
# "stat_type" should be an existing effect type in CombatContent bond_passive.
func get_bond_passive() -> Dictionary:
	return {}

# Named support technique: what this creature visibly does when triggered in combat.
# Returns: { "name", "summary", "effect_id", "trigger_on", "effect_value", "hud_hint", "full_text" }
# Runtime behavior lives in SupportEffectResolver under "effect_id".
func get_support_technique() -> Dictionary:
	return {}

# DNA Echo: what remains in the Vessel after eating this creature.
# Eating is a separate path from bonding. Echo is not a bond benefit.
# Returns: { "name", "summary", "effect_type", "value", "eat_vs_bond", "full_text" }
func get_dna_echo() -> Dictionary:
	return {}

# Human-readable description of how creature level improves this creature's potency.
# Runtime scaling lives in GameState.get_creature_level_mult(). This just documents it.
func get_creature_level_behavior() -> String:
	return ""

# Bond level perks: what each bond level adds for this specific creature.
# Runtime bond mult lives in GameState.get_bond_level_mult(). This adds flavor + specifics.
# Returns: { 1: { "perk_name", "summary" }, 2: { ... }, ... }
func get_bond_level_perks() -> Dictionary:
	return {}

# Codex and lair flavor text entries for this creature.
# Returns: { "lair_text", "archive_text", "signal_flavor", "wrong_detail" }
func get_codex_flavor() -> Dictionary:
	return {}

# Data-only witnessed mutation hook. No logic. No implementation.
# Seeds a future behavior-grown mutation condition.
# Returns: { "id", "name", "condition_text", "future_effect_hint", "status" }
func get_witnessed_mutation_hook() -> Dictionary:
	return {}

# Optional custom combat event hook for future creatures that need behavior
# outside the existing SupportEffectResolver match block.
# Return empty dict to defer to SupportEffectResolver (default for all current creatures).
# Return non-empty dict to signal that this creature handles the event itself.
func on_combat_event(_event_id: String, _ctx: Dictionary) -> Dictionary:
	return {}
