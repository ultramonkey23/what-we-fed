class_name GrowthStats extends Resource

@export var genetic_weights: Dictionary = {
	"predator": {"stat_power": 3, "stat_swiftness": 2, "stat_adaptability": 1},
	"bond": {"stat_intelligence": 3, "stat_potential": 2, "stat_luck": 1},
	"guard": {"stat_carapace": 3, "stat_vitality": 2, "stat_endurance": 1},
	"flesh": {"stat_vitality": 3, "stat_power": 1, "stat_adaptability": 2},
	"bone": {"stat_carapace": 3, "stat_endurance": 2, "stat_vitality": 1},
	"grit": {"stat_endurance": 3, "stat_carapace": 1, "stat_power": 2},
	"reflex": {"stat_swiftness": 3, "stat_adaptability": 2, "stat_intelligence": 1},
	"gorge": {"stat_vitality": 3, "stat_power": 2, "stat_potential": 1},
	"hollow": {"stat_potential": 3, "stat_luck": 2, "stat_intelligence": 1},
	"cadence": {"stat_swiftness": 3, "stat_intelligence": 2, "stat_adaptability": 1},
	"spine": {"stat_power": 3, "stat_swiftness": 2, "stat_carapace": 1},
	"veil": {"stat_luck": 3, "stat_intelligence": 2, "stat_potential": 1},
	"pressure": {"stat_adaptability": 3, "stat_power": 2, "stat_swiftness": 1},
	"edge": {"stat_power": 3, "stat_adaptability": 2, "stat_swiftness": 1}
}

@export var default_surges: Dictionary = {
	"aggression": 0.0,
	"cadence": 0.0,
	"guard": 0.0,
	"bond": 0.0
}
