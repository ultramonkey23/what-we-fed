extends RefCounted

# LairResonanceContent.gd
# Data and constants for World Fate resonance and Kaiju Ascension.
const COMBAT_DATA_CONTENT = preload("res://data/CombatContent.gd")

const ASCENSION_DNA_COST: float = 500.0

const WORLD_FATE_IDS: Array[String] = [
	"predatory_brutal",
	"mythic_hopeful",
	"sterile_technocratic",
	"haunted_ritual"
]

const LEGACY_RESONANCE_TO_FATE := {
	"flesh": "predatory_brutal",
	"void": "haunted_ritual",
	"neural": "sterile_technocratic"
}

const COMBAT_AFFINITY_TO_FATE := {
	"flesh": "predatory_brutal",
	"gorge": "predatory_brutal",
	"cadence": "haunted_ritual",
	"reflex": "haunted_ritual",
	"hush": "haunted_ritual",
	"guard": "mythic_hopeful",
	"hollow": "mythic_hopeful"
}

const RESONANCE_PERKS := {
	"predatory_brutal": {
		"id": "predatory_brutal",
		"display_name": "Predatory Resonance",
		"splicing_cost_mult": 0.8
	},
	"mythic_hopeful": {
		"id": "mythic_hopeful",
		"display_name": "Mythic Resonance",
		"splicing_cost_mult": 0.8
	},
	"sterile_technocratic": {
		"id": "sterile_technocratic",
		"display_name": "Technocratic Resonance",
		"splicing_cost_mult": 0.8
	},
	"haunted_ritual": {
		"id": "haunted_ritual",
		"display_name": "Haunted Resonance",
		"splicing_cost_mult": 0.8
	}
}

const SPECIES_AFFINITY := {
	"ashclaw": "predatory_brutal",
	"bond_remnant": "mythic_hopeful",
	"gruvek": "predatory_brutal",
	"veilskin": "haunted_ritual",
	"thornback": "predatory_brutal",
	"knellspine": "haunted_ritual",
	"marrowward": "mythic_hopeful",
	"gorefane": "predatory_brutal",
	"hushcoil": "haunted_ritual",
	"coldvein": "haunted_ritual",
	"siltgrip": "predatory_brutal"
}

const MASTERY_TRAITS := {
	"ashclaw": {
		"id": "ashclaw_mastery",
		"title": "Apex Predator",
		"description": "Predatory lunges bite harder into wounded targets and make Ashclaw support favor finishing pressure."
	},
	"gruvek": {
		"id": "gruvek_mastery",
		"title": "Unstoppable Hunger",
		"description": "Sustained aggression thickens support charge flow after kills and rewards relentless routes."
	},
	"veilskin": {
		"id": "veilskin_mastery",
		"title": "Phase Master",
		"description": "Perfect defensive timing opens brief evasive support windows and favors spectral counterplay."
	},
	"hushcoil": {
		"id": "hushcoil_mastery",
		"title": "Silent Death",
		"description": "Clean, quiet chains strengthen support precision and punish enemies before they fully speak."
	},
	"knellspine": {
		"id": "knellspine_mastery",
		"title": "Resonant Peal",
		"description": "On-beat mastery expands cadence support and makes phrase windows feel more ritualized."
	},
	"marrowward": {
		"id": "marrowward_mastery",
		"title": "Bone Shield",
		"description": "Guarded play converts support into survival pressure and reinforces the Codex after hard reads."
	}
}

static func get_resonance_perk(fate_id: String) -> Dictionary:
	var normalized_fate_id: String = _normalize_fate_id(fate_id)
	return RESONANCE_PERKS.get(normalized_fate_id, {"splicing_cost_mult": 1.0})

static func get_species_affinity(species_id: String) -> String:
	# Returns WorldFateState-compatible IDs for ascension gate comparisons.
	if SPECIES_AFFINITY.has(species_id):
		return String(SPECIES_AFFINITY.get(species_id, "unclaimed"))

	var creature: Dictionary = COMBAT_DATA_CONTENT.get_creature(species_id)
	var affinity_id: String = String(creature.get("affinity", "")).to_lower()
	var mapped_fate_id: String = String(COMBAT_AFFINITY_TO_FATE.get(affinity_id, "unclaimed"))
	return _normalize_fate_id(mapped_fate_id)

static func get_mastery_trait(species_id: String) -> Dictionary:
	if MASTERY_TRAITS.has(species_id):
		return MASTERY_TRAITS.get(species_id, {}).duplicate(true)
	var creature: Dictionary = COMBAT_DATA_CONTENT.get_creature(species_id)
	var display_name: String = String(creature.get("display_name", species_id)).strip_edges()
	if display_name.is_empty():
		display_name = "Unknown Lineage"
	return {
		"id": "%s_mastery" % species_id,
		"title": "%s Sovereignty" % display_name,
		"description": "Ascension rewrites this lineage into a Sovereign support trait. Its exact combat expression should be authored before final balance."
	}

static func _normalize_fate_id(fate_id: String) -> String:
	var normalized: String = fate_id.to_lower()
	if LEGACY_RESONANCE_TO_FATE.has(normalized):
		normalized = String(LEGACY_RESONANCE_TO_FATE.get(normalized, "unclaimed"))
	if WORLD_FATE_IDS.has(normalized):
		return normalized
	return "unclaimed"
