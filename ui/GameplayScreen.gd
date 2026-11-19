class_name GameplayScreen
extends Control

const RingReleaseFXScript = preload("res://gameplay/ring_release_fx.gd")
const ConfettiBurstScript = preload("res://gameplay/confetti_burst.gd")

## How far the release gate sticks out past the outermost ring.
const GATE_WIDTH := 46.0
## GameplayScreen — Complete interactive HUD & Ring Puzzle Board for Godot 4.
## Renders:
##   - Top Bar: Stage Name + Puzzle # + 5 Stage Progress Dots | Bamboo Budget Gauge + Par/Used | Pause Button
##   - Center Board: Target Release Gate + Interactive RingPiece2D nodes + DragRotationController + MascotCompanion
##   - Bottom Bar: Passive Perk Pills + 3 Active Power Buttons (Panda Eye, Rewind, Free Spin, Stretch, Snip, Pop)

signal pause_requested()
signal open_home_requested()

class ReleaseGateGuide extends Node2D:
	## The release gate: the player turns a ring until its gap lines up with
	## this channel on the right. The arrow breathes so the target is obvious.
	var max_radius: float = 175.0
	var time: float = 0.0
	var pulse: float = 0.0

	func _process(delta: float) -> void:
		time += delta
		pulse = 0.5 + 0.5 * sin(time * 2.4)
		queue_redraw()

	func _draw() -> void:
		# Center hub pin
		draw_circle(Vector2.ZERO, 15.0, Color(0.12, 0.23, 0.18, 0.28))
		draw_circle(Vector2.ZERO, 11.0, RingTheme.INK)
		draw_circle(Vector2.ZERO, 6.0, RingTheme.CREAM)

		# The channel the ring's gap has to point at, running east.
		var lane := Color(0.18, 0.49, 0.20, 0.10 + 0.05 * pulse)
		draw_colored_polygon(PackedVector2Array([
			Vector2(22.0, -15.0),
			Vector2(max_radius + 26.0, -15.0),
			Vector2(max_radius + 26.0, 15.0),
			Vector2(22.0, 15.0),
		]), lane)

		# Dashed guide line down the middle of the channel.
		draw_dashed_line(Vector2(20.0, 0.0), Vector2(max_radius + 30.0, 0.0),
			Color(0.18, 0.49, 0.20, 0.45 + 0.25 * pulse), 3.0, 8.0)

		# Two chevrons pointing into the gate, bright enough to read against
		# the bamboo rings behind them.
		for i in 2:
			var x := max_radius + 10.0 + float(i) * 16.0
			var a := 1.0 - float(i) * 0.4
			var tip := Vector2(x, 0.0)
			var arrow := PackedVector2Array([
				tip,
				tip + Vector2(-13.0, -10.0),
				tip + Vector2(-8.0, 0.0),
				tip + Vector2(-13.0, 10.0),
			])
			draw_colored_polygon(arrow, Color(0.10, 0.30, 0.16, a * (0.55 + 0.45 * pulse)))

		# The gate mouth: a bamboo arch the ring passes through.
		var mouth := Vector2(max_radius + 26.0, 0.0)
		draw_line(mouth + Vector2(0, -24.0), mouth + Vector2(0, 24.0), Color(0.10, 0.20, 0.12, 0.75), 6.0, true)
		draw_line(mouth + Vector2(0, -24.0), mouth + Vector2(0, 24.0), RingTheme.BAMBOO, 3.0, true)

class StageDotsStrip extends Control:
	var current_pos_in_stage: int = 0
	func _init() -> void:
		custom_minimum_size = Vector2(110, 18)
	func set_progress(puzzle_number: int) -> void:
		current_pos_in_stage = (puzzle_number - 1) % 5
		queue_redraw()
	func _draw() -> void:
		for i in range(5):
			var center := Vector2(10.0 + float(i) * 20.0, 9.0)
			var col := RingTheme.CARD
			if i < current_pos_in_stage:
				col = RingTheme.BAMBOO
			elif i == current_pos_in_stage:
				col = RingTheme.EPIC_GOLD
			if i == 4:
				# 5th dot = Boss diamond
				var pts := PackedVector2Array([
					center + Vector2(0, -7),
					center + Vector2(7, 0),
					center + Vector2(0, 7),
					center + Vector2(-7, 0)
				])
				draw_colored_polygon(pts, col)
				draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), RingTheme.INK, 2.0)
			else:
				draw_circle(center, 6.0, col)
				draw_arc(center, 6.0, 0.0, TAU, 20, RingTheme.INK, 2.0)

