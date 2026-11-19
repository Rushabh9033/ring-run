extends SceneTree
# Records the puzzle-clear celebration as a sequence of frames, so the
# particle motion can be checked rather than guessed at.
func _init() -> void:
	_go.call_deferred()
func _go() -> void:
	await process_frame
	var mc = load("res://ui/MainController.gd").new()
	root.add_child(mc)
	await process_frame
	await process_frame
	var rc = root.get_node("/root/RunController")
	rc.start_new_run(false)
	await process_frame
	for i in range(5):
		rc.advance_to_next_puzzle()
	await process_frame
	mc.home_screen.visible = false
	mc.gameplay_screen.visible = true
	await create_timer(1.4).timeout
	var gs = mc.gameplay_screen
	gs._on_puzzle_cleared({"par": 3, "moves_used": 3, "is_clean_solve": true, "clean_bonus": 1,
		"refill_moves": 3, "boss_bonus": 0, "earned_coins": 10})
	for i in range(24):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/rec_%02d.png" % i)
		await process_frame
	print("RECORDED 24 frames")
	quit(0)
