extends Node
## PerkSystem — Manages the 12 tools (6 Active Powers + 6 Passive Perks),
## rarity drop probabilities, 3-slot active power inventory, and card draw logic.

signal powers_changed()
signal perks_changed()

const MAX_ACTIVE_SLOTS := 3

const TOOLS_CATALOG := {
	# 6 Active Powers (HUD bottom 3 slots, hold charges)
	"panda_eye": {
		"id": "panda_eye",
		"name": "Panda Eye",
		"type": "active",
		"rarity": "common",
		"badge_shape": "circle",
		"default_charges": 2,
		"desc": "Shows the next optimal move with a hand animation.",
		"icon": "res://assets/icons/panda_eye.svg"
	},
	"rewind": {
		"id": "rewind",
		"name": "Rewind",
		"type": "active",
		"rarity": "common",
		"badge_shape": "circle",
		"default_charges": 2,
		"desc": "Undoes your last move and refunds the move cost.",
		"icon": "res://assets/icons/rewind.svg"
	},
	"free_spin": {
		"id": "free_spin",
		"name": "Free Spin",
		"type": "active",
		"rarity": "common",
		"badge_shape": "circle",
		"default_charges": 1,
		"desc": "Your next 3 moves in this puzzle cost 0 budget.",
		"icon": "res://assets/icons/free_spin.svg"
	},
	"stretch": {
		"id": "stretch",
		"name": "Stretch",
		"type": "active",
		"rarity": "rare",
		"badge_shape": "diamond",
		"default_charges": 1,
		"desc": "Widens a chosen ring's gap for this puzzle.",
		"icon": "res://assets/icons/stretch.svg"
	},
	"snip": {
		"id": "snip",
		"name": "Snip",
		"type": "active",
		"rarity": "rare",
		"badge_shape": "diamond",
		"default_charges": 1,
		"desc": "Bamboo cutter slices off 1 connector pin.",
		"icon": "res://assets/icons/snip.svg"
	},
	"pop": {
		"id": "pop",
		"name": "Pop",
		"type": "active",
		"rarity": "epic",
		"badge_shape": "hexagon",
		"default_charges": 1,
		"desc": "Bubble-pops and removes 1 ring immediately.",
		"icon": "res://assets/icons/pop.svg"
	},
	# 6 Passive Perks (last for the entire run)
	"thrifty": {
		"id": "thrifty",
		"name": "Thrifty",
		"type": "passive",
		"rarity": "common",
		"badge_shape": "circle",
		"desc": "The first move of every puzzle is free.",
		"icon": "res://assets/icons/thrifty.svg"
	},
	"sharp_mind": {
		"id": "sharp_mind",
		"name": "Sharp Mind",
		"type": "passive",
		"rarity": "common",
		"badge_shape": "circle",
		"desc": "Clean Solve bonus increases from +1 to +3 moves.",
		"icon": "res://assets/icons/sharp_mind.svg"
	},
	"chain_reaction": {
		"id": "chain_reaction",
		"name": "Chain Reaction",
		"type": "passive",
		"rarity": "rare",
		"badge_shape": "diamond",
		"desc": "Releasing 2+ rings in a single move gives +1 move.",
		"icon": "res://assets/icons/chain_reaction.svg"
	},
	"big_tank": {
		"id": "big_tank",
		"name": "Big Tank",
		"type": "passive",
		"rarity": "rare",
		"badge_shape": "diamond",
		"desc": "Increases maximum Move Budget cap from 45 to 55.",
		"icon": "res://assets/icons/big_tank.svg"
	},
	"lucky_paw": {
		"id": "lucky_paw",
		"name": "Lucky Paw",
		"type": "passive",
		"rarity": "rare",
		"badge_shape": "diamond",
		"desc": "Perk choice offers 4 cards instead of 3.",
		"icon": "res://assets/icons/lucky_paw.svg"
	},
	"second_wind": {
		"id": "second_wind",
		"name": "Second Wind",
		"type": "passive",
		"rarity": "epic",
		"badge_shape": "hexagon",
		"desc": "First time budget hits 0, gain +6 moves and survive.",
		"icon": "res://assets/icons/second_wind.svg"
	}
}