var stage_label: Label
var stage_dots: StageDotsStrip
var budget_label: Label
var par_label: Label
var board_hint_label: Label
var passive_strip: HBoxContainer
var power_bar: HBoxContainer
var power_buttons: Array[Button] = []
var power_slot_containers: Array[Control] = []
var _board_scale: float = 1.0
var _banner_root: Control = null
var _banner_panel: PanelContainer = null
var _banner_title: Label = null
var _banner_sub: Label = null
var header: Dictionary = {}

var board_container: Control
var board_root: Node2D
var gate_guide: ReleaseGateGuide
var drag_controller: DragRotationController
var ring_nodes: Array[RingPiece2D] = []
var mascot: MascotCompanion
var tutorial_hand: TutorialHand
var hint_controller: HintController
var pending_target_power: String = ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_hud()

	hint_controller = HintController.new()
	add_child(hint_controller)

	drag_controller = DragRotationController.new()
	add_child(drag_controller)
	drag_controller.ring_grabbed.connect(_on_ring_grabbed)
	drag_controller.ring_rotated_live.connect(_on_ring_rotated_live)
	drag_controller.ring_move_committed.connect(_on_ring_move_committed)
	drag_controller.ring_blocked_feedback.connect(_on_ring_blocked_feedback)

	RunController.budget_changed.connect(_on_budget_changed)
	RunController.puzzle_started.connect(_on_puzzle_started)
	RunController.puzzle_cleared.connect(_on_puzzle_cleared)
	RunController.danger_zone_changed.connect(_on_danger_zone_changed)
	PerkSystem.powers_changed.connect(_refresh_power_slots)
	PerkSystem.perks_changed.connect(_refresh_passive_strip)

	resized.connect(_update_board_position)
	call_deferred("_update_board_position")
	board_container.resized.connect(_update_board_position)

