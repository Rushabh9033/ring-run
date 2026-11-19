extends SceneTree
# Proves the home screen is wired to real state: live numbers, working
# buttons, and rings that turn around one fixed centre.

func _init() -> void:
	_go.call_deferred()

func _go() -> void:
	await process_frame
	var failures: Array[String] = []
	var mc = load("res://ui/MainController.gd").new()
	root.add_child(mc)
	await process_frame
	await process_frame

	var hs = mc.home_screen
	if hs == null:
		_finish(["no home screen"])
		return

	# --- live numbers -------------------------------------------------
	var ss = root.get_node("/root/SaveService")
	ss.data["coins"] = 777
	ss.data["best_depth"] = 13
	ss.data["daily_run"]["streak_days"] = 5
	ss.save_updated.emit()
	await process_frame
	if hs.coins_lbl.text != "777":
		failures.append("coins show %s not 777" % hs.coins_lbl.text)
	if hs.best_lbl.text != "13":
		failures.append("best depth shows %s not 13" % hs.best_lbl.text)
	if not hs.streak_lbl.text.begins_with("5"):
		failures.append("streak shows %s not 5d" % hs.streak_lbl.text)

	# --- every asset the screen uses must exist -----------------------
	var missing: Array[String] = []
	for path in [
		"backgrounds/bamboo_garden_menu.png", "branding/ring_run_logo.png",
		"rings/zen_stone_board.png", "rings/ring_outer_purple.png",
		"rings/ring_middle_orange.png", "rings/ring_inner_blue.png",
		"rings/center_hub.png", "ui/panel_stat.png", "ui/pill_currency.png",
		"ui/button_nav.png", "ui/button_daily.png", "ui/button_start_normal.png",
		"icons/icon_coin.png", "icons/icon_collection.png", "icons/icon_shop.png",
		"icons/icon_settings.png", "icons/icon_play.png", "icons/icon_trophy.png",
		"icons/icon_flame.png", "effects/sparkle_gold.png",
	]:
		if not ResourceLoader.exists("res://assets/ui/ring_run_zen/" + path):
			missing.append(path)
	for m in missing:
		failures.append("missing asset %s" % m)

	# --- the rings must share one centre and turn ----------------------
	# All three arcs have to pivot on the exact same point, or the board
	# wobbles while it turns.
	var centre = _ring_centre(hs)
	for name in ["_ring_outer", "_ring_middle", "_ring_inner"]:
		var r = hs.get(name) as TextureRect
		if r == null:
			failures.append("%s missing" % name)
			continue
		if (r.position + r.size * 0.5).distance_to(centre) > 1.0:
			failures.append("%s is not centred" % name)
		if r.pivot_offset.distance_to(r.size * 0.5) > 1.0:
			failures.append("%s does not pivot on its centre" % name)

	var outer = hs.get("_ring_outer") as TextureRect
	var before = outer.rotation
	for i in range(30):
		await process_frame
	if absf(outer.rotation - before) < 0.001:
		failures.append("the outer ring is not turning")

	# --- the buttons fire the real signals -----------------------------
	var fired: Array[String] = []
	hs.start_run_pressed.connect(func(): fired.append("start"))
	hs.daily_run_pressed.connect(func(): fired.append("daily"))
	hs.collection_pressed.connect(func(): fired.append("collection"))
	hs.shop_pressed.connect(func(): fired.append("shop"))
	hs.settings_pressed.connect(func(): fired.append("settings"))

	_click(hs.start_btn)
	_click(hs.daily_btn)
	for btn in hs.nav_buttons:
		_click(btn)
	await process_frame
	for want in ["start", "daily", "collection", "shop", "settings"]:
		if not fired.has(want):
			failures.append("%s did not fire" % want)

	_finish(failures)


func _ring_centre(hs) -> Vector2:
	var outer = hs.get("_ring_outer") as TextureRect
	return outer.position + outer.size * 0.5


func _click(control: Control) -> void:
	var hit := control.get_node_or_null("Hit") as Button
	if hit == null:
		hit = control as Button
	if hit == null:
		return
	hit.emit_signal("pressed")


func _finish(problems: Array[String]) -> void:
	if problems.is_empty():
		print("HOME_OK")
		quit(0)
	else:
		for p in problems:
			print("FAIL " + p)
		print("HOME_FAILED %d" % problems.size())
		quit(1)
