class_name HomeScreen
extends Control
## HomeScreen — the Ring Run front door.
##
## Built on the Zen Bamboo asset pack: the garden background, the RING RUN
## logo plaque, the stone board with three independently rotating ring arcs,
## gold stat panels, the glossy green START RUN button and three nav tabs.
##
## Every number on this screen is LIVE: the coin balance, the best depth, the
## streak and the daily run status all come from SaveService and update when
## they change.
##
## The rings here are decoration. They are TextureRects on their own layer,
## not gameplay rings, and they never touch the puzzle state.

signal start_run_pressed()
signal daily_run_pressed()
signal collection_pressed()
signal shop_pressed()
signal settings_pressed()

const PACK := "res://assets/ui/ring_run_zen"
const UiTheme = preload("res://app/ui_theme.gd")

# Ring rotation: the design calls for these exact periods and directions.
const OUTER_PERIOD := 9.0
const MIDDLE_PERIOD := 12.0
const INNER_PERIOD := 7.0

# The design reference canvas. Everything is laid out against this and scaled.
const REF_W := 540.0
const REF_H := 960.0

var best_lbl: Label
var streak_lbl: Label
var coins_lbl: Label
var daily_btn: Control
var start_btn: Control
var nav_buttons: Array[Control] = []
var daily_lbl: Label

var _logo: TextureRect
var _coin_pill: PanelContainer
var _stat_panels: Array[PanelContainer] = []
var _ring_outer: TextureRect
var _ring_middle: TextureRect
var _ring_inner: TextureRect
var _board: TextureRect
var _hub: TextureRect
var _ring_layer: Control
var _sparkle: TextureRect

var _time: float = 0.0
var _outer_angle: float = 0.0
var _middle_angle: float = 0.0
var _inner_angle: float = 0.0
var _entering: bool = true
var _entering_t: float = 0.0



func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	SaveService.save_updated.connect(refresh_stats)
	resized.connect(_layout)
	# The viewport can change size without the control's own `resized` firing
	# (window resize, device rotation, safe-area change), and the layout has
	# to follow it.
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_layout):
		vp.size_changed.connect(_layout)
	call_deferred("_layout")
	# The nav captions are positioned against the laid-out row, so they have to
	# wait a frame for the container to sort.
	await get_tree().process_frame
	_layout()
	await get_tree().process_frame
	_layout()
	# The ring motion must stop when the menu is hidden or the app is
	# backgrounded, and resume correctly afterwards.
	visibility_changed.connect(_on_visibility_changed)
	notification(NOTIFICATION_APPLICATION_PAUSED, false)
	notification(NOTIFICATION_APPLICATION_RESUMED, false)