func _build_hud() -> void:
	RingTheme.bamboo_background(self)

	# Everything below is anchored to the screen rather than stacked in a
	# container chain. A chain re-sorts only when its parent re-sorts, and the
	# gameplay screen changes size when the window settles - which left the
	# whole HUD sized to its minimum and the labels collapsed to one pixel.
	const TOP := 26.0
	const HEADER_H := 116.0
	const ROW_H := 26.0
	const BOTTOM_H := 158.0

	# --- BAMBOO BANNER HEADER ---
	header = RingTheme.build_header("Garden \u00b7 1", 30, int(SaveService.data.get("coins", 0)))
	var header_root: Control = header["root"]
	header_root.anchor_left = 0.0
	header_root.anchor_right = 1.0
	header_root.anchor_top = 0.0
	header_root.anchor_bottom = 0.0
	header_root.offset_left = 12
	header_root.offset_right = -12
	header_root.offset_top = TOP
	header_root.offset_bottom = TOP + HEADER_H
	add_child(header_root)
	stage_label = header["stage"]
	budget_label = header["budget"]

	# --- STAGE STRIP + HINT + PAR ---
	var row := Control.new()
	row.anchor_left = 0.0
	row.anchor_right = 1.0
	row.anchor_top = 0.0
	row.anchor_bottom = 0.0
	row.offset_left = 14
	row.offset_right = -14
	row.offset_top = TOP + HEADER_H + 6
	row.offset_bottom = TOP + HEADER_H + 6 + ROW_H
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	stage_dots = StageDotsStrip.new()
	stage_dots.position = Vector2(0, 4)
	row.add_child(stage_dots)

	var hint_pill := PanelContainer.new()
	hint_pill.position = Vector2(120, 0)
	hint_pill.size = Vector2(372, ROW_H - 6)
	hint_pill.add_theme_stylebox_override("panel", RingTheme.card_style(Color(0.98, 0.96, 0.90, 0.82), RingTheme.BAMBOO_DARK, 1, 12, 5))
	hint_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(hint_pill)

	board_hint_label = RingTheme.label("", 13, RingTheme.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	board_hint_label.clip_text = true
	board_hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	board_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_pill.add_child(board_hint_label)

	var par_pill := PanelContainer.new()
	par_pill.anchor_left = 1.0
	par_pill.anchor_right = 1.0
	par_pill.anchor_top = 0.0
	par_pill.anchor_bottom = 0.0
	par_pill.offset_left = -156
	par_pill.offset_right = 0
	par_pill.offset_top = 0
	par_pill.offset_bottom = ROW_H - 6
	par_pill.add_theme_stylebox_override("panel", RingTheme.card_style(Color(0.98, 0.96, 0.90, 0.82), RingTheme.BAMBOO_DARK, 1, 12, 5))
	par_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(par_pill)

	par_label = RingTheme.label("Par 3 \u00b7 Used 0", 13, RingTheme.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	par_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	par_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	par_pill.add_child(par_label)

	# --- STAGE / CURSE BANNER (sits over the board, fades itself out) ---
	_banner_root = Control.new()
	_banner_root.anchor_left = 0.0
	_banner_root.anchor_right = 1.0
	_banner_root.anchor_top = 0.0
	_banner_root.anchor_bottom = 0.0
	_banner_root.offset_left = 14
	_banner_root.offset_right = -14
	_banner_root.offset_top = TOP + HEADER_H + 42
	_banner_root.offset_bottom = TOP + HEADER_H + 128
	_banner_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_root.visible = false
	add_child(_banner_root)

	_banner_panel = PanelContainer.new()
	_banner_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_root.add_child(_banner_panel)

	var banner_vbox := VBoxContainer.new()
	banner_vbox.add_theme_constant_override("separation", 2)
	_banner_panel.add_child(banner_vbox)

	_banner_title = RingTheme.label("STAGE", 20, RingTheme.CARD)
	banner_vbox.add_child(_banner_title)
	_banner_sub = RingTheme.label("", 13, RingTheme.GOLD)
	banner_vbox.add_child(_banner_sub)

	# --- CENTER PUZZLE AREA ---
	board_container = Control.new()
	board_container.anchor_left = 0.0
	board_container.anchor_right = 1.0
	board_container.anchor_top = 0.0
	board_container.anchor_bottom = 1.0
	board_container.offset_left = 0
	board_container.offset_right = 0
	board_container.offset_top = TOP + HEADER_H + 6 + ROW_H + 4
	board_container.offset_bottom = -BOTTOM_H
	board_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board_container)

	board_root = Node2D.new()
	board_container.add_child(board_root)

	gate_guide = ReleaseGateGuide.new()
	gate_guide.z_index = 40
	board_root.add_child(gate_guide)

	tutorial_hand = TutorialHand.new()
	board_root.add_child(tutorial_hand)

	mascot = MascotCompanion.new()
	board_container.add_child(mascot)

	# --- BOTTOM: PASSIVE PERKS + ACTIVE POWER CARDS ---
	var bottom_panel := PanelContainer.new()
	bottom_panel.add_theme_stylebox_override("panel", RingTheme.card_style(Color(1.0, 0.99, 0.96, 0.94), RingTheme.BAMBOO_DARK, 2, 18, 10))
	bottom_panel.anchor_left = 0.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = 10
	bottom_panel.offset_right = -10
	bottom_panel.offset_top = -BOTTOM_H
	bottom_panel.offset_bottom = -10
	add_child(bottom_panel)

	var bottom_vbox := VBoxContainer.new()
	bottom_vbox.add_theme_constant_override("separation", 6)
	bottom_panel.add_child(bottom_vbox)

	passive_strip = HBoxContainer.new()
	passive_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	passive_strip.add_theme_constant_override("separation", 8)
	passive_strip.custom_minimum_size = Vector2(0, 26)
	bottom_vbox.add_child(passive_strip)

	power_bar = HBoxContainer.new()
	power_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	power_bar.add_theme_constant_override("separation", 10)
	bottom_vbox.add_child(power_bar)

	power_buttons.clear()
	power_slot_containers.clear()
	for i in range(3):
		var slot_idx := i
		var slot_root := Control.new()
		slot_root.custom_minimum_size = Vector2(150, 96)
		slot_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		power_bar.add_child(slot_root)

		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.pressed.connect(func(): _on_power_button_pressed(slot_idx))
		slot_root.add_child(b)

		power_slot_containers.append(slot_root)
		power_buttons.append(b)


func _update_board_position() -> void:
	_layout_board()


## Scale and place the board so the whole cluster fits the free area.
## The bounds come from the ring specs, not from the live nodes: during the
## drop animation the nodes are not where they will end up.
func _layout_board() -> void:
	if board_container == null or board_root == null:
		return
	var rect := board_container.get_rect()
	var center := Vector2(rect.size.x * 0.5, rect.size.y * 0.5)
	if center.x < 100:
		var vp := get_viewport_rect().size
		center = Vector2(vp.x * 0.5, vp.y * 0.44)

	var bounds := _cluster_bounds()
	if bounds.size.x > 1.0 and bounds.size.y > 1.0:
		var avail := Vector2(maxf(120.0, rect.size.x - 26.0), maxf(120.0, rect.size.y - 26.0))
		var scale_f: float = minf(avail.x / bounds.size.x, avail.y / bounds.size.y)
		_board_scale = clampf(scale_f, 0.30, 1.25)
		board_root.scale = Vector2(_board_scale, _board_scale)
		center -= bounds.get_center() * _board_scale
	board_root.position = center
	drag_controller.board_center = board_container.global_position + center
	if mascot != null:
		# Park the panda in the bottom-right of the sand garden, clear of the board.
		mascot.position = Vector2(rect.size.x - 54.0, rect.size.y - 34.0)


## The bounding box of every ring, including its tube and end caps.
func _cluster_bounds() -> Rect2:
	if RunController.current_puzzle_state == null:
		return Rect2()
	var rings: Array = RunController.current_puzzle_state.rings
	if rings.is_empty():
		return Rect2()
	var max_r := 0.0
	for r_spec in rings:
		var radius := float(r_spec.get("radius_px", 70.0))
		var thickness := float(r_spec.get("thickness_px", 14.0))
		max_r = maxf(max_r, radius + thickness * 0.5 + 8.0)
	# The gate sticks out to the right of the outermost ring, so the bounds
	# have to include it or it gets clipped by the edge of the board area.
	var min_pt := Vector2(-max_r, -max_r)
	var max_pt := Vector2(max_r + GATE_WIDTH, max_r)
	return Rect2(min_pt, max_pt - min_pt)

func _on_budget_changed(new_budget: int, max_cap: int, delta: int) -> void:
	if budget_label != null:
		budget_label.text = str(new_budget)
	if header.has("coins"):
		header["coins"].text = str(int(SaveService.data.get("coins", 0)))
	if delta != 0 and board_root != null:
		var txt := ("+%d" % delta) if delta > 0 else str(delta)
		var col := RingTheme.BAMBOO if delta > 0 else RingTheme.DANGER
		_spawn_floating_text(txt, board_root.position + Vector2(0, -175), col)

func _on_danger_zone_changed(is_danger: bool) -> void:
	if budget_label == null:
		return
	if is_danger:
		budget_label.add_theme_color_override("font_color", RingTheme.DANGER)
		mascot.set_mood("ghabraya")
		AudioService.play_danger_heartbeat()
		RingReleaseFXScript.danger_pulse(board_root, board_root.position + Vector2(0, -150))
	else:
		budget_label.add_theme_color_override("font_color", RingTheme.BAMBOO_DARK)

## A short banner announcing the stage or the curse that just came into play.
func _show_banner(is_boss: bool, curses: Array, stage_num: int, stage_name: String) -> void:
	if is_boss:
		_banner_title.text = "BOSS PUZZLE"
		_banner_sub.text = "Clear every ring for 3x coins, +5 moves and a Rare card"
		_banner_panel.add_theme_stylebox_override("panel", RingTheme.card_style(RingTheme.DANGER, RingTheme.GOLD, 3, 16, 14))
		_banner_title.add_theme_color_override("font_color", RingTheme.CARD)
	elif not curses.is_empty():
		var names: Array = []
		for c in curses:
			names.append(str(c).replace("_", " ").to_upper())
		_banner_title.text = "CURSE"
		_banner_sub.text = ", ".join(names)
		_banner_panel.add_theme_stylebox_override("panel", RingTheme.card_style(Color("#7A2436"), RingTheme.DANGER, 3, 16, 14))
		_banner_title.add_theme_color_override("font_color", RingTheme.CARD)
	else:
		_banner_title.text = "STAGE %d \u00b7 %s" % [stage_num, stage_name.to_upper()]
		_banner_sub.text = CampaignBoard.get_stage_mechanic_hint(stage_num)
		_banner_panel.add_theme_stylebox_override("panel", RingTheme.card_style(RingTheme.INK, RingTheme.GOLD, 3, 16, 14))
		_banner_title.add_theme_color_override("font_color", RingTheme.CARD)
	_banner_root.visible = true
	_banner_root.modulate.a = 0.0
	var tw := _banner_root.create_tween()
	tw.tween_property(_banner_root, "modulate:a", 1.0, 0.16)
	tw.tween_interval(1.25)
	tw.tween_property(_banner_root, "modulate:a", 0.0, 0.28)
	tw.tween_callback(func(): _banner_root.visible = false)


func _on_puzzle_started(spec: Dictionary) -> void:
	_update_board_position()
	pending_target_power = ""
	var stage_name := str(spec.get("stage_name", "Garden"))
	var p_num := int(spec.get("puzzle_number", 1))
	var stage_num := int(spec.get("stage", 1))
	if stage_label != null:
		stage_label.text = "%s · %d" % [stage_name, p_num]
	if stage_dots != null:
		stage_dots.set_progress(p_num)
	_update_par_label()

	var curses: Array = spec.get("curses", [])
	var is_boss := bool(spec.get("is_boss", false))
	if is_boss:
		mascot.set_mood("boss")
		AudioService.play_boss_intro()
	elif not curses.is_empty():
		mascot.set_mood("calm")
		AudioService.play_curse_applied()
	else:
		mascot.set_mood("ghabraya" if RunController.budget <= 5 else "calm")

	# The hint row always shows the mechanic; the banner announces the event.
	board_hint_label.text = CampaignBoard.get_stage_mechanic_hint(stage_num)
	board_hint_label.add_theme_color_override("font_color", RingTheme.MUTED)
	if p_num % 5 == 1 or is_boss or not curses.is_empty():
		_show_banner(is_boss, curses, stage_num, stage_name)

	_rebuild_ring_nodes()
	_refresh_power_slots()
	_refresh_passive_strip()

	# On Puzzle 1 of a tutorial run, show a friendly hand hint automatically
	if p_num == 1 and bool(spec.get("is_tutorial", false)):
		hint_controller.trigger_panda_eye(RunController.current_puzzle_state, [], tutorial_hand)

func _rebuild_ring_nodes() -> void:
	for r_node in ring_nodes:
		if is_instance_valid(r_node):
			r_node.queue_free()
	ring_nodes.clear()

	if RunController.current_puzzle_state == null:
		return
	var rings_arr := RunController.current_puzzle_state.rings
	var max_r := 70.0
	# Rings drop in from above, outermost first, so the puzzle assembles itself
	# instead of appearing all at once.
	var drop_order := _drop_order(rings_arr)
	for idx in range(rings_arr.size()):
		var r_spec: Dictionary = rings_arr[idx]
		var r_node := RingPiece2D.new()
		r_node.setup(idx, r_spec)
		r_node.visible = not bool(r_spec.get("released", false))
		board_root.add_child(r_node)
		ring_nodes.append(r_node)
		max_r = maxf(max_r, float(r_spec.get("radius_px", 70.0)))

		# The drop: fall in from above and land with a bounce. The tween has to
		# be created on the node itself - a tween made before the node has a
		# parent never runs.
		var delay: float = 0.04 * float(drop_order.find(idx)) if drop_order.find(idx) >= 0 else 0.0
		var target_pos := r_node.position
		r_node.position = target_pos + Vector2(0, -420)
		r_node.modulate.a = 0.0
		var tw := r_node.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(r_node, "position", target_pos, 0.52).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(r_node, "modulate:a", 1.0, 0.16)

	gate_guide.max_radius = max_r
	gate_guide.queue_redraw()

	# Smart framing scale so large Boss puzzles fit cleanly inside 500px width
	var avail_radius := minf(get_viewport_rect().size.x * 0.46, 260.0)
	var scale_factor := clampf(avail_radius / maxf(120.0, max_r + 28.0), 0.58, 1.7)
	board_root.scale = Vector2(scale_factor, scale_factor)

## The order rings drop in: the biggest ring first, then the rest by radius.
## A big ring landing under a small one looks wrong.
func _drop_order(rings_arr: Array) -> Array[int]:
	var order: Array[int] = []
	var indices: Array[int] = []
	for i in range(rings_arr.size()):
		indices.append(i)
	indices.sort_custom(func(a: int, b: int) -> bool:
		var ra := float(rings_arr[a].get("radius_px", 70.0))
		var rb := float(rings_arr[b].get("radius_px", 70.0))
		return ra > rb
	)
	for i in indices:
		order.append(i)
	return order


func _sync_ring_nodes() -> void:
	if RunController.current_puzzle_state == null:
		return
	var rings_arr := RunController.current_puzzle_state.rings
	for idx in range(mini(ring_nodes.size(), rings_arr.size())):
		var r_spec: Dictionary = rings_arr[idx]
		var r_node := ring_nodes[idx]
		r_node.sync_from_state(r_spec)
		r_node.visible = not bool(r_spec.get("released", false))
	_update_par_label()

func _update_par_label() -> void:
	if par_label == null or RunController.current_puzzle_state == null:
		return
	var par := int(RunController.current_puzzle_spec.get("par", 3))
	var used := RunController.current_puzzle_state.moves_used
	var free_left := RunController.free_spin_moves_left
	var extra := (" · Free:%d" % free_left) if free_left > 0 else ""
	par_label.text = "Par %d · Used %d%s" % [par, used, extra]
	par_label.add_theme_color_override("font_color", RingTheme.GOLD if used > par else RingTheme.MUTED)

func _gui_input(event: InputEvent) -> void:
	if RunController.current_puzzle_state == null or not RunController.is_run_active:
		return
	_update_board_position()

	# Cast to the concrete event types: `event` is typed InputEvent, so its members
	# don't resolve without narrowing and the result would be an untyped Variant.
	var mouse_btn := event as InputEventMouseButton
	var mouse_motion := event as InputEventMouseMotion

	if mouse_btn != null and mouse_btn.button_index == MOUSE_BUTTON_LEFT:
		var local_board_pos: Vector2 = (mouse_btn.position - board_root.global_position) / board_root.scale
		if mouse_btn.pressed:
			var picked_idx := _pick_ring_at(local_board_pos)
			if picked_idx >= 0:
				# Check if player is targeting Stretch, Snip, or Pop power on a ring
				if pending_target_power != "":
					_apply_targeted_power_on_ring(pending_target_power, picked_idx)
					pending_target_power = ""
					return
				var r_spec: Dictionary = RunController.current_puzzle_state.rings[picked_idx]
				# If locked by Slider Pin, clicking near the slider pin (or clicking the ring) slides it open!
				if not bool(r_spec.get("slider_unlocked", true)):
					_spawn_floating_text("Slider Pin Unlocked!", board_root.global_position + Vector2(0, -60), RingTheme.BAMBOO)
					RunController.commit_player_move(picked_idx, int(r_spec.get("current_step", 0)), true)
					_sync_ring_nodes()
					return
				drag_controller.begin_drag(picked_idx, mouse_btn.position, int(r_spec.get("current_step", 0)))
		else:
			drag_controller.end_drag(RunController.current_puzzle_state)
			for r_node in ring_nodes:
				r_node.set_grabbed(false)
				r_node.is_near_aligned = false
			_sync_ring_nodes()

	elif mouse_motion != null and drag_controller.is_dragging:
		drag_controller.update_drag(mouse_motion.position, RunController.current_puzzle_state)

func _pick_ring_at(local_pos: Vector2) -> int:
	if RunController.current_puzzle_state == null:
		return -1
	var dist := local_pos.length()
	var best_idx := -1
	var best_diff := 24.0
	var rings_arr := RunController.current_puzzle_state.rings
	for idx in range(rings_arr.size()):
		var r_spec: Dictionary = rings_arr[idx]
		if bool(r_spec.get("released", false)):
			continue
		var rad := float(r_spec.get("radius_px", 70.0))
		var diff := absf(dist - rad)
		if diff < best_diff:
			best_diff = diff
			best_idx = idx
	return best_idx

func _on_ring_grabbed(ring_index: int) -> void:
	if ring_index >= 0 and ring_index < ring_nodes.size():
		ring_nodes[ring_index].set_grabbed(true)
		var r_spec: Dictionary = RunController.current_puzzle_state.rings[ring_index]
		RingReleaseFXScript.pickup_spark(board_root, ring_nodes[ring_index].position,
			Color.from_string(str(r_spec.get("color", "#4CAF50")), RingTheme.BAMBOO))
		AudioService.play_piece_select()
		PlatformServices.trigger_haptic("piece_select")

func _on_ring_rotated_live(ring_index: int, angle_rad: float, near_align: bool) -> void:
	if ring_index >= 0 and ring_index < ring_nodes.size():
		var r_node := ring_nodes[ring_index]
		r_node.rotation = angle_rad
		r_node.is_near_aligned = near_align
		r_node.queue_redraw()

func _on_ring_move_committed(ring_index: int, new_step: int, is_slider_move: bool) -> void:
	for r_node in ring_nodes:
		r_node.is_hinted = false
	var res := RunController.commit_player_move(ring_index, new_step, is_slider_move)
	var released: Array = res.get("released", [])
	for rel_idx in released:
		var idx := int(rel_idx)
		if idx >= 0 and idx < ring_nodes.size():
			var r_spec: Dictionary = RunController.current_puzzle_state.rings[idx]
			var radius := float(r_spec.get("radius_px", 70.0))
			var col := Color.from_string(str(r_spec.get("color", "#4CAF50")), RingTheme.BAMBOO)
			var thickness := float(r_spec.get("thickness_px", 14.0))
			var gap_deg := float(r_spec.get("gap_width_deg", 44.0))

			# The ring falls away, shatters into shards and pops a ring of stars.
			var drop := DroppedRing2D.new()
			drop.position = ring_nodes[idx].position
			drop.rotation = ring_nodes[idx].rotation
			board_root.add_child(drop)
			drop.start_drop(radius, col, 0.6, thickness, gap_deg)
			RingReleaseFXScript.play(board_root, drop.position, radius, col, thickness, released.size(), ring_nodes[idx].rotation, gap_deg)
			ring_nodes[idx].visible = false
	if released.size() >= 2:
		_spawn_floating_text("GREAT! Chain x%d" % released.size(), board_root.global_position + Vector2(0, -40), RingTheme.EPIC_GOLD)
	elif released.size() == 1:
		var r_check: Dictionary = RunController.current_puzzle_state.rings[ring_index]
		var prereqs: Array = r_check.get("requires_free", [])
		var blocked_by_inner := false
		for req in prereqs:
			if not bool(RunController.current_puzzle_state.rings[int(req)].get("released", false)):
				blocked_by_inner = true
	else:
		# Explain if the ring was aligned to step 0 but still had an unreleased prerequisite ring
		var r_cur: Dictionary = RunController.current_puzzle_state.rings[ring_index]
		var targets: Array = r_cur.get("target_steps", [0])
		if targets.has(new_step):
			_spawn_floating_text("Release inner blocking ring first!", board_root.global_position + Vector2(0, -35), RingTheme.GOLD)

	_sync_ring_nodes()

func _on_ring_blocked_feedback(ring_index: int, contact_point: Vector2, reason: String) -> void:
	if ring_index >= 0 and ring_index < ring_nodes.size():
		ring_nodes[ring_index].trigger_blocked_jiggle()
	var burst := CollisionSparkBurst.new()
	add_child(burst)
	burst.emit_burst(contact_point, RingTheme.EPIC_GOLD, 14, 0.30)
	AudioService.play_blocked()
	PlatformServices.trigger_haptic("blocked")
	var msg := "Blocked!"
	if reason == "one_way_curse":
		msg = "One-Way Curse: Rotate Clockwise Only!"
	elif reason == "locked_ring_curse":
		msg = "Locked Ring: Release neighbor ring first!"
	elif reason == "slider_pin_locked":
		msg = "Tap Slider Pin to unlock first!"
	_spawn_floating_text(msg, contact_point + Vector2(0, -24), RingTheme.DANGER)

func _on_puzzle_cleared(summary: Dictionary) -> void:
	mascot.set_mood("celebrate")
	var is_clean := bool(summary.get("is_clean_solve", false))
	var msg := "CLEAN SOLVE! +%d Move" % int(summary.get("clean_bonus", 1)) if is_clean else "PUZZLE CLEARED!"
	_spawn_floating_text(msg, board_root.global_position + Vector2(0, -90), RingTheme.GOLD if is_clean else RingTheme.BAMBOO)
	if not SaveService.is_reduced_motion():
		ConfettiBurstScript.fire(self, board_root.global_position, 18)
	else:
		# Reduced motion still gets a small sparkle, just no flying paper.
		var confetti := CollisionSparkBurst.new()
		add_child(confetti)
		confetti.emit_burst(board_root.global_position, RingTheme.EPIC_GOLD, 14, 0.5)

func _refresh_passive_strip() -> void:
	if passive_strip == null:
		return
	for c in passive_strip.get_children():
		c.queue_free()
	if PerkSystem.passive_perks.is_empty():
		var hint := RingTheme.label("No passive perks yet \u2014 clear a puzzle to pick a card", 12, RingTheme.MUTED)
		hint.autowrap_mode = TextServer.AUTOWRAP_OFF
		passive_strip.add_child(hint)
		return
	for pid in PerkSystem.passive_perks:
		var meta: Dictionary = PerkSystem.TOOLS_CATALOG.get(pid, {})
		var pill := RingTheme.perk_pill(str(meta.get("name", pid)))
		var desc := str(meta.get("desc", ""))
		pill.mouse_filter = Control.MOUSE_FILTER_STOP
		pill.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				_spawn_floating_text("%s: %s" % [meta.get("name", ""), desc], board_root.global_position, RingTheme.INK)
		)
		passive_strip.add_child(pill)



