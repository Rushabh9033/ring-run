extends SceneTree

# Capture every screen and modal of Ring Run at full 720x1280 resolution.

const OUT_DIR := "res://screenshots/all_screens"

func _init() -> void:
	_go.call_deferred()

func _go() -> void:
	var dir := DirAccess.open("res://")
	if dir and not dir.dir_exists("screenshots/all_screens"):
		dir.make_dir_recursive("screenshots/all_screens")

	var win := root.get_window()
	if win == null:
		win = root
	win.size = Vector2i(720, 1280)
	await process_frame
	await process_frame

	var mc = load("res://ui/MainController.gd").new()
	root.add_child(mc)
	await process_frame
	await process_frame

	var rc = root.get_node("/root/RunController")
	var ps = root.get_node("/root/PerkSystem")

	# Hide all screens initially
	for s in [mc.home_screen, mc.gameplay_screen, mc.perk_modal, mc.shrine_modal,
			mc.run_over_screen, mc.daily_screen, mc.collection_screen,
			mc.shop_modal, mc.settings_modal, mc.stage_banner, mc.boss_banner]:
		if s != null:
			s.visible = false

	# 1. HOME SCREEN
	mc.home_screen.visible = true
	mc.home_screen.refresh_stats()
	await create_timer(1.2).timeout
	await _shot("01_home_screen")
	mc.home_screen.visible = false

	# 2. GAMEPLAY BOARD
	rc.start_new_run(false)
	await process_frame
	for i in range(4):
		rc.advance_to_next_puzzle()
	await process_frame
	ps.add_active_power("panda_eye", 2)
	ps.add_active_power("rewind", 1)
	ps.add_active_power("free_spin", 3)
	mc.gameplay_screen.visible = true
	await create_timer(1.2).timeout
	await _shot("02_gameplay_board")

	# 3. PERK CHOICE MODAL
	var cards: Array = ps.draw_cards(rc.rng, false, false)
	mc.perk_modal.present_cards(cards, {
		"puzzle_number": 4, "par": 3, "moves_used": 3,
		"is_clean_solve": true, "clean_bonus": 1, "refill_moves": 4,
		"earned_coins": 20, "hot_streak": 2
	})
	mc.perk_modal.visible = true
	await create_timer(0.8).timeout
	await _shot("03_perk_choice_modal")
	mc.perk_modal.visible = false

	# 4. SHRINE SACRIFICE MODAL
	mc.shrine_modal.show_shrine()
	mc.shrine_modal.visible = true
	await create_timer(0.8).timeout
	await _shot("04_shrine_modal")
	mc.shrine_modal.visible = false

	# 5. BOSS CURSE BANNER
	mc.boss_banner.show_banner(true, ["heavy_ring"])
	mc.boss_banner.visible = true
	await create_timer(0.6).timeout
	await _shot("05_boss_banner")
	mc.boss_banner.visible = false

	# 6. RUN OVER SCREEN
	mc.run_over_screen.show_summary({
		"depth": 14,
		"best_depth": 18,
		"is_new_best": false,
		"run_coins": 185,
		"clean_solves": 6,
		"can_revive": true,
		"is_daily": false,
		"share_card": "🎋 Ring Run · Depth 14 · 6 Clean Solves"
	})
	mc.run_over_screen.visible = true
	await create_timer(0.8).timeout
	await _shot("06_run_over_screen")
	mc.run_over_screen.visible = false

	# 7. DAILY RUN SCREEN
	mc.daily_screen.refresh_view()
	mc.daily_screen.visible = true
	await create_timer(0.8).timeout
	await _shot("07_daily_run_screen")
	mc.daily_screen.visible = false

	# 8. COLLECTION SCREEN
	mc.collection_screen.visible = true
	await create_timer(0.8).timeout
	await _shot("08_collection_screen")
	mc.collection_screen.visible = false

	# 9. SHOP MODAL
	mc.shop_modal.visible = true
	await create_timer(0.8).timeout
	await _shot("09_shop_modal")
	mc.shop_modal.visible = false

	# 10. SETTINGS & PAUSE MODAL
	mc.settings_modal.visible = true
	await create_timer(0.8).timeout
	await _shot("10_settings_modal")
	mc.settings_modal.visible = false

	print("ALL_SCREENS_CAPTURED_SUCCESSFULLY")
	quit(0)

func _shot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var global_path := ProjectSettings.globalize_path("%s/%s.png" % [OUT_DIR, file_name])
	img.save_png(global_path)
	print("Saved: %s (%dx%d)" % [global_path, img.get_width(), img.get_height()])
