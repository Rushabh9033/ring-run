class_name RunOverScreen
extends Control
## RunOverScreen — Displays Depth vs Best Depth, Near-Miss callout, perks row,
## Revive (+8 moves ad), Double Coins (ad), Share Card, New Run, and Home button.

signal revive_pressed()
signal new_run_pressed()
signal home_pressed()

var last_summary: Dictionary = {}
var coins_doubled: bool = false
var depth_lbl: Label
var compare_lbl: Label
var coins_lbl: Label
var revive_btn: Control
var double_btn: Control
var share_btn: Control
var build_row: HBoxContainer = null
var panel: PanelContainer = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	RingTheme.bamboo_background(self, 0.55)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.16, 0.12, 0.85)
	add_child(bg)

	# Anchored, not centred: a CenterContainer lets the panel collapse to the
	# text's minimum width, which squeezed the whole screen into a column.
	# A centred card that hugs its content: the run-over screen is short, and a
	# full-height card would be a big empty slab.
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)

	var center := MarginContainer.new()
	center.add_theme_constant_override("margin_left", 20)
	center.add_theme_constant_override("margin_right", 20)
	center.add_theme_constant_override("margin_top", 40)
	center.add_theme_constant_override("margin_bottom", 40)
	holder.add_child(center)

	panel = RingTheme.gold_panel()
	panel.custom_minimum_size = Vector2(430, 0)
	center.add_child(panel)

	var vbox := panel.get_node("Pad/Content") as VBoxContainer
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 8)
	vbox.add_child(head)
	var trophy := RingTheme.zen_icon(head, "icons/icon_trophy.png", 28)
	trophy.size = Vector2(28, 28)
	var r_title := RingTheme.label("RUN OVER", 30, RingTheme.DANGER)
	r_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(r_title)
	depth_lbl = RingTheme.label("Depth Cleared: 0", 24, RingTheme.INK)
	compare_lbl = RingTheme.label("Best Depth: 0", 15, RingTheme.MUTED)
	coins_lbl = RingTheme.label("Coins Earned: +0", 16, RingTheme.BAMBOO)
	vbox.add_child(depth_lbl)
	vbox.add_child(compare_lbl)
	vbox.add_child(coins_lbl)

	# The build the player assembled, as a row of perk names.
	build_row = HBoxContainer.new()
	build_row.alignment = BoxContainer.ALIGNMENT_CENTER
	build_row.add_theme_constant_override("separation", 6)
	vbox.add_child(build_row)
	var build_cap := RingTheme.label("YOUR BUILD", 11, RingTheme.MUTED)
	build_cap.autowrap_mode = TextServer.AUTOWRAP_OFF
	vbox.add_child(build_cap)

	revive_btn = RingTheme.zen_button("nav", "REVIVE +8 MOVES  (Ad)", 15, 50)
	(revive_btn.get_node("Hit") as Button).pressed.connect(trigger_revive)
	vbox.add_child(revive_btn)

	double_btn = RingTheme.zen_button("nav", "DOUBLE COINS 2x  (Ad)", 15, 50)
	(double_btn.get_node("Hit") as Button).pressed.connect(trigger_double_coins)
	vbox.add_child(double_btn)

	var new_run_btn := RingTheme.zen_button("primary", "NEW RUN  ·  30 MOVES", 17, 58)
	(new_run_btn.get_node("Hit") as Button).pressed.connect(trigger_new_run)
	vbox.add_child(new_run_btn)

	share_btn = RingTheme.zen_button("nav", "SHARE RESULT CARD", 14, 46)
	(share_btn.get_node("Hit") as Button).pressed.connect(func():
		var card := str(last_summary.get("share_card", "Ring Run · Depth 0"))
		PlatformServices.share_text_card(card)
		_set_share_text("Copied: " + card)
	)
	vbox.add_child(share_btn)

	var home_btn := RingTheme.zen_button("nav", "BACK TO HOME", 14, 46)
	(home_btn.get_node("Hit") as Button).pressed.connect(func():
		visible = false
		home_pressed.emit()
	)
	vbox.add_child(home_btn)

## Fill the perk row with the build the player took into the run.
func _refresh_build_row() -> void:
	if build_row == null:
		return
	for c in build_row.get_children():
		c.queue_free()
	for perk_id in PerkSystem.passive_perks:
		var meta: Dictionary = PerkSystem.TOOLS_CATALOG.get(perk_id, {})
		build_row.add_child(RingTheme.perk_pill(str(meta.get("name", perk_id))))
	for slot in PerkSystem.active_slots:
		var smeta: Dictionary = PerkSystem.TOOLS_CATALOG.get(str(slot.get("id", "")), {})
		build_row.add_child(RingTheme.perk_pill(str(smeta.get("name", ""))))
	if build_row.get_child_count() == 0:
		var empty := RingTheme.label("No perks collected", 12, RingTheme.MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_OFF
		build_row.add_child(empty)


func show_summary(summary: Dictionary) -> void:
	last_summary = summary
	coins_doubled = false
	var depth := int(summary.get("depth", 0))
	var best := int(summary.get("best_depth", depth))
	depth_lbl.text = "Depth Cleared: %d" % depth
	if bool(summary.get("is_new_best", false)):
		compare_lbl.text = "NEW PERSONAL BEST DEPTH!"
	else:
		compare_lbl.text = "Best Depth: %d (%d away from best)" % [best, maxi(1, best - depth)]
	coins_lbl.text = "Coins Earned: +%d   ·   Clean Solves: %d" % [
		int(summary.get("run_coins", 0)),
		int(summary.get("clean_solves", 0))
	]
	_refresh_build_row()
	revive_btn.visible = bool(summary.get("can_revive", false))
	_set_button_text(double_btn, "DOUBLE COINS 2x  (Ad)")
	_set_button_text(share_btn, "SHARE RESULT CARD")
	visible = true
	# Dress after a frame has passed so the panel has its final size. This is
	# deferred with a timer, not an await: these run from a signal handler and
	# an await there would stall the caller.
	if panel != null:
		var dress := func() -> void: RingTheme.dress_modal(panel, self, true)
		get_tree().create_timer(0.05).timeout.connect(dress)
	RingTheme.present_modal(self)

## Set the caption on a zen button.
func _set_button_text(btn: Control, text: String) -> void:
	if btn == null:
		return
	var cap := btn.get_node_or_null("Caption") as Label
	if cap != null:
		cap.text = text


func _set_share_text(text: String) -> void:
	_set_button_text(share_btn, text)


func trigger_revive() -> void:
	if not bool(last_summary.get("can_revive", false)):
		return
	PlatformServices.show_rewarded_ad("revive_plus_8", func():
		if RunController.revive_with_rewarded_ad():
			visible = false
			revive_pressed.emit()
	)

func trigger_double_coins() -> void:
	if coins_doubled:
		return
	PlatformServices.show_rewarded_ad("double_run_coins", func():
		coins_doubled = true
		var extra := int(last_summary.get("run_coins", 0))
		SaveService.data["coins"] = int(SaveService.data.get("coins", 0)) + extra
		SaveService.save_game()
		_set_button_text(double_btn, "Coins Doubled! (+%d)" % (extra * 2))
	)

func trigger_new_run() -> void:
	PlatformServices.maybe_show_interstitial_on_new_run()
	visible = false
	new_run_pressed.emit()
