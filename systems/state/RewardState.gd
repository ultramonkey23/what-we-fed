extends RefCounted
class_name RewardState

const RITUAL_CONTENT = preload("res://data/RitualConsumableContent.gd")

const LOOT_SLOT_LIMITS: Dictionary = {
	"offense": 2,
	"defense": 1,
	"utility": 1
}
const ARTIFACT_SLOT_LIMITS: Dictionary = {
	"major": 1,
	"minor": 1
}

var loot_slots: Dictionary = {
	"offense": [],
	"defense": [],
	"utility": []
}
var artifact_slots: Dictionary = {
	"major": [],
	"minor": []
}
var consumable_slots: Dictionary = {
	"carry": [],
	"prepared": []
}

var bond_streak: int = 0
var eat_streak: int = 0
var bond_total: int = 0
var eat_total: int = 0

var absorbed_types: Array[Dictionary] = []
var active_mutations: Array[Dictionary] = []

func reset_run_state() -> void:
	loot_slots = {
		"offense": [],
		"defense": [],
		"utility": []
	}
	artifact_slots = {
		"major": [],
		"minor": []
	}
	consumable_slots = {
		"carry": [],
		"prepared": []
	}
	bond_streak = 0
	eat_streak = 0
	bond_total = 0
	eat_total = 0
	absorbed_types.clear()
	active_mutations.clear()

func register_choice(choice_id: String) -> void:
	if choice_id == "bond":
		bond_streak += 1
		eat_streak = 0
		bond_total += 1
	elif choice_id == "eat":
		eat_streak += 1
		bond_streak = 0
		eat_total += 1

func get_weight_profile() -> Dictionary:
	return {
		"bond_streak": bond_streak,
		"eat_streak": eat_streak,
		"bond_total": bond_total,
		"eat_total": eat_total
	}

func is_reward_offer_eligible(reward_data: Dictionary) -> bool:
	var lane: String = String(reward_data.get("lane", ""))
	var reward_id: String = String(reward_data.get("id", ""))
	if lane.is_empty() or reward_id.is_empty():
		return false
	if lane == "loot":
		var slot: String = String(reward_data.get("lane_slot", "utility"))
		if not loot_slots.has(slot):
			slot = "utility"
		var target: Array = loot_slots[slot]
		if target.has(reward_id):
			return true
		return target.size() < int(LOOT_SLOT_LIMITS.get(slot, 1))
	if lane == "artifact":
		var artifact_slot: String = String(reward_data.get("lane_slot", "minor"))
		if not artifact_slots.has(artifact_slot):
			artifact_slot = "minor"
		var artifact_target: Array = artifact_slots[artifact_slot]
		if artifact_target.has(reward_id):
			return true
		return artifact_target.size() < int(ARTIFACT_SLOT_LIMITS.get(artifact_slot, 1))
	if lane == "consumable":
		var prepared: Array = consumable_slots["prepared"]
		var carry: Array = consumable_slots["carry"]
		if prepared.has(reward_id) or carry.has(reward_id):
			return true
		if prepared.size() < RITUAL_CONTENT.PREPARED_LIMIT:
			return true
		return carry.size() < RITUAL_CONTENT.CARRY_LIMIT
	return false

func add_reward(reward_data: Dictionary) -> Dictionary:
	var lane: String = String(reward_data.get("lane", ""))
	var reward_id: String = String(reward_data.get("id", ""))
	if lane.is_empty() or reward_id.is_empty():
		return {"accepted": false, "evicted_id": ""}

	if lane == "loot":
		var slot: String = String(reward_data.get("lane_slot", "utility"))
		if not loot_slots.has(slot):
			slot = "utility"
		var target: Array = loot_slots[slot]
		var result: Dictionary = _insert_with_cap(target, reward_id, int(LOOT_SLOT_LIMITS.get(slot, 1)))
		loot_slots[slot] = target
		return result

	if lane == "artifact":
		var artifact_slot: String = String(reward_data.get("lane_slot", "minor"))
		if not artifact_slots.has(artifact_slot):
			artifact_slot = "minor"
		var artifact_target: Array = artifact_slots[artifact_slot]
		var artifact_result: Dictionary = _insert_with_cap(artifact_target, reward_id, int(ARTIFACT_SLOT_LIMITS.get(artifact_slot, 1)))
		artifact_slots[artifact_slot] = artifact_target
		return artifact_result

	if lane == "consumable":
		return add_ritual_consumable(reward_data)

	return {"accepted": false, "evicted_id": ""}

