extends Node
## SaveService — Persists player progress, best depth, collection unlocks,
## Daily Run records, 7-day streak calendar, and accessibility settings.
## Uses a clean save path ("user://ring_run_save_v1.json") with zero legacy Rotate Rings data.

signal save_updated()

const SAVE_PATH := "user://ring_run_save_v1.json"

var data: Dictionary = {
	"best_depth": 0,
	"best_depth_remaining_moves": 0,
	"total_runs": 0,
	"coins": 120,
	"tutorial_completed": false,
	"unlocked_powers": ["panda_eye", "rewind", "free_spin"],
	"unlocked_perks": ["thrifty", "sharp_mind", "chain_reaction", "big_tank", "lucky_paw", "second_wind"],
	"starting_power_id": "",
	"bonus_next_run_charges": 0,
	"daily_bonus_ads_watched_today": 0,
	"daily_bonus_ads_date": "",
	"unlocked_outfits": ["classic_bamboo"],
	"equipped_outfit": "classic_bamboo",
	"remove_ads_purchased": false,
	"daily_run": {
		"last_played_date": "",
		"ranked_attempt_used": false,
		"today_best_depth": 0,
		"today_clean_solves": 0,
		"streak_days": 0,
		"last_streak_date": "",
		"history": {}
	},
	"settings": {
		"sound_enabled": true,
		"music_enabled": true,
		"haptics_enabled": true,
		"reduced_motion": false
	},
	"telemetry": {
		"perk_picks": {},
		"death_puzzle_histogram": {}
	}
}

func _ready() -> void:
	load_game()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_game()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var raw := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) == TYPE_DICTIONARY:
		_merge_dict(data, parsed)

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	save_updated.emit()

func _merge_dict(target: Dictionary, patch: Dictionary) -> void:
	for k in patch.keys():
		if target.has(k) and typeof(target[k]) == TYPE_DICTIONARY and typeof(patch[k]) == TYPE_DICTIONARY:
			_merge_dict(target[k], patch[k])
		else:
			target[k] = patch[k]

func record_run_result(depth: int, remaining_moves: int, earned_coins: int, is_daily: bool, clean_solves: int) -> bool:
	data["total_runs"] = int(data.get("total_runs", 0)) + 1
	data["coins"] = int(data.get("coins", 0)) + earned_coins
	var is_new_best := false
	var prev_best := int(data.get("best_depth", 0))
	var prev_tie := int(data.get("best_depth_remaining_moves", 0))
	if depth > prev_best or (depth == prev_best and remaining_moves > prev_tie):
		data["best_depth"] = depth
		data["best_depth_remaining_moves"] = remaining_moves
		is_new_best = true

	var hist: Dictionary = data["telemetry"]["death_puzzle_histogram"]
	var key := str(depth + 1)
	hist[key] = int(hist.get(key, 0)) + 1

	if is_daily:
		_record_daily_attempt(depth, clean_solves)

	save_game()
	return is_new_best

func _record_daily_attempt(depth: int, clean_solves: int) -> void:
	var today := get_local_date_string()
	var d: Dictionary = data["daily_run"]
	if d.get("last_played_date", "") != today:
		d["last_played_date"] = today
		d["ranked_attempt_used"] = true
		d["today_best_depth"] = depth
		d["today_clean_solves"] = clean_solves
		_advance_streak(today)
	else:
		d["ranked_attempt_used"] = true
		if depth > int(d.get("today_best_depth", 0)):
			d["today_best_depth"] = depth
			d["today_clean_solves"] = clean_solves
	d["history"][today] = {
		"depth": d["today_best_depth"],
		"clean_solves": d["today_clean_solves"]
	}

func _advance_streak(today: String) -> void:
	var d: Dictionary = data["daily_run"]
	var prev_date: String = d.get("last_streak_date", "")
	if prev_date == today:
		return
	d["streak_days"] = int(d.get("streak_days", 0)) + 1
	d["last_streak_date"] = today
	# Daily streak reward: +1 charge for next run
	data["bonus_next_run_charges"] = int(data.get("bonus_next_run_charges", 0)) + 1

func get_local_date_string() -> String:
	var dt := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]

func get_daily_number() -> int:
	# Days since launch epoch (2026-10-01)
	var unix := int(Time.get_unix_time_from_system())
	var epoch := 1790812800
	return maxi(1, int((unix - epoch) / 86400) + 1)

func can_play_ranked_daily() -> bool:
	var today := get_local_date_string()
	var d: Dictionary = data["daily_run"]
	if d.get("last_played_date", "") != today:
		return true
	return not bool(d.get("ranked_attempt_used", false))

func format_daily_share_card(depth: int, clean_solves: int) -> String:
	return "Daily #%d · Depth %d · %d Clean Solves" % [get_daily_number(), depth, clean_solves]

func unlock_power(power_id: String, cost: int) -> bool:
	if int(data.get("coins", 0)) < cost:
		return false
	data["coins"] = int(data["coins"]) - cost
	var arr: Array = data["unlocked_powers"]
	if not arr.has(power_id):
		arr.append(power_id)
	data["starting_power_id"] = power_id
	save_game()
	return true

func is_reduced_motion() -> bool:
	return bool(data["settings"].get("reduced_motion", false))
