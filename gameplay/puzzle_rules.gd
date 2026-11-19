class_name PuzzleRules
extends RefCounted
## PuzzleRules — Pure state model and validation rules for Ring Run puzzles.
## Supports cloning (`clone()`) for Rewind power and BFS Solver exploration.

class PuzzleState:
	var rings: Array[Dictionary] = []
	var moves_used: int = 0
	var golden_bonus_claimed: bool = false
	var first_released_ring_id: int = -1

	func clone() -> PuzzleState:
		var copy := PuzzleState.new()
		for r in rings:
			copy.rings.append(r.duplicate(true))
		copy.moves_used = moves_used
		copy.golden_bonus_claimed = golden_bonus_claimed
		copy.first_released_ring_id = first_released_ring_id
		return copy

	func remaining_ring_count() -> int:
		var count := 0
		for r in rings:
			if not bool(r.get("released", false)):
				count += 1
		return count

static func create_state_from_spec(puzzle_spec: Dictionary) -> PuzzleState:
	var st := PuzzleState.new()
	var raw_rings: Array = puzzle_spec.get("rings", [])
	for r in raw_rings:
		var item: Dictionary = r.duplicate(true)
		item["current_step"] = int(item.get("start_step", 0)) % 8
		item["released"] = false
		item["slider_unlocked"] = not bool(item.get("has_slider_pin", false))
		item["stretched"] = false
		st.rings.append(item)
	return st

static func can_rotate_ring(state: PuzzleState, ring_idx: int, direction_sign: int = 1) -> Dictionary:
	if ring_idx < 0 or ring_idx >= state.rings.size():
		return {"ok": false, "reason": "invalid_index"}
	var r: Dictionary = state.rings[ring_idx]
	if bool(r.get("released", false)):
		return {"ok": false, "reason": "already_released"}
	if not bool(r.get("slider_unlocked", true)):
		return {"ok": false, "reason": "slider_pin_locked"}
	var lock_dep := int(r.get("locked_until_free", -1))
	if bool(r.get("initially_locked", false)) and lock_dep >= 0 and lock_dep < state.rings.size():
		if not bool(state.rings[lock_dep].get("released", false)):
			return {"ok": false, "reason": "locked_ring_curse"}
	if bool(r.get("is_one_way", false)) and direction_sign < 0:
		return {"ok": false, "reason": "one_way_curse"}
	return {"ok": true, "reason": ""}

static func evaluate_releases(state: PuzzleState) -> Array[int]:
	var newly_released: Array[int] = []
	var changed := true
	while changed:
		changed = false
		for idx in range(state.rings.size()):
			var r: Dictionary = state.rings[idx]
			if bool(r.get("released", false)):
				continue
			if not bool(r.get("slider_unlocked", true)):
				continue
			# Check prerequisite rings
			var prereq_ok := true
			for req_idx in r.get("requires_free", []):
				var rq := int(req_idx)
				if rq >= 0 and rq < state.rings.size() and not bool(state.rings[rq].get("released", false)):
					prereq_ok = false
					break
			if not prereq_ok:
				continue
			# Check target alignment
			var cur_step := int(r.get("current_step", 0)) % 8
			var targets: Array = r.get("target_steps", [0])
			var aligned := false
			for t in targets:
				if int(t) % 8 == cur_step:
					aligned = true
					break
				if bool(r.get("stretched", false)) and absi((int(t) - cur_step) % 8) <= 1:
					aligned = true
					break
			if not aligned:
				continue
			r["released"] = true
			if state.first_released_ring_id == -1:
				state.first_released_ring_id = int(r.get("id", idx))
				if bool(r.get("is_golden", false)):
					state.golden_bonus_claimed = true
			newly_released.append(idx)
			changed = true
	return newly_released
