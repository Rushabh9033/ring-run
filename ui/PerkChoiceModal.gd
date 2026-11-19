class_name PerkChoiceModal
extends Control
## PerkChoiceModal — Displays 3 (or 4 with Lucky Paw) build cards after clearing
## a puzzle.
##
## The layout follows the Rotate Rings look: a parchment card with a thick
## bamboo-wood border, one bamboo-framed row per card with the tool icon in a
## recessed well, a rarity chip and a charge chip on the right, and a chunky
## green button for the reroll.

signal card_selected(card: Dictionary)

const CoinFlyAnimationScript = preload("res://gameplay/CoinFlyAnimation.gd")

var current_cards: Array[Dictionary] = []
var reroll_used_this_puzzle: bool = false
var summary_lbl: Label
var cards_vbox: VBoxContainer
var reroll_btn: Button
var panel: PanelContainer = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.12, 0.05, 0.68)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	center.add_child(margin)

	panel = PanelContainer.new()
	# As wide as the phone allows, with a floor for very small screens.
	var vp := get_viewport_rect().size
	panel.custom_minimum_size = Vector2(clampf(vp.x - 28.0, 260.0, 520.0), 0)
	panel.add_theme_stylebox_override("panel", RingTheme.wood_card())
	margin.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := RingTheme.label("PUZZLE CLEARED!", 26, RingTheme.BAMBOO_DARK)
	vbox.add_child(title)

	summary_lbl = RingTheme.label("", 14, RingTheme.INK)
	summary_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	vbox.add_child(summary_lbl)

	var sub := RingTheme.label("Choose a power or passive perk for your build", 13, RingTheme.MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	vbox.add_child(sub)

	cards_vbox = VBoxContainer.new()
	cards_vbox.add_theme_constant_override("separation", 10)
	vbox.add_child(cards_vbox)

	reroll_btn = RingTheme.button("Reroll Cards (Rewarded Ad)", "secondary", Vector2(0, 52), 15)
	reroll_btn.pressed.connect(request_reroll_ad)
	vbox.add_child(reroll_btn)


## `coin_target` is the global position of the real coin counter in the HUD.
## `coin_origin` is where the reward was earned. Both are optional: without a
## target the coins simply do not fly.
func present_cards(cards: Array[Dictionary], clear_summary: Dictionary = {}, coin_origin: Vector2 = Vector2.ZERO, coin_target: Vector2 = Vector2.ZERO) -> void:
	current_cards = cards
	reroll_used_this_puzzle = false
	if reroll_btn != null:
		reroll_btn.disabled = false
		reroll_btn.text = "Reroll Cards (Rewarded Ad)"
	if summary_lbl != null and not clear_summary.is_empty():
		var parts := PackedStringArray()
		if bool(clear_summary.get("is_clean_solve", false)):
			parts.append("Clean Solve +%d" % int(clear_summary.get("clean_bonus", 1)))
		parts.append("Stage Refill +%d" % int(clear_summary.get("refill_moves", 3)))
		if int(clear_summary.get("boss_bonus", 0)) > 0:
			parts.append("Boss +%d" % int(clear_summary.get("boss_bonus", 5)))
		parts.append("+%d Coins" % int(clear_summary.get("earned_coins", 10)))
		summary_lbl.text = " · ".join(parts)

	_rebuild_card_buttons()
	visible = true
	# Dress after a frame has passed so the panel has its final size. This is
	# deferred with a timer, not an await: these run from a signal handler and
	# an await there would stall the caller.
	if panel != null:
		var dress := func() -> void: RingTheme.dress_modal(panel, self, true)
		get_tree().create_timer(0.05).timeout.connect(dress)
	RingTheme.present_modal(self, panel)
	_fly_coins(int(clear_summary.get("earned_coins", 0)), coin_origin, coin_target)
	if not current_cards.is_empty():
		AudioService.play_card_reveal(str(current_cards[0].get("rarity", "common")))


## The coins earned fly from where the reward was won to the real coin
## counter. Both ends are measured from the live UI, never guessed.
func _fly_coins(amount: int, origin: Vector2, target: Vector2) -> void:
	if amount <= 0 or target == Vector2.ZERO:
		return
	CoinFlyAnimationScript.play_fly_coins(self, origin, target, mini(amount, 10), AudioService, null,
		func(): pass,
		func(coin_idx: int, _total: int): AudioService.play_coin_chime(coin_idx)
	)


## One card per row: icon well, name, description, rarity chip, charge chip.
func _rebuild_card_buttons() -> void:
	for c in cards_vbox.get_children():
		c.queue_free()
	for i in range(current_cards.size()):
		var idx := i
		var c: Dictionary = current_cards[i]
		var rarity := str(c.get("rarity", "common"))
		var r_col := RingTheme.rarity_color(rarity)
		var is_active := str(c.get("type", "")) == "active"

		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", RingTheme.powerup_card(Color("#F7FBF4"), r_col))
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				select_card_at(idx)
		)
		cards_vbox.add_child(row)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		row.add_child(hb)

		# the tool icon in a recessed well - a fixed-size box so it cannot
		# stretch to the height of the row
		var well := PanelContainer.new()
		well.custom_minimum_size = Vector2(56, 56)
		well.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		well.add_theme_stylebox_override("panel", RingTheme.icon_well())
		hb.add_child(well)

		var icon := TextureRect.new()
		icon.texture = RingTheme.tex(str(c.get("icon", "")))
		icon.custom_minimum_size = Vector2(38, 38)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		well.add_child(icon)

		# name and description
		var text_col := VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text_col.size_flags_stretch_ratio = 1.0
		text_col.add_theme_constant_override("separation", 1)
		hb.add_child(text_col)

		var name_lbl := RingTheme.label(str(c.get("name", "")), 19, RingTheme.INK, HORIZONTAL_ALIGNMENT_LEFT)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_lbl.clip_text = true
		text_col.add_child(name_lbl)

		var desc_lbl := RingTheme.label(str(c.get("desc", "")), 13, RingTheme.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.custom_minimum_size = Vector2(0, 38)
		text_col.add_child(desc_lbl)

		# rarity chip and type chip, stacked on the right
		var chip_col := VBoxContainer.new()
		chip_col.alignment = BoxContainer.ALIGNMENT_CENTER
		chip_col.add_theme_constant_override("separation", 4)
		chip_col.custom_minimum_size = Vector2(92, 0)
		chip_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(chip_col)

		var badge := PanelContainer.new()
		badge.add_theme_stylebox_override("panel", RingTheme.chip(r_col.lightened(0.86), r_col))
		chip_col.add_child(badge)
		var badge_lbl := RingTheme.label(RingTheme.rarity_badge(rarity).split(" · ")[1], 11, r_col)
		badge_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		badge.add_child(badge_lbl)

		if is_active:
			var charge := PanelContainer.new()
			charge.add_theme_stylebox_override("panel", RingTheme.chip(RingTheme.GOLD.lightened(0.55), RingTheme.GOLD_DARK))
			chip_col.add_child(charge)
			var charge_lbl := RingTheme.label("+%d charges" % int(c.get("charges", 1)), 11, RingTheme.GOLD_DARK)
			charge_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			charge.add_child(charge_lbl)
		else:
			var passive := PanelContainer.new()
			passive.add_theme_stylebox_override("panel", RingTheme.chip(RingTheme.BAMBOO_TINT, RingTheme.BAMBOO_DARK))
			chip_col.add_child(passive)
			var passive_lbl := RingTheme.label("PERK", 11, RingTheme.BAMBOO_DARK)
			passive_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			passive.add_child(passive_lbl)


func select_card_at(index: int) -> void:
	if index < 0 or index >= current_cards.size():
		return
	var chosen := current_cards[index]
	PerkSystem.apply_card_choice(chosen)
	visible = false
	card_selected.emit(chosen)


func request_reroll_ad() -> void:
	if reroll_used_this_puzzle:
		return
	PlatformServices.show_rewarded_ad("perk_reroll", func():
		reroll_used_this_puzzle = true
		reroll_btn.disabled = true
		reroll_btn.text = "Reroll Used"
		current_cards = PerkSystem.draw_cards(RunController.rng, false, false)
		_rebuild_card_buttons()
	)
