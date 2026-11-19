class_name StageIntroBanner
extends Control
## StageIntroBanner — 1.5s full-width banner announcing a new Stage & mechanic.

signal banner_finished()

var title_lbl: Label
var sub_lbl: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_top = 330
	panel.offset_bottom = 420
	panel.offset_left = 20
	panel.offset_right = -20
	panel.add_theme_stylebox_override("panel", RingTheme.card_style(RingTheme.INK, RingTheme.EPIC_GOLD, 3, 16, 14))
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	title_lbl = RingTheme.label("STAGE 1 · GARDEN", 22, Color.WHITE)
	sub_lbl = RingTheme.label("Align ring gaps with the exit gate", 14, RingTheme.EPIC_GOLD)
	vbox.add_child(title_lbl)
	vbox.add_child(sub_lbl)

func show_stage_intro(stage_num: int, stage_name: String, mechanic_hint: String) -> void:
	if title_lbl != null:
		title_lbl.text = "STAGE %d · %s" % [stage_num, stage_name.to_upper()]
	if sub_lbl != null:
		sub_lbl.text = mechanic_hint
	visible = true
	var tw := create_tween()
	tw.tween_interval(1.3)
	tw.tween_callback(func():
		visible = false
		banner_finished.emit()
	)
