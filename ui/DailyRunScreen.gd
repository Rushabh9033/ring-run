class_name DailyRunScreen
extends Control
## DailyRunScreen — Today's Daily Run seed, ranked vs practice status, the
## 7-day streak, and the button that starts it.
##
## Everything shown is real saved state: the date seed, whether a ranked
## attempt is still available, today's best depth and the streak.

signal start_daily_pressed()
signal back_pressed()

var info_lbl: Label
var mode_lbl: Label
var streak_row: HBoxContainer
var _page: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	refresh_view()


func _build() -> void:
	_page = RingTheme.zen_page("DAILY RUN", "icons/icon_daily.png", 180)
	add_child(_page["page"])

	var content: VBoxContainer = _page["content"]
	(_page["status"] as Label).text = "Same date seed for every player, so everyone gets the same puzzles and card draws."

	mode_lbl = RingTheme.label("", 15, RingTheme.BAMBOO_DARK)
	mode_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	content.add_child(mode_lbl)

	info_lbl = RingTheme.label("", 15, RingTheme.INK, HORIZONTAL_ALIGNMENT_LEFT)
	info_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	content.add_child(info_lbl)

	# The 7-day streak strip: one pip per day, filled up to the current streak.
	var streak_cap := RingTheme.label("STREAK", 12, RingTheme.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	streak_cap.autowrap_mode = TextServer.AUTOWRAP_OFF
	content.add_child(streak_cap)
	streak_row = HBoxContainer.new()
	streak_row.add_theme_constant_override("separation", 5)
	content.add_child(streak_row)

	var play_btn := RingTheme.zen_button("primary", "PLAY TODAY'S DAILY RUN", 17, 58)
	(play_btn.get_node("Hit") as Button).pressed.connect(func():
		visible = false
		start_daily_pressed.emit()
	)
	content.add_child(play_btn)

	var back_btn := RingTheme.zen_button("nav", "BACK TO HOME", 15, 46)
	(back_btn.get_node("Hit") as Button).pressed.connect(func():
		visible = false
		back_pressed.emit()
	)
	content.add_child(back_btn)


func refresh_view() -> void:
	if info_lbl == null:
		return
	var d_num := SaveService.get_daily_number()
	var date_s := SaveService.get_local_date_string()
	var ranked := SaveService.can_play_ranked_daily()
	var best := int(SaveService.data["daily_run"].get("today_best_depth", 0))
	var streak := int(SaveService.data["daily_run"].get("streak_days", 0))

	mode_lbl.text = "Daily #%d  ·  %s  ·  %s" % [d_num, date_s, "RANKED" if ranked else "PRACTICE"]
	info_lbl.text = "Attempt: %s   ·   Best depth: %d   ·   Streak: %d days" % [
		"RANKED" if ranked else "PRACTICE", best, streak
	]

	for c in streak_row.get_children():
		c.queue_free()
	for i in range(7):
		var pip := PanelContainer.new()
		pip.add_theme_stylebox_override("panel", RingTheme.card_style(
			RingTheme.GOLD if i < streak else RingTheme.CARD,
			RingTheme.GOLD_DARK, 2, 8, 2))
		pip.custom_minimum_size = Vector2(26, 12)
		streak_row.add_child(pip)
