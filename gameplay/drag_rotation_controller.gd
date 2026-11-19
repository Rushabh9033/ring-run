class_name DragRotationController
extends Node2D
## DragRotationController — Handles 1:1 angular finger tracking on rings,
## slider pin swipe gestures, blocked jiggle (±2.5 deg), and move cost hooks
## for Free Spin, Thrifty, and Heavy Ring curse.

signal ring_grabbed(ring_index: int)
signal ring_rotated_live(ring_index: int, angle_rad: float, near_align: bool)
signal ring_move_committed(ring_index: int, new_step: int, is_slider_move: bool)
signal ring_blocked_feedback(ring_index: int, contact_point: Vector2, reason: String)

var active_ring_index: int = -1
var grab_start_angle: float = 0.0
var ring_start_angle: float = 0.0
var current_drag_angle: float = 0.0
var last_tick_step: int = -1
var is_dragging: bool = false
var _was_near_align: bool = false
var board_center: Vector2 = Vector2(270, 470)

func begin_drag(ring_index: int, touch_pos: Vector2, initial_step: int) -> void:
	active_ring_index = ring_index
	is_dragging = true
	grab_start_angle = (touch_pos - board_center).angle()
	ring_start_angle = PieceGeometry.step_to_rad(initial_step)
	current_drag_angle = ring_start_angle
	last_tick_step = initial_step
	_was_near_align = false
	AudioService.play_piece_select()
	PlatformServices.trigger_haptic("piece_select")
	ring_grabbed.emit(ring_index)

func update_drag(touch_pos: Vector2, puzzle_state: PuzzleRules.PuzzleState) -> void:
	if not is_dragging or active_ring_index < 0:
		return
	var pointer_angle := (touch_pos - board_center).angle()
	var delta := angle_difference(grab_start_angle, pointer_angle)
	var dir_sign := 1 if delta >= 0.0 else -1

	var check := PuzzleRules.can_rotate_ring(puzzle_state, active_ring_index, dir_sign)
	if not bool(check.get("ok", false)):
		is_dragging = false
		AudioService.play_blocked()
		PlatformServices.trigger_haptic("blocked")
		ring_blocked_feedback.emit(active_ring_index, touch_pos, str(check.get("reason", "")))
		active_ring_index = -1
		return

	current_drag_angle = ring_start_angle + delta
	var nearest_step := PieceGeometry.rad_to_nearest_step(current_drag_angle)
	var r: Dictionary = puzzle_state.rings[active_ring_index]
	if nearest_step != last_tick_step:
		last_tick_step = nearest_step
		AudioService.play_rotation_tick(float(r.get("radius_px", 80.0)))
		PlatformServices.trigger_haptic("rotation_tick")

	var targets: Array = r.get("target_steps", [0])
	var near_align := PieceGeometry.is_angle_near_target(current_drag_angle, targets)
	# Edge-triggered: the chime plays once as the gap enters the tolerance,
	# not on every frame the finger sits inside it.
	if near_align and not _was_near_align:
		AudioService.play_near_alignment()
		PlatformServices.trigger_haptic("gap_align")
	_was_near_align = near_align
	ring_rotated_live.emit(active_ring_index, current_drag_angle, near_align)

func end_drag(puzzle_state: PuzzleRules.PuzzleState) -> void:
	if not is_dragging or active_ring_index < 0:
		return
	is_dragging = false
	var idx := active_ring_index
	active_ring_index = -1
	var snapped_step := PieceGeometry.rad_to_nearest_step(current_drag_angle)
	var prev_step := int(puzzle_state.rings[idx].get("current_step", 0))
	if snapped_step != prev_step:
		ring_move_committed.emit(idx, snapped_step, false)
