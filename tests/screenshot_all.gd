extends SceneTree
# Captures every screen so the whole UI can be reviewed at once.
func _init() -> void:
	_go.call_deferred()

func _go() -> void:
	await process_frame
	var mc = load("res://ui/MainController.gd").new()
	root.add_child(mc)
	await process_frame
	await process_frame
	var rc = root.get_node("/root/RunController")
	# --- board ---
	var ps = root.get_node("/root/PerkSystem")
	rc.start_new_run(false)
	await process_frame
	for i in range(5):
		rc.advance_to_next_puzzle()
	await process_frame
	mc.home_screen.visible = false
	mc.gameplay_screen.visible = true
	ps.add_active_power("panda_eye", 2)
	ps.add_active_power("rewind", 1)
	await create_timer(1.8).timeout
	await _shot("board")

	# --- perk choice ---
	var cards: Array = ps.draw_cards(rc.rng, false, false)
	mc.perk_modal.present_cards(cards, {"par": 3, "moves_used": 3, "is_clean_solve": true, "earned_coins": 10})
	await create_timer(0.6).timeout
	await _shot("perk")
	mc.perk_modal.visible = false

	# --- run over ---
	mc.run_over_screen.show_summary({
		"depth": 12, "best_depth": 15, "is_new_best": false, "run_coins": 140,
		"clean_solves": 5, "can_revive": true, "is_daily": false, "share_card": "x"})
	await create_timer(0.6).timeout
	await _shot("over")
	mc.run_over_screen.visible = false

	# --- collection ---
	mc.collection_screen.visible = true
	await create_timer(0.5).timeout
	await _shot("collection")
	mc.collection_screen.visible = false

	# --- shop ---
	mc.shop_modal.visible = true
	await create_timer(0.5).timeout
	await _shot("shop")
	mc.shop_modal.visible = false

	# --- daily ---
	mc.daily_screen.refresh_view()
	mc.daily_screen.visible = true
	await create_timer(0.5).timeout
	await _shot("daily")
	mc.daily_screen.visible = false

	# --- settings ---
	mc.settings_modal.visible = true
	await create_timer(0.5).timeout
	await _shot("settings")
	mc.settings_modal.visible = false

	# --- home ---
	mc.home_screen.visible = true
	await create_timer(0.8).timeout
	await _shot("home")

	print("SHOTS DONE")
	quit(0)

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/ui_%s.png" % name)