func add_ritual_consumable(reward_data: Dictionary) -> Dictionary:
	var reward_id: String = String(reward_data.get("id", ""))
	if reward_id.is_empty():
		return {"accepted": false, "evicted_id": ""}

	var prepared: Array = consumable_slots["prepared"]
	var carry: Array = consumable_slots["carry"]
	var evicted_id: String = ""

	if not prepared.has(reward_id) and prepared.is_empty():
		prepared.append(reward_id)
		consumable_slots["prepared"] = prepared
		return {"accepted": true, "evicted_id": evicted_id}

	if carry.has(reward_id):
		return {"accepted": true, "evicted_id": ""}
	if carry.size() >= RITUAL_CONTENT.CARRY_LIMIT:
		return {"accepted": false, "evicted_id": ""}
	carry.append(reward_id)
	consumable_slots["carry"] = carry
	return {"accepted": true, "evicted_id": evicted_id}

func consume_prepared_ritual() -> Dictionary:
	var prepared: Array = consumable_slots["prepared"]
	if prepared.is_empty():
		return {}
	var ritual_id: String = String(prepared.pop_front())
	consumable_slots["prepared"] = prepared
	var carry: Array = consumable_slots["carry"]
	if prepared.is_empty() and not carry.is_empty():
		prepared.append(String(carry.pop_front()))
		consumable_slots["prepared"] = prepared
		consumable_slots["carry"] = carry
	return RITUAL_CONTENT.get_ritual(ritual_id)

func _insert_with_cap(target: Array, reward_id: String, cap: int) -> Dictionary:
	if target.has(reward_id):
		return {"accepted": true, "evicted_id": ""}
	if target.size() >= max(cap, 1):
		return {"accepted": false, "evicted_id": ""}
	target.append(reward_id)
	return {"accepted": true, "evicted_id": ""}

func get_snapshot() -> Dictionary:
	return {
		"loot": loot_slots.duplicate(true),
		"artifact": artifact_slots.duplicate(true),
		"consumable": consumable_slots.duplicate(true),
		"weight_profile": get_weight_profile()
	}

func set_slot_primary(lane: String, slot: String, reward_id: String) -> bool:
	var id: String = reward_id.strip_edges()
	if id.is_empty():
		return false
	match lane:
		"loot":
			if not loot_slots.has(slot):
				return false
			var loot_target: Array = loot_slots[slot]
			var loot_idx: int = loot_target.find(id)
			if loot_idx < 0:
				return false
			if loot_idx > 0:
				loot_target.remove_at(loot_idx)
				loot_target.insert(0, id)
				loot_slots[slot] = loot_target
			return true
		"artifact":
			if not artifact_slots.has(slot):
				return false
			var artifact_target: Array = artifact_slots[slot]
			var artifact_idx: int = artifact_target.find(id)
			if artifact_idx < 0:
				return false
			if artifact_idx > 0:
				artifact_target.remove_at(artifact_idx)
				artifact_target.insert(0, id)
				artifact_slots[slot] = artifact_target
			return true
		"consumable":
			var prepared: Array = consumable_slots["prepared"]
			var carry: Array = consumable_slots["carry"]
			if prepared.has(id):
				return true
			if not carry.has(id):
				return false
			carry.erase(id)
			if prepared.is_empty():
				prepared.insert(0, id)
			else:
				var displaced: String = String(prepared.pop_front())
				prepared.insert(0, id)
				if not displaced.is_empty():
					carry.insert(0, displaced)
			while carry.size() > RITUAL_CONTENT.CARRY_LIMIT:
				carry.pop_back()
			consumable_slots["prepared"] = prepared
			consumable_slots["carry"] = carry
			return true
		_:
			return false

