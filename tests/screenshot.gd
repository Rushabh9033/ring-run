extends SceneTree

# Opens the real game, waits for the board to settle and saves a screenshot.

func _init() -> void:
	_go.call_deferred()

func _go() -> void:
	await process_frame
	var mc = load("res://ui/MainController.gd").new()
	root.add_child(mc)
	await process_frame
	await process_frame
	await process_frame
	await create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png("/tmp/ringrun_board.png")
	print("SAVED /tmp/ringrun_board.png  %dx%d" % [img.get_width(), img.get_height()])
	quit(0)
