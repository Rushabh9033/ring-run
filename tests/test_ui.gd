extends SceneTree

# Builds the whole UI (MainController and every screen) and checks that the
# run HUD, the board and the menus all come up without errors.
#
#   ./run_headless.sh tests/test_ui.gd

func _init() -> void:
	_go.call_deferred()

func _go() -> void:
	await process_frame
	var failures: Array[String] = []
	var mc = load("res://ui/MainController.gd").new()
	root.add_child(mc)
	await process_frame
	await process_frame
	if mc.home_screen == null: failures.append("home screen missing")
	if mc.gameplay_screen == null: failures.append("gameplay screen missing")
	if mc.perk_modal == null: failures.append("perk modal missing")
	if mc.run_over_screen == null: failures.append("run over screen missing")
	if mc.shrine_modal == null: failures.append("shrine missing")
	if mc.daily_screen == null: failures.append("daily screen missing")
	if mc.collection_screen == null: failures.append("collection missing")
	if mc.shop_modal == null: failures.append("shop missing")
	if mc.settings_modal == null: failures.append("settings missing")
	var gs = mc.gameplay_screen
	if gs != null:
		if gs.drag_controller == null: failures.append("no drag controller")
		if gs.budget_label == null: failures.append("no budget label")
		if gs.stage_label == null: failures.append("no stage label")
		if gs.power_buttons.size() != 3: failures.append("power slots != 3")
		if gs.power_slot_containers.size() != 3: failures.append("power cards != 3")
		if gs.board_root == null: failures.append("no board root")
		print("board rings loaded: %d" % gs.ring_nodes.size())
	if failures.is_empty():
		print("UI_OK")
		quit(0)
	else:
		for f in failures: print("FAIL " + f)
		print("UI_FAILED %d" % failures.size())
		quit(1)