func _refresh_power_slots() -> void:
	for i in range(power_buttons.size()):
		var btn := power_buttons[i]
		var slot_root: Control = power_slot_containers[i]
		for c in slot_root.get_children():
			if c != btn:
				c.queue_free()
		if i < PerkSystem.active_slots.size():
			var slot: Dictionary = PerkSystem.active_slots[i]
			var meta: Dictionary = PerkSystem.TOOLS_CATALOG.get(str(slot.get("id", "")), {})
			var chg := int(slot.get("charges", 0))
			slot_root.add_child(RingTheme.power_card(
				str(meta.get("icon", "")),
				str(meta.get("name", "")),
				chg,
				chg > 0
			))
			btn.disabled = (chg <= 0)
		else:
			slot_root.add_child(RingTheme.power_card("", "", 0, false))
			btn.disabled = true
		# keep the invisible button on top so it still catches the tap
		slot_root.move_child(btn, slot_root.get_child_count() - 1)



func _on_power_button_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= PerkSystem.active_slots.size():
		return
	var slot: Dictionary = PerkSystem.active_slots[slot_index]
	var pid := str(slot.get("id", ""))
	if pid == "":
		return

	if pid == "panda_eye":
		var curses: Array = RunController.current_puzzle_spec.get("curses", [])
		var h_res := hint_controller.trigger_panda_eye(RunController.current_puzzle_state, curses, tutorial_hand)
		if not bool(h_res.get("ok", false)):
			_spawn_floating_text("Blind Curse: Panda Eye Disabled!", board_root.global_position, RingTheme.DANGER)
			return
		var mv: Dictionary = h_res.get("move", {})
		var r_idx := int(mv.get("ring_index", -1))
		if r_idx >= 0 and r_idx < ring_nodes.size():
			ring_nodes[r_idx].is_hinted = true
		PerkSystem.use_active_power(slot_index)
		_spawn_floating_text("Panda Eye: Align highlighted ring to right gate!", board_root.global_position + Vector2(0, -60), RingTheme.BAMBOO)

	elif pid == "rewind":
		if not RunController.execute_rewind():
			_spawn_floating_text("Nothing to rewind yet!", board_root.global_position, RingTheme.GOLD)
			return
		PerkSystem.use_active_power(slot_index)
		_sync_ring_nodes()
		_spawn_floating_text("Rewind! Move Refunded", board_root.global_position + Vector2(0, -60), RingTheme.RARE_BLUE)

	elif pid == "free_spin":
		RunController.activate_free_spin()
		PerkSystem.use_active_power(slot_index)
		_update_par_label()
		_spawn_floating_text("Free Spin! Next 3 Moves Cost 0", board_root.global_position + Vector2(0, -60), RingTheme.BAMBOO)

	elif pid in ["stretch", "snip", "pop"]:
		# Automatically apply to the first remaining locked/unreleased ring for smooth 1-tap play
		var target_idx := _find_best_power_target_ring(pid)
		if target_idx < 0:
			return
		PerkSystem.use_active_power(slot_index)
		_apply_targeted_power_on_ring(pid, target_idx)

