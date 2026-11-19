class_name BossCurseBanner
extends Control
## BossCurseBanner — 1.0s alert banner before Boss or Cursed puzzles.

signal banner_finished()

var title_lbl: Label
var rule_lbl: Label

const CURSE_RULES := {
	"heavy_ring": "Heavy Ring: Marked ring costs 2 moves to rotate.",
	"tight_gaps": "Tight Gaps: All ring gaps are narrower.",
	"blind": "Blind: Panda Eye hint power is disabled.",
	"one_way": "One-Way: Marked ring rotates clockwise only.",
	"locked_ring": "Locked Ring: Unlocks only after neighbor ring releases."
}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_top = 300
	panel.offset_bottom = 390
	panel.offset_left = 20
	panel.offset_right = -20
	panel.add_theme_stylebox_override("panel", RingTheme.card_style(RingTheme.DANGER, RingTheme.EPIC_GOLD, 3, 16, 14))
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	title_lbl = RingTheme.label("BOSS PUZZLE", 22, Color.WHITE)
	rule_lbl = RingTheme.label("Clear for +5 Moves, 3x Coins & Rare/Epic Card!", 14, Color.WHITE)
	vbox.add_child(title_lbl)
	vbox.add_child(rule_lbl)

func show_banner(is_boss: bool, curses: Array) -> void:
	if is_boss:
		title_lbl.text = "BOSS PUZZLE!"
		rule_lbl.text = "Rewards: +5 Moves · 3x Coins · Rare/Epic Card"
		AudioService.play_boss_intro()
		PlatformServices.trigger_haptic("boss_intro")
	elif not curses.is_empty():
		var c_id := str(curses[0])
		title_lbl.text = "CURSE ACTIVE"
		rule_lbl.text = str(CURSE_RULES.get(c_id, c_id))
		AudioService.play_curse_applied()
	visible = true
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_callback(func():
		visible = false
		banner_finished.emit()
	)
