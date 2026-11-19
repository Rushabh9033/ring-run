extends Node
## RunController — Core roguelike state machine for Ring Run.
## Tracks Move Budget (start 30, cap 45 / 55 with Big Tank), stage refill %,
## Clean Solve bonuses, Hot Streak coin multipliers, Revive, Shrine, and Daily Run seed.

signal budget_changed(new_budget: int, max_cap: int, delta: int)
signal puzzle_started(puzzle_spec: Dictionary)
signal puzzle_cleared(summary: Dictionary)
signal run_over_triggered(summary: Dictionary)
signal danger_zone_changed(is_danger: bool)

const START_BUDGET := 30
const DEFAULT_BUDGET_CAP := 45
const BIG_TANK_CAP := 55
const REVIVE_MOVES := 8
const SECOND_WIND_MOVES := 6
const BOSS_BONUS_MOVES := 5
const GOLDEN_RING_BONUS_MOVES := 3
const SHRINE_COST_MOVES := 5
const DANGER_ZONE_THRESHOLD := 5

var is_run_active: bool = false
var is_daily_run: bool = false
var is_ranked_daily: bool = false
var run_seed: int = 0
var rng := RandomNumberGenerator.new()

var budget: int = START_BUDGET
var current_puzzle_number: int = 1
var depth_cleared: int = 0
var clean_solves_count: int = 0
var hot_streak: int = 0
var run_coins: int = 0
var revive_used: bool = false
var free_spin_moves_left: int = 0
var puzzle_first_move_taken: bool = false

var current_puzzle_spec: Dictionary = {}
var current_puzzle_state: PuzzleRules.PuzzleState
var history_stack: Array[PuzzleRules.PuzzleState] = []
var move_cost_stack: Array[int] = []

func start_new_run(daily_mode: bool = false) -> void:
	is_daily_run = daily_mode
	if daily_mode:
		var date_str := SaveService.get_local_date_string()
		run_seed = date_str.hash()
		is_ranked_daily = SaveService.can_play_ranked_daily()
	else:
		run_seed = int(Time.get_unix_time_from_system()) ^ randi()
		is_ranked_daily = false

	rng.seed = run_seed
	budget = START_BUDGET
	current_puzzle_number = 1
	depth_cleared = 0
	clean_solves_count = 0
	hot_streak = 0
	run_coins = 0
	revive_used = false
	free_spin_moves_left = 0
	is_run_active = true

	var starter: String = SaveService.data.get("starting_power_id", "")
	var bonus_chg := int(SaveService.data.get("bonus_next_run_charges", 0))
	SaveService.data["bonus_next_run_charges"] = 0
	SaveService.save_game()
	PerkSystem.reset_for_new_run(starter, bonus_chg)

	_emit_budget(0)
	load_current_puzzle()

func get_budget_cap() -> int:
	return BIG_TANK_CAP if PerkSystem.has_perk("big_tank") else DEFAULT_BUDGET_CAP

func get_stage_refill_ratio(stage: int) -> float:
	match stage:
		1:
			return 1.20
		2:
			return 1.00
		3:
			return 0.90
		_:
			return 0.80

func load_current_puzzle() -> void:
	var is_first_install_tutorial := not bool(SaveService.data.get("tutorial_completed", false)) and not is_daily_run
	current_puzzle_spec = CampaignBoard.get_puzzle_for_run(current_puzzle_number, run_seed, is_first_install_tutorial)
	current_puzzle_state = PuzzleRules.create_state_from_spec(current_puzzle_spec)
	history_stack.clear()
	move_cost_stack.clear()
	free_spin_moves_left = 0
	puzzle_first_move_taken = false

	var stage := int(current_puzzle_spec.get("stage", 1))
	AudioService.set_stage_mood(stage, budget <= DANGER_ZONE_THRESHOLD)
	puzzle_started.emit(current_puzzle_spec)

func calculate_move_cost(ring_idx: int) -> int:
	if free_spin_moves_left > 0:
		return 0
	if not puzzle_first_move_taken and PerkSystem.has_perk("thrifty"):
		return 0
	if ring_idx >= 0 and ring_idx < current_puzzle_state.rings.size():
		var r: Dictionary = current_puzzle_state.rings[ring_idx]
		if bool(r.get("is_heavy", false)):
			return 2
	return 1

func commit_player_move(ring_idx: int, new_step: int, is_slider_move: bool = false) -> Dictionary:
	if not is_run_active or current_puzzle_state == null:
		return {"ok": false}

	history_stack.append(current_puzzle_state.clone())
	var cost := calculate_move_cost(ring_idx)
	move_cost_stack.append(cost)

	if free_spin_moves_left > 0:
		free_spin_moves_left -= 1
	puzzle_first_move_taken = true

	if is_slider_move:
		current_puzzle_state.rings[ring_idx]["slider_unlocked"] = true
	else:
		current_puzzle_state.rings[ring_idx]["current_step"] = (new_step % 8 + 8) % 8

	current_puzzle_state.moves_used += 1
	if cost > 0:
		_add_budget(-cost)
		AudioService.play_move_spent()

	var pre_golden := current_puzzle_state.golden_bonus_claimed
	var released_indices := PuzzleRules.evaluate_releases(current_puzzle_state)

	# Golden Ring bonus (+3 moves if released first)
	if not pre_golden and current_puzzle_state.golden_bonus_claimed:
		_add_budget(GOLDEN_RING_BONUS_MOVES)

	# Chain Reaction perk (+1 move when 2+ rings release in a single move)
	if released_indices.size() >= 2 and PerkSystem.has_perk("chain_reaction"):
		_add_budget(1)

	for idx in released_indices:
		var order := current_puzzle_state.rings.size() - current_puzzle_state.remaining_ring_count()
		AudioService.play_release(order)
		PlatformServices.trigger_haptic("ring_release")

	if current_puzzle_state.remaining_ring_count() == 0:
		_handle_puzzle_clear()
		return {"ok": true, "cleared": true, "released": released_indices}

	# Check Run Over if budget hit 0 and rings still remain
	if budget <= 0:
		if PerkSystem.has_perk("second_wind") and not PerkSystem.second_wind_consumed:
			PerkSystem.second_wind_consumed = true
			_add_budget(SECOND_WIND_MOVES)
		else:
			_trigger_run_over()
			return {"ok": true, "run_over": true, "released": released_indices}

	return {"ok": true, "cleared": false, "released": released_indices}

