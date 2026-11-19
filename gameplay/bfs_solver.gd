class_name BfsSolver
extends RefCounted
## BfsSolver — Runtime optimal move solver for Ring Run.
## Powers both the "Par" calculation/verification and the "Panda Eye" active power hint.

static func find_next_optimal_move(state: PuzzleRules.PuzzleState) -> Dictionary:
	var solution := solve_state(state, 16)
	if solution.is_empty():
		# Fallback: find first unreleased ring and point to its primary target_step
		for idx in range(state.rings.size()):
			var r: Dictionary = state.rings[idx]
			if not bool(r.get("released", false)):
				if not bool(r.get("slider_unlocked", true)):
					return {"type": "slide_pin", "ring_index": idx, "target_step": int(r.get("current_step", 0))}
				var targets: Array = r.get("target_steps", [0])
				return {"type": "rotate", "ring_index": idx, "target_step": int(targets[0])}
		return {}
	return solution[0]

static func solve_state(initial_state: PuzzleRules.PuzzleState, max_depth: int = 16) -> Array[Dictionary]:
	if initial_state.remaining_ring_count() == 0:
		return []

	var queue: Array = [{"state": initial_state.clone(), "path": []}]
	var visited := {}
	visited[_state_signature(initial_state)] = true

	while not queue.is_empty():
		var node: Dictionary = queue.pop_front()
		var st: PuzzleRules.PuzzleState = node["state"]
		var path: Array[Dictionary] = []
		for step_item in node["path"]:
			path.append(step_item)

		if path.size() >= max_depth:
			continue

		for idx in range(st.rings.size()):
			var r: Dictionary = st.rings[idx]
			if bool(r.get("released", false)):
				continue

			# Case 1: locked by slider pin -> unlock slider pin
			if not bool(r.get("slider_unlocked", true)):
				var next_st := st.clone()
				next_st.rings[idx]["slider_unlocked"] = true
				PuzzleRules.evaluate_releases(next_st)
				var sig := _state_signature(next_st)
				if not visited.has(sig):
					visited[sig] = true
					var next_path: Array[Dictionary] = path.duplicate()
					next_path.append({"type": "slide_pin", "ring_index": idx, "target_step": int(r.get("current_step", 0))})
					if next_st.remaining_ring_count() == 0:
						return next_path
					queue.append({"state": next_st, "path": next_path})
				continue

			# Case 2: rotate ring to target step
			var check := PuzzleRules.can_rotate_ring(st, idx, 1)
			if not bool(check.get("ok", false)):
				continue

			var targets: Array = r.get("target_steps", [0])
			for t in targets:
				var target_step := int(t) % 8
				if int(r.get("current_step", 0)) == target_step:
					continue
				var next_st := st.clone()
				next_st.rings[idx]["current_step"] = target_step
				PuzzleRules.evaluate_releases(next_st)
				var sig := _state_signature(next_st)
				if not visited.has(sig):
					visited[sig] = true
					var next_path: Array[Dictionary] = path.duplicate()
					next_path.append({"type": "rotate", "ring_index": idx, "target_step": target_step})
					if next_st.remaining_ring_count() == 0:
						return next_path
					queue.append({"state": next_st, "path": next_path})

	return []

static func _state_signature(st: PuzzleRules.PuzzleState) -> String:
	var parts := PackedStringArray()
	for r in st.rings:
		parts.append("%d:%d:%d" % [
			int(r.get("current_step", 0)),
			1 if bool(r.get("released", false)) else 0,
			1 if bool(r.get("slider_unlocked", true)) else 0
		])
	return "|".join(parts)
