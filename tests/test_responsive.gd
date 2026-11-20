extends SceneTree

# Responsive verification for EVERY screen, not just the home screen.
#
# On a narrow phone, a standard portrait phone, a tall phone and a tablet:
# nothing may overflow the screen, nothing may overlap something it should
# not, and the core actions must stay reachable.

const SIZES := [
	{"name": "narrow", "w": 480, "h": 900},
	{"name": "standard", "w": 720, "h": 1280},
	{"name": "tall", "w": 720, "h": 1600},
	{"name": "tablet", "w": 1024, "h": 1366},
]

const SCREENS := ["home", "gameplay", "perk", "runover", "collection", "shop", "daily", "settings"]


func _init() -> void:
	_go.call_deferred()


func _go() -> void:
	await process_frame
	var failures: Array[String] = []
	var win := root.get_window()
	if win == null:
		win = root

	for size in SIZES:
		win.size = Vector2i(int(size.w), int(size.h))
		await process_frame
		await process_frame

		var mc = load("res://ui/MainController.gd").new()
		root.add_child(mc)
		await process_frame
		await process_frame
		# The screens slide in when they are shown, so the layout has to
		# settle before anything is measured.
		await create_timer(0.45).timeout

		var rc = root.get_node("/root/RunController")
		rc.start_new_run(false)
		await process_frame
		for i in range(5):
			rc.advance_to_next_puzzle()
		await process_frame
		await process_frame

		var vp: Vector2 = mc.get_viewport_rect().size

		# --- the home screen: the rings must dominate a phone -----------
		var hs = mc.home_screen
		var outer: TextureRect = hs.get("_ring_outer") as TextureRect
		var frac: float = outer.size.x / vp.x
		var is_phone: bool = vp.x < 900.0
		if is_phone and (frac < 0.62 or frac > 0.92):
			failures.append("%s: ring width %.0f%% of screen" % [size.name, frac * 100.0])
		if not is_phone and (frac < 0.40 or frac > 0.92):
			failures.append("%s: ring width %.0f%% of screen" % [size.name, frac * 100.0])

		# the rings must not collide with the logo or the stat cards
		var board: Control = hs.get("_ring_layer") as Control
		var logo: Control = hs.get("_logo") as Control
		var stats: Control = hs.get_node_or_null("Stats") as Control
		if logo != null and board != null:
			if board.global_position.y < logo.global_position.y + logo.size.y - 6.0:
				failures.append("%s: the rings overlap the logo" % size.name)
		if stats != null and board != null:
			if stats.global_position.y < board.global_position.y + board.size.y - 6.0:
				failures.append("%s: the rings overlap the stat cards" % size.name)

		# the coin pill must not cover the logo's plaque
		var pill: Control = hs.get("_coin_pill") as Control
		if pill != null and logo != null:
			var plaque := Rect2(logo.get_global_rect().position + Vector2(logo.size.x * 0.16, logo.size.y * 0.08),
				Vector2(logo.size.x * 0.68, logo.size.y * 0.84))
			if pill.get_global_rect().intersects(plaque):
				failures.append("%s: the coin pill covers the logo plaque" % size.name)

		# --- every screen must fit -------------------------------------
		for name in SCREENS:
			var screen: Control = _screen_for(mc, name)
			if screen == null:
				failures.append("%s: the %s screen is missing" % [size.name, name])
				continue
			var was_visible: bool = screen.visible
			screen.visible = true
			await process_frame
			await process_frame

			var over := _overflowing(screen, vp)
			for o in over:
				failures.append("%s/%s: %s" % [size.name, name, o])

			screen.visible = was_visible
			await process_frame

		print("%-9s %dx%d  rings %.0f%% wide" % [size.name, size.w, size.h, frac * 100.0])
		mc.queue_free()
		await process_frame

	if failures.is_empty():
		print("RESPONSIVE_OK")
		quit(0)
	else:
		for f in failures:
			print("FAIL " + f)
		print("RESPONSIVE_FAILED %d" % failures.size())
		quit(1)


## Anything on a screen that sticks out past the viewport.
func _overflowing(screen: Control, vp: Vector2) -> Array[String]:
	var out: Array[String] = []
	for c in _walk(screen):
		if not (c is Control):
			continue
		var ctrl := c as Control
		if not ctrl.visible:
			continue
		if ctrl.size.x < 2.0 or ctrl.size.y < 2.0:
			continue
		# The ring canvases are 1024x1024 images with transparent margins, so
		# their bounding box is meant to be bigger than the screen. The art
		# inside them is not.
		if ctrl.name.begins_with("ring_") and ctrl.name.ends_with("_png"):
			continue
		var r: Rect2 = ctrl.get_global_rect()
		if r.position.x < -2.0:
			out.append("%s starts off the left edge" % ctrl.name)
		if r.end.x > vp.x + 2.0:
			out.append("%s runs off the right edge (%.0f > %.0f)" % [ctrl.name, r.end.x, vp.x])
		if r.position.y < -2.0:
			out.append("%s starts off the top" % ctrl.name)
		if r.end.y > vp.y + 2.0:
			out.append("%s runs off the bottom (%.0f > %.0f)" % [ctrl.name, r.end.y, vp.y])
	return out


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_walk(child))
	return out


func _screen_for(mc, name: String) -> Control:
	match name:
		"home": return mc.home_screen
		"gameplay": return mc.gameplay_screen
		"perk": return mc.perk_modal
		"runover": return mc.run_over_screen
		"collection": return mc.collection_screen
		"shop": return mc.shop_modal
		"daily": return mc.daily_screen
		"settings": return mc.settings_modal
	return null