func execute_rewind() -> bool:
	if history_stack.is_empty():
		return false
	current_puzzle_state = history_stack.pop_back()
	var last_cost: int = move_cost_stack.pop_back() if not move_cost_stack.is_empty() else 1
	if last_cost > 0:
		_add_budget(last_cost)
	return true

func activate_free_spin() -> void:
	free_spin_moves_left += 3

func _handle_puzzle_clear() -> void:
	depth_cleared = current_puzzle_number
	if current_puzzle_number >= 3 and not bool(SaveService.data.get("tutorial_completed", false)):
		SaveService.data["tutorial_completed"] = true
		SaveService.save_game()

	var par := int(current_puzzle_spec.get("par", 4))
	var used := current_puzzle_state.moves_used
	var is_clean := (used <= par)
	var clean_bonus := 0
	if is_clean:
		clean_solves_count += 1
		hot_streak += 1
		clean_bonus = 3 if PerkSystem.has_perk("sharp_mind") else 1
	else:
		hot_streak = 0

	var next_spec := CampaignBoard.get_puzzle_for_run(current_puzzle_number + 1, run_seed, false)
	var next_par := int(next_spec.get("par", 4))
	var stage := int(current_puzzle_spec.get("stage", 1))
	var refill_moves := int(ceil(float(next_par) * get_stage_refill_ratio(stage)))

	var is_boss := bool(current_puzzle_spec.get("is_boss", false))
	var boss_bonus := BOSS_BONUS_MOVES if is_boss else 0

	var total_gain := clean_bonus + refill_moves + boss_bonus
	_add_budget(total_gain)

	# Coins calculation with Hot Streak & Boss 3x multiplier
	var base_coins := 10
	var streak_mult := 3 if hot_streak >= 5 else (2 if hot_streak >= 3 else 1)
	var boss_mult := 3 if is_boss else 1
	var earned_coins := base_coins * streak_mult * boss_mult
	run_coins += earned_coins

	AudioService.play_level_clear(is_clean)
	PlatformServices.trigger_haptic("puzzle_clear")

	puzzle_cleared.emit({
		"puzzle_number": current_puzzle_number,
		"par": par,
		"moves_used": used,
		"is_clean_solve": is_clean,
		"clean_bonus": clean_bonus,
		"refill_moves": refill_moves,
		"boss_bonus": boss_bonus,
		"is_boss": is_boss,
		"is_lucky": bool(current_puzzle_spec.get("is_lucky", false)),
		"earned_coins": earned_coins,
		"hot_streak": hot_streak
	})

func advance_to_next_puzzle() -> void:
	current_puzzle_number += 1
	load_current_puzzle()

func can_use_shrine() -> bool:
	return budget > SHRINE_COST_MOVES

func spend_shrine_for_rare_card() -> Array[Dictionary]:
	if not can_use_shrine():
		return []
	_add_budget(-SHRINE_COST_MOVES)
	return PerkSystem.draw_cards(rng, false, true)

func revive_with_rewarded_ad() -> bool:
	if revive_used:
		return false
	revive_used = true
	is_run_active = true
	_add_budget(REVIVE_MOVES)
	AudioService.play_revive()
	return true

func _trigger_run_over() -> void:
	is_run_active = false
	var is_new_best := SaveService.record_run_result(depth_cleared, budget, run_coins, is_daily_run, clean_solves_count)
	if is_daily_run and is_ranked_daily:
		PlatformServices.submit_leaderboard_score("ring_run_daily", depth_cleared)
	PlatformServices.submit_leaderboard_score("ring_run_best_depth", depth_cleared)
	AudioService.play_run_over()
	PlatformServices.trigger_haptic("run_over")
	run_over_triggered.emit({
		"depth": depth_cleared,
		"best_depth": int(SaveService.data.get("best_depth", depth_cleared)),
		"is_new_best": is_new_best,
		"run_coins": run_coins,
		"clean_solves": clean_solves_count,
		"can_revive": not revive_used,
		"is_daily": is_daily_run,
		"share_card": SaveService.format_daily_share_card(depth_cleared, clean_solves_count)
	})

func _add_budget(delta: int) -> void:
	var cap := get_budget_cap()
	if delta > 0:
		budget = mini(cap, budget + delta)
	else:
		budget = maxi(0, budget + delta)
	_emit_budget(delta)

func _emit_budget(delta: int) -> void:
	budget_changed.emit(budget, get_budget_cap(), delta)
	danger_zone_changed.emit(budget <= DANGER_ZONE_THRESHOLD and budget > 0)
