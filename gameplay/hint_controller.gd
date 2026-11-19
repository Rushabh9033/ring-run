class_name HintController
extends Node
## HintController — Connects BfsSolver to TutorialHand for the "Panda Eye" active power.
## Automatically blocked when the Stage 6+ "Blind" curse is active on a puzzle.

func trigger_panda_eye(puzzle_state: PuzzleRules.PuzzleState, curses: Array, hand: TutorialHand) -> Dictionary:
	if curses.has("blind"):
		return {"ok": false, "reason": "blind_curse_active"}
	var move := BfsSolver.find_next_optimal_move(puzzle_state)
	if move.is_empty():
		return {"ok": false, "reason": "no_move_found"}
	var ring_idx := int(move.get("ring_index", 0))
	var target_step := int(move.get("target_step", 0))
	var r: Dictionary = puzzle_state.rings[ring_idx]
	var cur_step := int(r.get("current_step", 0))
	if hand != null:
		hand.play_arc_hint(
			float(r.get("radius_px", 80.0)),
			PieceGeometry.step_to_rad(cur_step),
			PieceGeometry.step_to_rad(target_step)
		)
	return {"ok": true, "move": move}
