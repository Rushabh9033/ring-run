extends SceneTree
func _init() -> void:
	_go.call_deferred()
func _go() -> void:
	await process_frame
	var mc = load("res://ui/MainController.gd").new()
	root.add_child(mc)
	await process_frame
	await process_frame
	var ps = root.get_node("/root/PerkSystem")
	ps.add_active_power("rewind", 2)
	ps.add_active_power("panda_eye", 1)
	ps.passive_perks = ["thrifty", "sharp_mind"]

	mc.run_over_screen.show_summary({
		"depth": 12, "best_depth": 15, "is_new_best": false, "run_coins": 140,
		"clean_solves": 5, "can_revive": true, "is_daily": false,
		"share_card": "Daily #49 - Depth 12 - 5 Clean Solves"
	})
	await create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/ringrun_over.png")
	print("SAVED over")
	quit(0)
