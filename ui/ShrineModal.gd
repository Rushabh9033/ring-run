class_name ShrineModal
extends Control
## ShrineModal — Post-Boss risk-reward decision: Spend 5 Moves for a Rare Card or Skip.

signal shrine_completed(claimed_cards: Array[Dictionary])

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	RingTheme.bamboo_background(self, 0.55)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.16, 0.12, 0.82)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var center_margin := MarginContainer.new()
	center_margin.add_theme_constant_override("margin_left", 24)
	center_margin.add_theme_constant_override("margin_right", 24)
	center_margin.add_theme_constant_override("margin_top", 40)
	center_margin.add_theme_constant_override("margin_bottom", 40)
	center.add_child(center_margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", RingTheme.wood_card())
	center_margin.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	vbox.add_child(RingTheme.label("ANCIENT BAMBOO SHRINE", 24, RingTheme.RARE_BLUE))
	vbox.add_child(RingTheme.label("You defeated the Stage Boss!\nSacrifice 5 Move Budget to draw a guaranteed Rare tool card?", 15, RingTheme.INK))

	var accept_btn := RingTheme.button("Spend 5 Moves -> Get Rare Card", "blue", Vector2(0, 56), 16)
	accept_btn.pressed.connect(choose_spend_moves)
	vbox.add_child(accept_btn)

	var skip_btn := RingTheme.button("Skip (Save Move Budget)", "secondary", Vector2(0, 50), 15)
	skip_btn.pressed.connect(choose_skip)
	vbox.add_child(skip_btn)

## Pop the shrine in when it appears.
func show_shrine() -> void:
	visible = true
	RingTheme.present_modal(self)


func choose_spend_moves() -> void:
	var cards := RunController.spend_shrine_for_rare_card()
	visible = false
	shrine_completed.emit(cards)

func choose_skip() -> void:
	visible = false
	shrine_completed.emit([])
