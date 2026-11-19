extends SceneTree
func _init() -> void:
	_go.call_deferred()
func _go() -> void:
	await process_frame
	var mc = load("res://ui/MainController.gd").new()
	root.add_child(mc)
	await process_frame
	await process_frame
	var rc = root.get_node("/root/RunController")
	var ps = root.get_node("/root/PerkSystem")
	var cards: Array = ps.draw_cards(rc.rng, false, false)
	print("cards: ", cards.size())
	mc.home_screen.visible = false
	mc.gameplay_screen.visible = true
	mc.perk_modal.present_cards(cards, {"par": 3, "moves_used": 3, "is_clean_solve": true, "earned_coins": 10})
	await create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/ringrun_perks.png")
	print("SAVED perks")
	quit(0)
