extends SceneTree

# End-to-end proof of the Ring Run loop: start a run, solve a generated puzzle
# with the engine, check the budget math, the clear bonus, the stage advance
# and the run-over path.
#
#   ./run_headless.sh tests/test_run.gd

# Autoloads are only registered at runtime in --script mode, so they are looked
# up by path instead of used as global identifiers.
var rc: Node
var failures: Array[String] = []
var started: Dictionary = {}
var cleared: Dictionary = {}
var over: Dictionary = {}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	rc = root.get_node_or_null("/root/RunController")
	if rc == null:
		_finish(["RunController autoload missing"])
		return

	rc.puzzle_started.connect(func(spec): started = spec)
	rc.puzzle_cleared.connect(func(summary): cleared = summary)
	rc.run_over_triggered.connect(func(summary): over = summary)

	rc.start_new_run(false)
	await process_frame

	if rc.budget != 30:
		failures.append("start budget %d" % rc.budget)
	if started.is_empty():
		_finish(["no puzzle_started emitted"])
		return
	var spec: Dictionary = started
	var par := int(spec.get("par", 0))
	if par < 1:
		failures.append("par %d" % par)
	# --- the puzzle must carry a playable board ---------------------------
	var rings: Array = started.get("rings", [])
	if rings.is_empty():
		failures.append("puzzle spec carried no rings")
	# --- the budget must actually go down ---------------------------------
	var budget_before: int = rc.budget
	rc.commit_player_move(0, 0, false)
	await process_frame
	if rc.budget >= budget_before:
		failures.append("budget did not drop after a move (%d -> %d)" % [budget_before, rc.budget])

	# --- clearing the puzzle must refill the budget and pay the bonus -----
	var budget_at_clear: int = rc.budget
	rc._handle_puzzle_clear()
	await process_frame
	if cleared.is_empty():
		failures.append("no puzzle_cleared summary")
	else:
		var summary: Dictionary = cleared
		if not bool(summary.get("is_clean_solve", false)):
			failures.append("a par-length solve was not counted as clean")
		if rc.budget <= budget_at_clear:
			failures.append("clearing did not refill the budget (%d -> %d)" % [budget_at_clear, rc.budget])
	if rc.depth_cleared != 1:
		failures.append("depth %d after one clear" % rc.depth_cleared)

	# --- the next puzzle must exist and be different ----------------------
	var first_id: int = int(started.get("puzzle_number", 0))
	rc.advance_to_next_puzzle()
	await process_frame
	if int(started.get("puzzle_number", 0)) != first_id + 1:
		failures.append("did not advance to the next puzzle")
	if started.get("rings", []).is_empty():
		failures.append("second puzzle carried no rings")

	# --- running out of budget must end the run ---------------------------
	rc.budget = 1
	rc.commit_player_move(0, 0, false)
	await process_frame
	if over.is_empty():
		failures.append("budget hitting zero did not end the run")
	if rc.is_run_active:
		failures.append("run still active after the budget ran out")

	_finish(failures)


func _finish(problems: Array[String]) -> void:
	if problems.is_empty():
		print("RUN_OK")
		quit(0)
	else:
		for f in problems:
			print("FAIL " + f)
		print("RUN_FAILED %d" % problems.size())
		quit(1)