func salvage_from_slot(lane: String, slot: String, reward_id: String) -> bool:
	var id: String = reward_id.strip_edges()
	if id.is_empty():
		return false
	match lane:
		"loot":
			if not loot_slots.has(slot):
				return false
			var loot_target: Array = loot_slots[slot]
			var loot_idx: int = loot_target.find(id)
			if loot_idx < 0:
				return false
			loot_target.remove_at(loot_idx)
			loot_slots[slot] = loot_target
			return true
		"artifact":
			if not artifact_slots.has(slot):
				return false
			var artifact_target: Array = artifact_slots[slot]
			var artifact_idx: int = artifact_target.find(id)
			if artifact_idx < 0:
				return false
			artifact_target.remove_at(artifact_idx)
			artifact_slots[slot] = artifact_target
			return true
		"consumable":
			var prepared: Array = consumable_slots["prepared"]
			var carry: Array = consumable_slots["carry"]
			var changed: bool = false
			if prepared.has(id):
				prepared.erase(id)
				changed = true
				if prepared.is_empty() and not carry.is_empty():
					prepared.append(String(carry.pop_front()))
			elif carry.has(id):
				carry.erase(id)
				changed = true
			if changed:
				consumable_slots["prepared"] = prepared
				consumable_slots["carry"] = carry
			return changed
		_:
			return false

func get_summary_lines() -> Array[String]:
	var offense: Array = loot_slots["offense"]
	var defense: Array = loot_slots["defense"]
	var utility: Array = loot_slots["utility"]
	var major: Array = artifact_slots["major"]
	var minor: Array = artifact_slots["minor"]
	var prepared: Array = consumable_slots["prepared"]
	var carry: Array = consumable_slots["carry"]
	return [
		"Loot  |  offense %d/%d  defense %d/%d  utility %d/%d" % [
			offense.size(), int(LOOT_SLOT_LIMITS["offense"]),
			defense.size(), int(LOOT_SLOT_LIMITS["defense"]),
			utility.size(), int(LOOT_SLOT_LIMITS["utility"])
		],
		"Artifacts  |  major %d/%d  minor %d/%d" % [
			major.size(), int(ARTIFACT_SLOT_LIMITS["major"]),
			minor.size(), int(ARTIFACT_SLOT_LIMITS["minor"])
		],
		"Rituals  |  prepared %d/%d  carry %d/%d" % [
			prepared.size(), RITUAL_CONTENT.PREPARED_LIMIT,
			carry.size(), RITUAL_CONTENT.CARRY_LIMIT
		],
		"Bond/Eat pressure  |  bond streak %d  eat streak %d" % [bond_streak, eat_streak]
	]

func get_slot_alerts() -> Array[String]:
	var alerts: Array[String] = []
	var offense: Array = loot_slots["offense"]
	var defense: Array = loot_slots["defense"]
	var utility: Array = loot_slots["utility"]
	var major: Array = artifact_slots["major"]
	var minor: Array = artifact_slots["minor"]
	var prepared: Array = consumable_slots["prepared"]
	var carry: Array = consumable_slots["carry"]

	if offense.size() >= int(LOOT_SLOT_LIMITS["offense"]):
		alerts.append("Loot offense slot sealed")
	if defense.size() >= int(LOOT_SLOT_LIMITS["defense"]):
		alerts.append("Loot defense slot sealed")
	if utility.size() >= int(LOOT_SLOT_LIMITS["utility"]):
		alerts.append("Loot utility slot sealed")
	if major.size() >= int(ARTIFACT_SLOT_LIMITS["major"]):
		alerts.append("Artifact major slot sealed")
	if minor.size() >= int(ARTIFACT_SLOT_LIMITS["minor"]):
		alerts.append("Artifact minor slot sealed")
	if prepared.size() >= RITUAL_CONTENT.PREPARED_LIMIT and carry.size() >= RITUAL_CONTENT.CARRY_LIMIT:
		alerts.append("Ritual slots sealed")
	elif carry.size() >= RITUAL_CONTENT.CARRY_LIMIT:
		alerts.append("Ritual carry slots sealed")

	return alerts