func _build() -> void:
	for child in get_children():
		child.queue_free()

	# --- BACKGROUND ---
	var bg := TextureRect.new()
	bg.name = "GardenBackground"
	bg.texture = _tex("backgrounds/bamboo_garden_menu.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# --- LOGO ---
	_logo = TextureRect.new()
	_logo.name = "Logo"
	_logo.texture = _tex("branding/ring_run_logo.png")
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo)

	# --- COIN PILL ---
	_coin_pill = PanelContainer.new()
	_coin_pill.name = "CoinPill"
	_coin_pill.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_coin_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_coin_pill)
	var coin_skin := NinePatchRect.new()
	coin_skin.name = "Skin"
	coin_skin.texture = _tex("ui/pill_currency.png")
	coin_skin.patch_margin_left = 44
	coin_skin.patch_margin_right = 44
	coin_skin.patch_margin_top = 44
	coin_skin.patch_margin_bottom = 44
	coin_skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_coin_pill.add_child(coin_skin)
	var coin_pad := MarginContainer.new()
	coin_pad.add_theme_constant_override("margin_left", 10)
	coin_pad.add_theme_constant_override("margin_right", 12)
	coin_pad.add_theme_constant_override("margin_top", 4)
	coin_pad.add_theme_constant_override("margin_bottom", 4)
	_coin_pill.add_child(coin_pad)
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 6)
	coin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_pad.add_child(coin_row)
	var coin_icon := TextureRect.new()
	coin_icon.texture = _tex("icons/icon_coin.png")
	coin_icon.custom_minimum_size = Vector2(32, 32)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_row.add_child(coin_icon)
	coins_lbl = _label("0", 19, Color("4A3428"))
	coins_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	coin_row.add_child(coins_lbl)

	# --- RING BOARD ---
	# The rings sit on their own layer so they can never take a tap meant for
	# a button underneath.
	_ring_layer = Control.new()
	_ring_layer.name = "RingLayer"
	_ring_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ring_layer)

	_board = TextureRect.new()
	_board.name = "StoneBoard"
	_board.texture = _tex("rings/zen_stone_board.png")
	_board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_board.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring_layer.add_child(_board)

	# All three ring arcs share one canvas size and one centre, so they turn
	# around the same pivot without wobbling.
	_ring_outer = _make_ring("rings/ring_outer_purple.png")
	_ring_middle = _make_ring("rings/ring_middle_orange.png")
	_ring_inner = _make_ring("rings/ring_inner_blue.png")

	_hub = TextureRect.new()
	_hub.name = "CenterHub"
	_hub.texture = _tex("rings/center_hub.png")
	_hub.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hub.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring_layer.add_child(_hub)

	_sparkle = TextureRect.new()
	_sparkle.name = "Sparkle"
	_sparkle.texture = _tex("effects/sparkle_gold.png")
	_sparkle.custom_minimum_size = Vector2(34, 34)
	_sparkle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sparkle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sparkle.modulate.a = 0.0
	_ring_layer.add_child(_sparkle)

	# --- STAT PANELS ---
	var stats := HBoxContainer.new()
	stats.name = "Stats"
	stats.add_theme_constant_override("separation", 12)
	add_child(stats)

	var depth_panel := _stat_panel("BEST DEPTH", "icons/icon_trophy.png")
	best_lbl = _stat_value(depth_panel)
	stats.add_child(depth_panel)
	_stat_panels.append(depth_panel)

	var streak_panel := _stat_panel("STREAK", "icons/icon_flame.png")
	streak_lbl = _stat_value(streak_panel)
	stats.add_child(streak_panel)
	_stat_panels.append(streak_panel)

	# --- START RUN ---
	start_btn = _skinned_button("ui/button_start_normal.png", "ui/button_start_pressed.png",
		"ui/button_start_disabled.png")
	(start_btn.get_node("Hit") as Button).pressed.connect(_on_start_pressed)
	add_child(start_btn)

	# --- DAILY RUN ---
	daily_btn = _skinned_button("ui/button_daily.png", "ui/button_daily.png", "ui/button_daily.png")
	(daily_btn.get_node("Hit") as Button).pressed.connect(_on_daily_pressed)
	add_child(daily_btn)
	daily_lbl = _label("", 14, Color("4A3428"))
	daily_btn.add_child(daily_lbl)

	# --- BOTTOM NAV ---
	var nav := HBoxContainer.new()
	nav.name = "Nav"
	nav.add_theme_constant_override("separation", 10)
	add_child(nav)

	for entry in [
		["icons/icon_collection.png", "Collection", func(): _emit_nav(collection_pressed)],
		["icons/icon_shop.png", "Shop", func(): _emit_nav(shop_pressed)],
		["icons/icon_settings.png", "Settings", func(): _emit_nav(settings_pressed)],
	]:
		var btn := _skinned_button("ui/button_nav.png", "ui/button_nav_pressed.png", "ui/button_nav_pressed.png")
		(btn.get_node("Hit") as Button).pressed.connect(entry[2])
		nav.add_child(btn)
		nav_buttons.append(btn)
		var icon := TextureRect.new()
		icon.texture = _tex(String(entry[0]))
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon)
		var cap := _label(String(entry[1]), 13, Color("4A3428"))
		cap.name = "Caption"
		btn.add_child(cap)

	refresh_stats()


# ---------------------------------------------------------------- helpers

func _tex(path: String) -> Texture2D:
	var full := "%s/%s" % [PACK, path]
	if ResourceLoader.exists(full):
		return load(full)
	push_warning("Ring Run asset missing: %s" % full)
	return null


