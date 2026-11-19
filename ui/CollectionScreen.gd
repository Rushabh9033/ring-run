class_name CollectionScreen
extends Control
## CollectionScreen — the player's unlocked powers and perks.
##
## A gold parchment card over the bamboo garden, with every tool on a bamboo
## row that shows its real icon, its name, its rarity and whether it is
## unlocked.

signal back_pressed()

var grid_box: GridContainer
var detail_lbl: Label
var _page: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_refresh()


func _build() -> void:
	_page = RingTheme.zen_page("COLLECTION", "icons/icon_collection.png", 400)
	add_child(_page["page"])

	var content: VBoxContainer = _page["content"]
	detail_lbl = _page["status"]
	detail_lbl.text = "Tap a card to see its effect."

	var scroll: ScrollContainer = _page["scroll"]
	grid_box = GridContainer.new()
	grid_box.columns = 2
	grid_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_box.add_theme_constant_override("h_separation", 10)
	grid_box.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid_box)

	var back := RingTheme.zen_button("primary", "BACK TO HOME", 15, 48)
	(back.get_node("Hit") as Button).pressed.connect(func():
		visible = false
		back_pressed.emit())
	content.add_child(back)


func _refresh() -> void:
	for c in grid_box.get_children():
		c.queue_free()

	var unlocked_powers: Array = SaveService.data.get("unlocked_powers", [])
	var unlocked_perks: Array = SaveService.data.get("unlocked_perks", [])

	for id in PerkSystem.TOOLS_CATALOG.keys():
		var meta: Dictionary = PerkSystem.TOOLS_CATALOG[id]
		var unlocked: bool = unlocked_powers.has(id) or unlocked_perks.has(id)
		grid_box.add_child(_tool_card(str(id), meta, unlocked))

	detail_lbl.text = "%d of %d tools unlocked — tap one to read its effect." % [_unlocked_count(), PerkSystem.TOOLS_CATALOG.size()]


func _unlocked_count() -> int:
	var n := 0
	var unlocked_powers: Array = SaveService.data.get("unlocked_powers", [])
	var unlocked_perks: Array = SaveService.data.get("unlocked_perks", [])
	for id in PerkSystem.TOOLS_CATALOG.keys():
		if unlocked_powers.has(id) or unlocked_perks.has(id):
			n += 1
	return n


## One tool on a bamboo card.
func _tool_card(id: String, meta: Dictionary, unlocked: bool) -> Control:
	var rarity := str(meta.get("rarity", "common"))
	var r_col := RingTheme.rarity_color(rarity)

	# A stylebox, not a nine-patch of the button skin: the skin's corner
	# patches were 42px in a 62px card, so the corners rendered as white
	# blobs and the rarity line was cut off.
	var card := Control.new()
	card.custom_minimum_size = Vector2(0, 62)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var skin := Panel.new()
	skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skin.add_theme_stylebox_override("panel", RingTheme.collection_card_style(unlocked))
	card.add_child(skin)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_right = -10
	row.offset_top = 6
	row.offset_bottom = -6
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)

	var icon := TextureRect.new()
	icon.texture = RingTheme.pack_tex(str(meta.get("icon", "")))
	icon.custom_minimum_size = Vector2(30, 30)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unlocked:
		icon.modulate = Color(1, 1, 1, 0.35)
	row.add_child(icon)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 1)
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_col)

	var name_lbl := RingTheme.label(str(meta.get("name", id)), 14, RingTheme.INK, HORIZONTAL_ALIGNMENT_LEFT)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_lbl.clip_text = true
	name_lbl.custom_minimum_size = Vector2(0, 18)
	text_col.add_child(name_lbl)

	var tag := "POWER" if str(meta.get("type", "")) == "active" else "PERK"
	if not unlocked:
		tag = "LOCKED"
	var tag_lbl := RingTheme.label("%s · %s" % [tag, rarity.to_upper()], 11, r_col if unlocked else RingTheme.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	tag_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	tag_lbl.clip_text = true
	tag_lbl.custom_minimum_size = Vector2(0, 15)
	text_col.add_child(tag_lbl)

	card.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			detail_lbl.text = "%s — %s" % [str(meta.get("name", id)), str(meta.get("desc", ""))])

	return card
