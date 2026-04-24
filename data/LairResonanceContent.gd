extends RefCounted

# LairResonanceContent.gd
# Data and constants for World Fate resonance and Kaiju Ascension.

const ASCENSION_DNA_COST: float = 500.0

const RESONANCE_PERKS := {
	"flesh": {
		"id": "flesh",
		"display_name": "Flesh Resonance",
		"splicing_cost_mult": 0.8
	},
	"void": {
		"id": "void",
		"display_name": "Void Resonance",
		"splicing_cost_mult": 0.8
	},
	"neural": {
		"id": "neural",
		"display_name": "Neural Resonance",
		"splicing_cost_mult": 0.8
	}
}

const SPECIES_AFFINITY := {
	"ashclaw": "flesh",
	"gruvek": "flesh",
	"veilskin": "void",
	"hushcoil": "void",
	"knellspine": "neural",
	"marrowward": "neural"
}

const MASTERY_TRAITS := {
	"ashclaw": {"id": "ashclaw_mastery", "title": "Apex Predator"},
	"gruvek": {"id": "gruvek_mastery", "title": "Unstoppable Hunger"},
	"veilskin": {"id": "veilskin_mastery", "title": "Phase Master"},
	"hushcoil": {"id": "hushcoil_mastery", "title": "Silent Death"},
	"knellspine": {"id": "knellspine_mastery", "title": "Resonant Peal"},
	"marrowward": {"id": "marrowward_mastery", "title": "Bone Shield"}
}

static func get_resonance_perk(fate_id: String) -> Dictionary:
	return RESONANCE_PERKS.get(fate_id, {"splicing_cost_mult": 1.0})

static func get_species_affinity(species_id: String) -> String:
	return String(SPECIES_AFFINITY.get(species_id, "unclaimed"))

static func get_mastery_trait(species_id: String) -> Dictionary:
	return MASTERY_TRAITS.get(species_id, {})
