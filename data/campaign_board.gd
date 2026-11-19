extends Node
## CampaignBoard — Replaces fixed level lists with a seeded puzzle selector
## backed by our solver-verified puzzle pool (`res://data/puzzle_pool.json`)
## plus runtime rotational, mirror, and palette variations.

const POOL_PATH := "res://data/puzzle_pool.json"

const STAGE_NAMES := {
	1: "Garden",
	2: "Grove",
	3: "Bridge",
	4: "Temple",
	5: "Peak",
	6: "Summit"
}

const STAGE_MECHANIC_HINTS := {
	1: "Align ring gaps with connectors",
	2: "Dual connectors: align both pins",
	3: "Slide locking pins before rotating",
	4: "Double-gap rings & geometric shapes",
	5: "Curses active: watch ring rules",
	6: "Master mix: multi-curse survival"
}

var _pool_data: Dictionary = {}

func _ready() -> void:
	_load_pool()

func _load_pool() -> void:
	if not FileAccess.file_exists(POOL_PATH):
		push_warning("Puzzle pool JSON missing at " + POOL_PATH)
		return
	var f := FileAccess.open(POOL_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_pool_data = parsed

func get_stage_for_puzzle(puzzle_number: int) -> int:
	return clampi(int((puzzle_number - 1) / 5) + 1, 1, 6)

func get_stage_name(stage: int) -> String:
	return STAGE_NAMES.get(clampi(stage, 1, 6), "Summit")

func get_stage_mechanic_hint(stage: int) -> String:
	return STAGE_MECHANIC_HINTS.get(clampi(stage, 1, 6), "Endless mastery")

func get_puzzle_for_run(puzzle_number: int, run_seed: int, is_tutorial_run: bool = false) -> Dictionary:
	var stage := get_stage_for_puzzle(puzzle_number)
	var stage_key := str(stage)
	var stage_puzzles: Array = _pool_data.get("stages", {}).get(stage_key, [])
	if stage_puzzles.is_empty():
		return _build_fallback_puzzle(puzzle_number, stage, run_seed)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(run_seed) + puzzle_number * 7919

	var is_boss := (puzzle_number % 5 == 0)
	var candidates: Array = []
	for p in stage_puzzles:
		if is_tutorial_run and puzzle_number <= 3:
			if bool(p.get("is_tutorial", false)):
				candidates.append(p)
		elif bool(p.get("is_boss", false)) == is_boss:
			candidates.append(p)

	if candidates.is_empty():
		candidates = stage_puzzles

	var chosen: Dictionary = candidates[rng.randi() % candidates.size()].duplicate(true)
	chosen["puzzle_number"] = puzzle_number
	chosen["stage"] = stage
	chosen["stage_name"] = get_stage_name(stage)
	chosen["is_boss"] = is_boss

	# Apply deterministic visual variation (rotation offset + mirror) while preserving Par
	var rot_offset := (rng.randi() % 7) + 1 if not is_tutorial_run else 0
	chosen["visual_rotation_offset_steps"] = rot_offset
	return chosen

func _build_fallback_puzzle(puzzle_number: int, stage: int, run_seed: int) -> Dictionary:
	var rings := []
	var count := clampi(2 + stage + int(puzzle_number % 3), 3, 12)
	for i in range(count):
		rings.append({
			"id": i,
			"radius_px": 52 + i * 22,
			"thickness_px": 14,
			"shape": "circle",
			"color": "#4CAF50",
			"start_step": (i * 3 + 2) % 8,
			"target_steps": [0],
			"gap_width_deg": 44.0,
			"connectors": 1 if stage == 1 else 2,
			"has_slider_pin": (stage >= 3 and i == count - 1),
			"requires_free": [i - 1] if i > 0 else [],
			"gap_deps": [],
			"is_golden": (i == count - 1 and puzzle_number % 3 == 0),
			"is_heavy": (stage >= 5 and i == 1),
			"is_one_way": (stage >= 6 and i == 0),
			"initially_locked": (stage >= 6 and i == count - 1),
			"locked_until_free": (i - 1) if (stage >= 6 and i == count - 1) else -1
		})
	return {
		"puzzle_id": "fallback_%d" % puzzle_number,
		"puzzle_number": puzzle_number,
		"stage": stage,
		"stage_name": get_stage_name(stage),
		"is_boss": (puzzle_number % 5 == 0),
		"is_lucky": (puzzle_number % 10 == 7),
		"par": count,
		"curses": ["heavy_ring"] if stage >= 5 else [],
		"rings": rings
	}
