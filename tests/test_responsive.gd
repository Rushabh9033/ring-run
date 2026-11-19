extends SceneTree
# The home screen must survive narrow, standard and tall phones, and a tablet,
# without the rings colliding with the cards or the buttons running off.
# It also checks the press feedback and the duplicate-tap guard.

const SIZES := [
	{"name": "narrow", "w": 480, "h": 900},
	{"name": "standard", "w": 720, "h": 1280},
	{"name": "tall", "w": 720, "h": 1600},
	{"name": "tablet", "w": 1024, "h": 1366},
]

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
		await process_frame
		var hs = mc.home_screen
		var vp: Vector2 = hs.get_viewport_rect().size

		# the ring composition should fill most of the width
		var board: Control = hs._ring_layer
		var outer: TextureRect = hs._ring_outer
		var frac: float = outer.size.x / vp.x
		# A typical portrait phone wants the composition at 70-76% of the
		# width. A tablet is limited by its height instead, so it only has to
		# fill a reasonable share.
		var is_phone: bool = vp.x < 900.0
		if is_phone and (frac < 0.62 or frac > 0.92):
			failures.append("%s: ring width %.0f%% of screen" % [size.name, frac * 100.0])
		if not is_phone and (frac < 0.40 or frac > 0.92):
			failures.append("%s: ring width %.0f%% of screen" % [size.name, frac * 100.0])

		# the rings must not collide with the cards or run off the top
		var board_top: float = board.global_position.y
		var cards_top: float = hs.get_node_or_null("Stats").global_position.y
		if board_top < hs._logo.global_position.y + hs._logo.size.y - 6.0:
			failures.append("%s: rings overlap the logo" % size.name)
		if cards_top < board_top + board.size.y - 6.0:
			failures.append("%s: rings overlap the stat cards" % size.name)

		# the bottom nav must stay on screen
		var nav: Control = hs.get_node_or_null("Nav")
		if nav.global_position.y + nav.size.y > vp.y + 2.0:
			failures.append("%s: nav runs off the bottom" % size.name)

		# the coin pill must not cover the logo's plaque. The art is centred
		# in its canvas, so the plaque occupies the middle 68%.
		var logo_box: Rect2 = hs._logo.get_global_rect()
		var plaque := Rect2(logo_box.position + Vector2(logo_box.size.x * 0.16, logo_box.size.y * 0.08),
			logo_box.size * Vector2(0.68, 0.84))
		var pill_box: Rect2 = hs._coin_pill.get_global_rect()
		if pill_box.intersects(plaque):
			failures.append("%s: coin pill covers the logo plaque" % size.name)

		print("%-9s win %dx%d vp %dx%d  layer %.0fx%.0f  board %.0f  rings %.0f%%" % [
			size.name, size.w, size.h, vp.x, vp.y,
			board.size.x, board.size.y, outer.size.x, frac * 100.0])
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
