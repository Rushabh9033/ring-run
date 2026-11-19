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
	rc.start_new_run(false)
	await process_frame
	for i in range(5):
		rc.advance_to_next_puzzle()
	await process_frame
	mc.home_screen.visible = false
	mc.gameplay_screen.visible = true
	await create_timer(0.30).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/ringrun_banner.png")
	print("SAVED banner")
	quit(0)