func _find_best_power_target_ring(pid: String) -> int:
	if RunController.current_puzzle_state == null:
		return -1
	var rings_arr := RunController.current_puzzle_state.rings
	if pid == "snip":
		for i in range(rings_arr.size()):
			var r: Dictionary = rings_arr[i]
			if not bool(r.get("released", false)) and (not r.get("requires_free", []).is_empty() or not bool(r.get("slider_unlocked", true))):
				return i
	for i in range(rings_arr.size() - 1, -1, -1):
		if not bool(rings_arr[i].get("released", false)):
			return i
	return -1

func _apply_targeted_power_on_ring(pid: String, ring_idx: int) -> void:
	if RunController.current_puzzle_state == null or ring_idx < 0:
		return
	var r: Dictionary = RunController.current_puzzle_state.rings[ring_idx]
	if pid == "stretch":
		r["stretched"] = true
		_sync_ring_nodes()
		_spawn_floating_text("Stretch! Ring gap widened", board_root.global_position + Vector2(0, -50), RingTheme.RARE_BLUE)
	elif pid == "snip":
		r["requires_free"] = []
		r["slider_unlocked"] = true
		r["initially_locked"] = false
		var anim := HammerAnimator.new()
		board_root.add_child(anim)
		anim.play_bamboo_snip(Vector2.ZERO, ring_idx)
		_sync_ring_nodes()
		_spawn_floating_text("Bamboo Snip! Connector sliced", board_root.global_position + Vector2(0, -50), RingTheme.BAMBOO)
	elif pid == "pop":
		var anim := RocketAnimator.new()
		board_root.add_child(anim)
		anim.play_bubble_pop(Vector2.ZERO, ring_idx)
		r["released"] = true
		_sync_ring_nodes()
		_spawn_floating_text("Bubble Pop! Ring removed", board_root.global_position + Vector2(0, -50), RingTheme.EPIC_GOLD)
		if RunController.current_puzzle_state.remaining_ring_count() == 0:
			RunController._handle_puzzle_clear()

func _spawn_floating_text(msg: String, global_pt: Vector2, col: Color) -> void:
	var lbl := RingTheme.label(msg, 16, col)
	lbl.position = global_pt - Vector2(160, 12)
	lbl.custom_minimum_size = Vector2(320, 30)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 34.0, 0.65)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.65)
	tw.tween_callback(func(): lbl.queue_free())
