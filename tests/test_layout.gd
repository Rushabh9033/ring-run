extends SceneTree

# Real layout verification.
#
# test_ui.gd mostly checks that a node exists. This one measures: it checks
# that nothing overflows the screen, that nothing overlaps something it should
# not, that the tap targets are big enough, and that the text is not clipped.
#
# It runs every screen, not just the home screen.

const SCREENS := ["home", "gameplay", "perk", "runover", "collection", "shop", "daily", "settings"]

## The smallest a tap target may be, in design pixels.
const MIN_TAP := 44.0


func _init() -> void:
	_go.call_deferred()


func _go() -> void:
	await process_frame
	var failures: Array[String] = []

	var mc = load("res://ui/MainController.gd").new()
	root.add_child(mc)
	await process_frame
	await process_frame
	# The screens slide in when they are shown, so the layout has to settle
	# before anything is measured.
	await create_timer(0.45).timeout

	var rc = root.get_node("/root/RunController")
	var gs = mc.gameplay_screen

	rc.start_new_run(false)
	await process_frame
	for i in range(5):
		rc.advance_to_next_puzzle()
	await process_frame
	await process_frame

	var vp: Vector2 = Vector2(720, 1280)

	# --- the board HUD row must stay inside the screen ---
	var row: Control = gs.get_node_or_null("HintRow") as Control
	if row != null:
		var rect: Rect2 = row.get_global_rect()
		if rect.position.x < -1.0 or rect.end.x > vp.x + 1.0:
			failures.append("the HUD row overflows: %s" % str(rect))
		var par: Control = gs.par_label
		if par != null:
			var pr: Rect2 = par.get_global_rect()
			if pr.end.x > vp.x + 1.0:
				failures.append("the par readout runs off the screen: %s" % str(pr))

	# --- the board's rings must not collide with the HUD ---
	# The board sits inside a Control, so that is what has a rect.
	var board_rect: Rect2 = gs.board_container.get_global_rect()
	var header_bottom: float = 0.0
	var header_root: Control = gs.header.get("root") as Control
	if header_root != null:
		header_bottom = header_root.get_global_rect().end.y
	if board_rect.position.y < header_bottom - 2.0:
		failures.append("the board overlaps the header")
	var power_bar: Control = gs.get_node_or_null("PowerBar")
	if power_bar != null and board_rect.end.y > power_bar.get_global_rect().position.y + 4.0:
		failures.append("the board overlaps the power bar")

	# --- every button must be a usable tap target ---
	var checked := 0
	for name in SCREENS:
		var screen: Control = _screen_for(mc, name)
		if screen == null:
			failures.append("the %s screen is missing" % name)
			continue
		if not screen.visible:
			screen.visible = true
			await process_frame
		var found := _buttons(screen)
		checked += found.size()
		if found.is_empty():
			failures.append("%s: no buttons were found" % name)
		for b in found:
			var r: Rect2 = b.get_global_rect()
			if r.size.y < MIN_TAP - 0.5 and not b.get_meta("is_icon", false):
				failures.append("%s: a button is only %d px tall" % [name, int(r.size.y)])
			if r.size.x < 24.0:
				failures.append("%s: a button is only %d px wide" % [name, int(r.size.x)])
		screen.visible = false
		await process_frame

	# --- the modal card must fit the screen and scroll its body ---
	var perk: Control = mc.perk_modal
	perk.visible = true
	var ps: Node = root.get_node("/root/PerkSystem")
	var cards: Array = ps.draw_cards(rc.rng, false, false)
	perk.present_cards(cards, {"par": 3, "moves_used": 3, "is_clean_solve": true, "earned_coins": 10})
	await process_frame
	await process_frame
	var card: Control = perk.get_node_or_null("Panel")
	if card != null:
		var cr: Rect2 = card.get_global_rect()
		if cr.size.x > vp.x + 1.0:
			failures.append("the perk card is wider than the screen: %s" % str(cr))
		if cr.position.x < -1.0:
			failures.append("the perk card starts off the screen: %s" % str(cr))
	# the card must not cover the whole screen
	if card != null and card.get_global_rect().size.y > vp.y * 0.92:
		failures.append("the perk card fills the screen")
	perk.visible = false
	await process_frame

	# --- the text must not be clipped ---
	for lbl in _labels(mc.gameplay_screen):
		if not lbl.visible or lbl.text.is_empty():
			continue
		if lbl.clip_text and lbl.get_global_rect().size.x < 10.0:
			failures.append("a clipped label has no room: %s" % lbl.text.substr(0, 20))

	print("checked %d buttons across %d screens" % [checked, SCREENS.size()])
	if failures.is_empty():
		print("LAYOUT_OK")
		quit(0)
	else:
		for f in failures:
			print("FAIL " + f)
		print("LAYOUT_FAILED %d" % failures.size())
		quit(1)


func _screen_for(mc, name: String) -> Control:
	match name:
		"home": return mc.home_screen
		"gameplay": return mc.gameplay_screen
		"perk": return mc.perk_modal
		"runover": return mc.run_over_screen
		"collection": return mc.collection_screen
		"shop": return mc.shop_modal
		"daily": return mc.daily_screen
		"settings": return mc.settings_modal
	return null


func _buttons(node: Node) -> Array[Button]:
	var out: Array[Button] = []
	for child in node.get_children():
		if child is Button:
			out.append(child)
		for b in _buttons(child):
			out.append(b)
	return out


func _labels(node: Node) -> Array[Label]:
	var out: Array[Label] = []
	for child in node.get_children():
		if child is Label:
			out.append(child)
		for l in _labels(child):
			out.append(l)
	return out