var active_slots: Array[Dictionary] = [] # [{id, charges}] up to 3
var passive_perks: Array[String] = []
var second_wind_consumed: bool = false

func reset_for_new_run(starting_power_id: String = "", bonus_charges: int = 0) -> void:
	active_slots.clear()
	passive_perks.clear()
	second_wind_consumed = false
	if starting_power_id != "" and TOOLS_CATALOG.has(starting_power_id):
		add_active_power(starting_power_id, 1 + maxi(0, bonus_charges))
	elif bonus_charges > 0:
		add_active_power("panda_eye", bonus_charges)
	powers_changed.emit()
	perks_changed.emit()

func has_perk(perk_id: String) -> bool:
	return passive_perks.has(perk_id)

func add_active_power(power_id: String, charges: int = 1) -> bool:
	for slot in active_slots:
		if slot["id"] == power_id:
			slot["charges"] = int(slot["charges"]) + charges
			powers_changed.emit()
			return true
	if active_slots.size() < MAX_ACTIVE_SLOTS:
		active_slots.append({"id": power_id, "charges": charges})
		powers_changed.emit()
		return true
	# If all 3 slots are full, add charges to the first slot
	active_slots[0]["charges"] = int(active_slots[0]["charges"]) + charges
	powers_changed.emit()
	return true

func use_active_power(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= active_slots.size():
		return ""
	var slot: Dictionary = active_slots[slot_index]
	if int(slot.get("charges", 0)) <= 0:
		return ""
	var power_id: String = slot["id"]
	slot["charges"] = int(slot["charges"]) - 1
	if int(slot["charges"]) <= 0:
		active_slots.remove_at(slot_index)
	powers_changed.emit()
	return power_id

func apply_card_choice(card: Dictionary) -> void:
	var id: String = card.get("id", "")
	var meta: Dictionary = TOOLS_CATALOG.get(id, {})
	if meta.get("type", "") == "passive":
		if not passive_perks.has(id):
			passive_perks.append(id)
			perks_changed.emit()
	else:
		var charges := int(card.get("charges", meta.get("default_charges", 1)))
		add_active_power(id, charges)

	var picks: Dictionary = SaveService.data["telemetry"]["perk_picks"]
	picks[id] = int(picks.get(id, 0)) + 1
	SaveService.save_game()

func draw_cards(rng: RandomNumberGenerator, is_boss_reward: bool = false, force_rare_only: bool = false) -> Array[Dictionary]:
	var count := 4 if has_perk("lucky_paw") else 3
	var result: Array[Dictionary] = []
	var used_ids: Array[String] = []

	for _i in range(count):
		var target_rarity := _roll_rarity(rng, is_boss_reward, force_rare_only)
		var pool := _get_candidates_by_rarity(target_rarity, used_ids)
		if pool.is_empty():
			pool = _get_candidates_by_rarity("common", used_ids)
		if pool.is_empty():
			break
		var chosen_meta: Dictionary = pool[rng.randi() % pool.size()].duplicate(true)
		used_ids.append(chosen_meta["id"])
		if chosen_meta["type"] == "active":
			chosen_meta["charges"] = int(chosen_meta.get("default_charges", 1))
		result.append(chosen_meta)
	return result

func _roll_rarity(rng: RandomNumberGenerator, is_boss_reward: bool, force_rare_only: bool) -> String:
	if force_rare_only:
		return "rare"
	var roll := rng.randf()
	if is_boss_reward:
		# Boss clear: guaranteed Rare or Epic (20% Epic, 80% Rare)
		return "epic" if roll < 0.20 else "rare"
	# Standard drop rates: Common 70%, Rare 25%, Epic 5%
	if roll < 0.05:
		return "epic"
	elif roll < 0.30:
		return "rare"
	return "common"

func _get_candidates_by_rarity(rarity: String, exclude_ids: Array[String]) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for id in TOOLS_CATALOG.keys():
		if exclude_ids.has(id):
			continue
		var item: Dictionary = TOOLS_CATALOG[id]
		if item["rarity"] != rarity:
			continue
		if item["type"] == "passive" and passive_perks.has(id):
			continue
		list.append(item)
	return list
