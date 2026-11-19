extends SceneTree
func _init() -> void:
	_go.call_deferred()
func _go() -> void:
	await process_frame
	var mc = load("res://ui/MainController.gd").new()
	root.add_child(mc)
	await process_frame
	await process_frame
	mc.gameplay_screen.visible = false
	mc.home_screen.visible = true
	mc.home_screen.refresh_stats()
	await create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/ringrun_home.png")
	print("SAVED home")
	quit(0)
