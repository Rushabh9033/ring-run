extends SceneTree

# Proves the particle/VFX coordinate handling.
#
# The bug this guards against: an effect was told to place itself with
# `global_position` but was given a coordinate that was relative to its
# parent, so the shards for a ring at the board's origin ended up at screen
# (0, 0) - the top-left corner, on top of the Stage panel.
#
# Every effect is now spawned through Vfx with a GLOBAL position, and each
# effect places itself in its parent's local space.

const VfxLib = preload("res://gameplay/vfx.gd")
const RingReleaseFX = preload("res://gameplay/ring_release_fx.gd")
const ConfettiBurst = preload("res://gameplay/confetti_burst.gd")

const EFFECT_CLASSES := [
	"RingShardBurst", "CArcStarBurst", "ConfettiBurst", "CollisionSparkBurst",
]


func _init() -> void:
	_go.call_deferred()


func _go() -> void:
	await process_frame
	var failures: Array[String] = []

	var mc = load("res://ui/MainController.gd").new()
	root.add_child(mc)
	await process_frame
	await process_frame
	var rc = root.get_node("/root/RunController")
	var gs = mc.gameplay_screen

	rc.start_new_run(false)
	await process_frame
	for i in range(5):
		rc.advance_to_next_puzzle()
	await process_frame
	await process_frame

	var board: Node2D = gs.board_root as Node2D
	var board_centre: Vector2 = VfxLib.global_centre(board)

	# --- 1. a ring release puts its shards ON the ring -----------------
	# The rings are concentric, so their local position inside the board is
	# the board's origin. That is exactly the case that used to throw the
	# particles to screen (0, 0).
	await process_frame
	var expected: Vector2 = (gs.ring_nodes[0] as Node2D).global_position
	for idx in range(gs.ring_nodes.size()):
		var ring: Node2D = gs.ring_nodes[idx] as Node2D
		RingReleaseFX.play(board, ring.global_position, 70.0, Color.RED, 14.0, 1, 0.0, 44.0)
	await process_frame

	var effects: Array[Node2D] = []
	_collect(board, effects)
	if effects.is_empty():
		failures.append("no release effects were created")
	for e in effects:
		var g: Vector2 = e.global_position
		var d: float = g.distance_to(expected)
		if d > 60.0:
			failures.append("effect landed at %s, %d px from the ring at %s" % [str(g), int(d), str(expected)])

	# --- 2. nothing may sit on the Stage panel -------------------------
	# The Stage badge is the panel in the top-left of the header. An effect
	# there is the reported bug.
	var stage_badge: Control = gs.stage_label
	var stage_panel: Vector2 = stage_badge.get_global_rect().get_center()
	for e in effects:
		var g: Vector2 = e.global_position
		if g.distance_to(stage_panel) < 120.0:
			failures.append("an effect landed on the Stage panel at %s" % str(g))
		# and nothing may land on the screen origin either
		if g.distance_to(Vector2.ZERO) < 40.0:
			failures.append("an effect landed on the screen origin at %s" % str(g))

	# --- 3. the conversion itself --------------------------------------
	# A global point must convert into the parent's local space, and back.
	var probe := Node2D.new()
	probe.position = Vector2(123, 456)
	probe.scale = Vector2(2.0, 2.0)
	board.add_child(probe)
	await process_frame
	var target_global := Vector2(700, 300)
	var local: Vector2 = VfxLib.to_parent_local(board, target_global)
	var back: Vector2 = VfxLib.to_global(board, local)
	if back.distance_to(target_global) > 0.5:
		failures.append("global->local->global round trip drifted: %s vs %s" % [str(back), str(target_global)])
	probe.queue_free()

	# --- 4. the puzzle-clear confetti comes from the board --------------
	mc.perk_modal.visible = false
	gs._on_puzzle_cleared({"par": 3, "moves_used": 3, "is_clean_solve": true, "clean_bonus": 1, "refill_moves": 3, "boss_bonus": 0, "earned_coins": 10})
	await process_frame

	var confetti: Array[Node2D] = []
	_collect(gs, confetti)
	if confetti.is_empty():
		failures.append("the puzzle clear produced no confetti")
	for e in confetti:
		if e.get_script() == ConfettiBurst:
			var d: float = e.global_position.distance_to(board_centre)
			if d > 160.0:
				failures.append("the confetti burst is %d px from the board centre" % int(d))

	# --- 5. effects must clean themselves up ---------------------------
	var before: int = _count_effects(gs, board)
	await create_timer(3.2).timeout
	var after: int = _count_effects(gs, board)
	if after > before:
		failures.append("effects leaked: %d before, %d after" % [before, after])

	if failures.is_empty():
		print("VFX_OK")
		quit(0)
	else:
		for f in failures:
			print("FAIL " + f)
		print("VFX_FAILED %d" % failures.size())
		quit(1)


func ring_global_of(gs) -> Vector2:
	# The rings are concentric around the board origin.
	return VfxLib.global_centre(gs.board_root)


func _collect(node: Node, out: Array[Node2D]) -> void:
	for child in node.get_children():
		if child is Node2D:
			var cls: Script = (child as Node2D).get_script() as Script
			if cls != null and str(cls.resource_path).get_file() in [
					"ring_shard_burst.gd", "c_arc_star_burst.gd", "confetti_burst.gd"]:
				out.append(child)
		_collect(child, out)


func _count_effects(a: Node, b: Node) -> int:
	var list: Array[Node2D] = []
	_collect(a, list)
	_collect(b, list)
	return list.size()