func _label(text: String, size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiTheme.rounded_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A ring arc. Same canvas, same centre, so the three turn as one assembly.
func _make_ring(path: String) -> TextureRect:
	var t := TextureRect.new()
	t.name = path.get_file()
	t.texture = _tex(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.pivot_offset = Vector2(512, 512)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring_layer.add_child(t)
	return t


## A button whose skin is a PNG; the label is live text on top of it.
##
## Godot 4.7 dropped Button.texture_normal, so the skin is a TextureRect and
## a transparent Button sits over it to catch the tap. The pressed state
## swaps the skin.
func _skinned_button(normal: String, pressed: String, disabled: String) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_PASS

	# A nine-patch, so the skin keeps its corners instead of being smeared.
	var skin := NinePatchRect.new()
	skin.name = "Skin"
	skin.texture = _tex(normal)
	skin.patch_margin_left = 42
	skin.patch_margin_right = 42
	skin.patch_margin_top = 42
	skin.patch_margin_bottom = 42
	skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(skin)

	var hit := Button.new()
	hit.name = "Hit"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.button_down.connect(func():
		skin.texture = _tex(pressed)
		# The press scale is on the root, so the skin and the text move together.
		var tw := root.create_tween()
		tw.tween_property(root, "scale", Vector2(0.97, 0.97), 0.07))
	hit.button_up.connect(func():
		skin.texture = _tex(normal)
		var tw := root.create_tween()
		tw.tween_property(root, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	root.add_child(hit)

	return root


## The live value label inside a stat panel.
func _stat_value(panel: PanelContainer) -> Label:
	# The value sits in the card's VBox, which may be nested inside a
	# padding container, so the search has to go by name at any depth.
	var found := panel.find_child("Value", true, false)
	return found as Label


## A gold stat panel with a caption, an icon and a live value.
func _stat_panel(caption: String, icon_path: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# The gold skin is a TextureRect behind the content.
	var skin := NinePatchRect.new()
	skin.name = "Skin"
	skin.texture = _tex("ui/panel_stat.png")
	skin.patch_margin_left = 34
	skin.patch_margin_right = 34
	skin.patch_margin_top = 34
	skin.patch_margin_bottom = 34
	skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(skin)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 18)
	pad.add_theme_constant_override("margin_right", 18)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(pad)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_child(col)

	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 6)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(head)

	var icon := TextureRect.new()
	icon.texture = _tex(icon_path)
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(icon)

	var cap := _label(caption, 13, Color("6B4A34"))
	cap.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(cap)

	var value := _label("0", 28, Color("1F7A3D"))
	value.name = "Value"
	col.add_child(value)

	return panel


# ---------------------------------------------------------------- layout

func _layout() -> void:
	var vp := get_viewport_rect().size
	if vp.x < 10.0:
		vp = Vector2(REF_W, REF_H)
	# The design reference is 540x960; scale everything against it.
	var s: float = minf(vp.x / REF_W, vp.y / REF_H)
	# On a narrow phone the rings give up space first.
	s = clampf(s, 0.62, 1.35)

	# Background covers the whole screen, no stretching.
	var bg := get_node_or_null("GardenBackground") as TextureRect
	if bg:
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# --- logo, top centre ---
	# The art is 1024x560. It gets a centred box whose height follows from its
	# own aspect ratio, so it is never squashed, and the box is narrow enough
	# to leave the top-right corner free for the coin pill.
	var logo_w: float = minf(vp.x * 0.62, 420.0 * s)
	var logo_h: float = logo_w * (560.0 / 1024.0)
	_logo.anchor_left = 0.5
	_logo.anchor_right = 0.5
	_logo.anchor_top = 0.0
	_logo.anchor_bottom = 0.0
	_logo.offset_left = -logo_w * 0.5
	_logo.offset_right = logo_w * 0.5
	_logo.offset_top = 10 * s
	_logo.offset_bottom = 10 * s + logo_h

	# --- coin pill, top right. The logo art is centred and only uses the
	# middle of its canvas, so the pill has to clear the PLAQUE, not the
	# logo's bounding box.
	_coin_pill.anchor_left = 1.0
	_coin_pill.anchor_right = 1.0
	_coin_pill.anchor_top = 0.0
	_coin_pill.anchor_bottom = 0.0
	_coin_pill.offset_left = -136 * s
	_coin_pill.offset_right = -14 * s
	_coin_pill.offset_top = 18 * s
	_coin_pill.offset_bottom = 62 * s

	# --- the ring board ---
	_ring_layer.anchor_left = 0.0
	_ring_layer.anchor_right = 1.0
	_ring_layer.anchor_top = 0.0
	_ring_layer.anchor_bottom = 1.0
	_ring_layer.offset_left = 0
	_ring_layer.offset_right = 0
	_ring_layer.offset_top = 10 * s + logo_h + 18 * s
	_ring_layer.offset_bottom = -372 * s

	# The ring composition should dominate: roughly three quarters of the
	# screen width, as long as it still fits between the logo and the cards.
	# The composition should dominate, but never so much that it crowds the
	# cards or the buttons. Capping it at 86% of the width keeps a tall phone
	# comfortable.
	var board_size: float = minf(_ring_layer.size.x * 0.86, _ring_layer.size.y - 16 * s)
	board_size = clampf(board_size, 120.0, 620.0 * s)
	var board_centre := Vector2(_ring_layer.size.x * 0.5, _ring_layer.size.y * 0.5)

	# The stone is a touch larger than the rings so the outermost arc sits
	# comfortably inside it.
	_board.size = Vector2(board_size, board_size)
	_board.position = board_centre - Vector2(board_size, board_size) * 0.5

	for ring in [_ring_outer, _ring_middle, _ring_inner]:
		ring.size = Vector2(board_size, board_size)
		ring.position = board_centre - Vector2(board_size, board_size) * 0.5
		ring.pivot_offset = Vector2(board_size, board_size) * 0.5

	var hub_size := board_size * 0.14
	_hub.size = Vector2(hub_size, hub_size)
	_hub.position = board_centre - Vector2(hub_size, hub_size) * 0.5

	_sparkle.size = Vector2(34 * s, 34 * s)
	_sparkle.position = board_centre + Vector2(board_size * 0.36, -board_size * 0.34)

	# --- stat panels ---
	var stats := get_node_or_null("Stats") as HBoxContainer
	if stats:
		stats.anchor_left = 0.0
		stats.anchor_right = 1.0
		stats.anchor_top = 1.0
		stats.anchor_bottom = 1.0
		stats.offset_left = 22 * s
		stats.offset_right = -22 * s
		stats.offset_top = -352 * s
		stats.offset_bottom = -276 * s

	# --- start button ---
	start_btn.anchor_left = 0.0
	start_btn.anchor_right = 1.0
	start_btn.anchor_top = 1.0
	start_btn.anchor_bottom = 1.0
	start_btn.offset_left = 22 * s
	start_btn.offset_right = -22 * s
	start_btn.offset_top = -264 * s
	start_btn.offset_bottom = -186 * s

	# the label and the play icon sit on top of the skin
	var play_icon := start_btn.get_node_or_null("PlayIcon") as TextureRect
	if play_icon == null:
		play_icon = TextureRect.new()
		play_icon.name = "PlayIcon"
		play_icon.texture = _tex("icons/icon_play.png")
		play_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		play_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		play_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		start_btn.add_child(play_icon)
	var start_label := start_btn.get_node_or_null("Caption") as Label
	if start_label == null:
		start_label = _label("", 21, Color.WHITE)
		start_label.name = "Caption"
		start_btn.add_child(start_label)
	play_icon.size = Vector2(40 * s, 40 * s)
	play_icon.position = Vector2(40 * s, (start_btn.size.y - 40 * s) * 0.42)
	start_label.size = Vector2(start_btn.size.x - 140 * s, start_btn.size.y * 0.62)
	start_label.position = Vector2(92 * s, 0)
	start_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	start_label.text = "START RUN"

	# the small mode line under the label
	var mode_label := start_btn.get_node_or_null("ModeLabel") as Label
	if mode_label == null:
		mode_label = _label("", 14, Color("E8FFD8"))
		mode_label.name = "ModeLabel"
		start_btn.add_child(mode_label)
	mode_label.size = Vector2(start_btn.size.x - 140 * s, 22 * s)
	mode_label.position = Vector2(92 * s, start_btn.size.y - 30 * s)
	mode_label.text = "%d MOVES" % RunController.START_BUDGET

	# --- daily button ---
	daily_btn.anchor_left = 0.0
	daily_btn.anchor_right = 1.0
	daily_btn.anchor_top = 1.0
	daily_btn.anchor_bottom = 1.0
	daily_btn.offset_left = 22 * s
	daily_btn.offset_right = -22 * s
	daily_btn.offset_top = -174 * s
	daily_btn.offset_bottom = -118 * s
	daily_lbl.size = daily_btn.size
	daily_lbl.position = Vector2.ZERO
	daily_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# --- bottom nav ---
	var nav := get_node_or_null("Nav") as HBoxContainer
	if nav:
		nav.anchor_left = 0.0
		nav.anchor_right = 1.0
		nav.anchor_top = 1.0
		nav.anchor_bottom = 1.0
		nav.offset_left = 14 * s
		nav.offset_right = -14 * s
		nav.offset_top = -106 * s
		nav.offset_bottom = -34 * s
	# The nav is a row of skins; the icon and caption go inside each one.
	# This runs after the row has been laid out, so the sizes are real.
	for btn in nav_buttons:
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var skin := btn.get_node_or_null("Skin") as TextureRect
		if skin:
			skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var icon: TextureRect = null
		for child in btn.get_children():
			if child is TextureRect and child.name != "Skin":
				icon = child
		var cap := btn.get_node_or_null("Caption") as Label
		var icon_sz := 36.0 * s
		if icon:
			icon.size = Vector2(icon_sz, icon_sz)
			icon.position = Vector2(18 * s, (btn.size.y - icon_sz) * 0.5)
		if cap:
			cap.size = Vector2(btn.size.x - 66 * s, 26 * s)
			cap.position = Vector2(60 * s, (btn.size.y - 26 * s) * 0.5)
			cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


# ---------------------------------------------------------------- behaviour

func _on_start_pressed() -> void:
	# Guard against a double tap starting two runs.
	if not is_run_active:
		return
	AudioService.play_piece_select()
	start_run_pressed.emit()


func _on_daily_pressed() -> void:
	if not is_run_active:
		return
	AudioService.play_piece_select()
	daily_run_pressed.emit()


func _emit_nav(sig: Signal) -> void:
	if not is_run_active:
		return
	AudioService.play_piece_select()
	sig.emit()


var is_run_active: bool = true


func _on_visibility_changed() -> void:
	# The ring motion stops when the menu is hidden and resumes where it left
	# off, so the rings never jump when the player comes back.
	_set_paused(not is_visible_in_tree())


func _set_paused(paused: bool) -> void:
	set_process(not paused)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_set_paused(true)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_set_paused(not is_visible_in_tree())


func _process(delta: float) -> void:
	_time += delta

	# Smooth constant angular velocity around one fixed pivot.
	_outer_angle = fposmod(_outer_angle + delta * TAU / OUTER_PERIOD, TAU)
	_middle_angle = fposmod(_middle_angle - delta * TAU / MIDDLE_PERIOD, TAU)
	_inner_angle = fposmod(_inner_angle + delta * TAU / INNER_PERIOD, TAU)
	_ring_outer.rotation = _outer_angle
	_ring_middle.rotation = _middle_angle
	_ring_inner.rotation = _inner_angle

	# The board eases in with a small scale settle.
	if _entering:
		_entering_t = minf(1.0, _entering_t + delta * 2.2)
		var e: float = 1.0 - pow(1.0 - _entering_t, 3.0)
		var scale_f: float = lerpf(0.88, 1.0, e)
		_ring_layer.scale = Vector2(scale_f, scale_f)
		_ring_layer.modulate.a = e
		if _entering_t >= 1.0:
			_entering = false
			_ring_layer.scale = Vector2.ONE

	# A slow sparkle near the board. It never intercepts input.
	_sparkle.modulate.a = 0.35 + 0.30 * sin(_time * 1.8)
	_sparkle.rotation = _time * 0.4
	_sparkle.position.y += 0.0


func refresh_stats() -> void:
	if coins_lbl != null:
		coins_lbl.text = str(int(SaveService.data.get("coins", 0)))
	if best_lbl != null:
		best_lbl.text = str(int(SaveService.data.get("best_depth", 0)))
	if streak_lbl != null:
		streak_lbl.text = "%d d" % int(SaveService.data["daily_run"].get("streak_days", 0))
	if daily_lbl != null:
		var d_num := SaveService.get_daily_number()
		var d_best := int(SaveService.data["daily_run"].get("today_best_depth", 0))
		var status := "RANKED" if SaveService.can_play_ranked_daily() else "PRACTICE"
		daily_lbl.text = "DAILY RUN #%d  (%s)  ·  BEST %d" % [d_num, status, d_best]
