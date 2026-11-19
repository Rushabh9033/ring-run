class_name SettingsPauseModal
extends Control
## SettingsPauseModal — Sound, Haptics, the working Reduced Motion toggle,
## Resume Run, and Quit to Home.
##
## The three toggles write straight to the save file, so a change is immediate
## and survives a restart.

signal resume_pressed()
signal quit_to_home_pressed()

var sound_btn: Control
var haptics_btn: Control
var motion_btn: Control
var _page: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_refresh_labels()


func _build() -> void:
	_page = RingTheme.zen_page("SETTINGS", "icons/icon_settings.png", 210)
	add_child(_page["page"])

	var list: VBoxContainer = _page["list"]
	(_page["status"] as Label).text = "Tap a row to toggle it."

	sound_btn = _toggle("Musical Rings Sound", func():
		var cur := bool(SaveService.data["settings"].get("sound_enabled", true))
		SaveService.data["settings"]["sound_enabled"] = not cur
		SaveService.save_game())
	list.add_child(sound_btn)

	haptics_btn = _toggle("Haptics", func():
		var cur := bool(SaveService.data["settings"].get("haptics_enabled", true))
		SaveService.data["settings"]["haptics_enabled"] = not cur
		SaveService.save_game())
	list.add_child(haptics_btn)

	motion_btn = _toggle("Reduced Motion", func():
		var cur := bool(SaveService.data["settings"].get("reduced_motion", false))
		SaveService.data["settings"]["reduced_motion"] = not cur
		SaveService.save_game())
	list.add_child(motion_btn)

	var content: VBoxContainer = _page["content"]

	var resume_btn := RingTheme.zen_button("primary", "RESUME RUN", 16, 52)
	(resume_btn.get_node("Hit") as Button).pressed.connect(func():
		visible = false
		resume_pressed.emit()
	)
	content.add_child(resume_btn)

	var home_btn := RingTheme.zen_button("nav", "HOME SCREEN", 15, 46)
	(home_btn.get_node("Hit") as Button).pressed.connect(func():
		visible = false
		quit_to_home_pressed.emit()
	)
	content.add_child(home_btn)


## A labelled on/off row.
func _toggle(label_text: String, on_toggle: Callable) -> Control:
	var btn := RingTheme.zen_button("nav", "", 15, 46)
	(btn.get_node("Hit") as Button).pressed.connect(func():
		on_toggle.call()
		_refresh_labels())
	btn.set_meta("label", label_text)
	return btn


func _refresh_labels() -> void:
	var s_on := bool(SaveService.data["settings"].get("sound_enabled", true))
	var h_on := bool(SaveService.data["settings"].get("haptics_enabled", true))
	var m_on := bool(SaveService.data["settings"].get("reduced_motion", false))
	_set_toggle(sound_btn, "Musical Rings Sound", s_on)
	_set_toggle(haptics_btn, "Haptics", h_on)
	_set_toggle(motion_btn, "Reduced Motion", m_on)


func _set_toggle(btn: Control, label_text: String, on: bool) -> void:
	if btn == null:
		return
	var cap := btn.get_node_or_null("Caption") as Label
	if cap == null:
		return
	cap.text = "%s: %s" % [label_text, "ON" if on else "OFF"]
	cap.add_theme_color_override("font_color", RingTheme.BAMBOO_DARK if on else RingTheme.MUTED)
