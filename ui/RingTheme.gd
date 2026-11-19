class_name RingTheme
extends RefCounted

## RingTheme — the visual language of Ring Run.
##
## Everything here is built from the Rotate Rings look: cream and bamboo
## surfaces, warm ink, tactile chunky buttons, a bamboo banner header and the
## bamboo booster cards along the bottom of the board.

const UiTheme = preload("res://app/ui_theme.gd")

## The Zen Bamboo asset pack.
const PACK := "res://assets/ui/ring_run_zen"

# --- palette (Rotate Rings) ----------------------------------------------
const CREAM := Color("F4E7D4")
const SURFACE := Color("FFF8F0")
const CARD := Color("FFFDF7")
const INK := Color("4A3428")
const MUTED := Color("8A6554")
const BAMBOO := Color("3EC6B0")
const BAMBOO_DARK := Color("1C8F7C")
const BAMBOO_TINT := Color("E8F5E9")
const GOLD := Color("F0B429")
const GOLD_DARK := Color("C48412")
const DANGER := Color("E25B6A")
const RARE_BLUE := Color("1976D2")
const EPIC_GOLD := Color("FFB300")

# --- art ------------------------------------------------------------------
const BG_ZEN := "res://assets/ui/bamboo_zen/background/zen_garden_clean.png"
const BG_BAMBOO := "res://art/gameplay/gameplay_bamboo_bg_clean.png"
const HEADER_BANNER := "res://assets/ui/bamboo_zen/header/bamboo_header_banner_clean.png"
const LEVEL_BADGE := "res://art/gameplay/hud_level_badge_bamboo.png"
const MOVES_PILL := "res://art/gameplay/hud_score_pill_clean.png"
const COIN_PILL := "res://art/gameplay/hud_coin_pill_clean.png"
const COIN_ICON := "res://assets/ui/bamboo_zen/hud/coin_icon.png"
const PAUSE_ICON := "res://assets/ui/bamboo_zen/hud/settings_icon.png"
const POWER_FRAME := "res://art/gameplay/booster_card_frame_clean.png"
const LOCK_ICON := "res://assets/ui/bamboo_zen/boosters/lock_icon.png"
const HERO_LOGO := "res://art/home/hero_logo_letters_fg.png"


## A rounded cream card with a coloured border.
static func card_style(bg: Color = CARD, border: Color = BAMBOO_DARK, border_w: int = 3, radius: int = 22, pad: int = 18) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	return sb


static func tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null


static func rarity_color(rarity: String) -> Color:
	match rarity:
		"rare": return RARE_BLUE
		"epic": return EPIC_GOLD
		_: return BAMBOO_DARK


static func rarity_badge(rarity: String) -> String:
	match rarity:
		"rare": return "DIAMOND · RARE"
		"epic": return "HEXAGON · EPIC"
		_: return "CIRCLE · COMMON"


# ---------------------------------------------------------------- surfaces

## The bamboo zen garden behind everything, with a warm scrim so the art
## stays visible but the text stays readable.
static func bamboo_background(host: Control, scrim_alpha: float = 0.42) -> void:
	var bg := TextureRect.new()
	bg.name = "BambooBg"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = tex(BG_ZEN)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	host.add_child(bg)
	if scrim_alpha > 0.0:
		var scrim := ColorRect.new()
		scrim.name = "Scrim"
		scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scrim.color = Color(0.961, 0.929, 0.882, scrim_alpha)
		host.add_child(scrim)


## Present a modal.
##
## Only the CARD animates: it scales up from slightly small with a soft
## overshoot. The full-screen scrim fades on its own, so the celebration
## behind the modal is not hidden by a panel that is also fading.
static func present_modal(modal: Control, card: Control = null) -> void:
	if modal == null or not is_instance_valid(modal):
		return

	# The scrim fades in by itself.
	var scrim := modal.get_node_or_null("Dimmer") as Control
	if scrim == null:
		scrim = modal.get_node_or_null("Scrim") as Control
	if scrim != null:
		scrim.modulate.a = 0.0
		var sw := scrim.create_tween()
		sw.tween_property(scrim, "modulate:a", 1.0, 0.16)

	# The card pops.
	var target: Control = card if card != null and is_instance_valid(card) else modal
	if target == null:
		return
	target.pivot_offset = target.size * 0.5
	target.scale = Vector2(0.88, 0.88)
	var tw := target.create_tween().set_parallel(true)
	tw.tween_property(target, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(target, "modulate:a", 1.0, 0.18)


## Slide a screen in from the right. Used when the game hands over to the
## board, so the change of scene reads as a movement rather than a cut.
## Slide a screen in from the side.
##
## The slide is done on the offsets, not on `position`. A full-rect anchored
## Control derives its position from its anchors, so writing `position.x`
## fights the anchor system: the screen ends up narrower than the screen and
## stays shifted if the tween is interrupted.
static func slide_in(control: Control, from_right: bool = true, distance: float = 90.0) -> void:
	if control == null or not is_instance_valid(control):
		return
	var dir := 1.0 if from_right else -1.0
	control.modulate.a = 0.0
	var base_left := control.offset_left
	var base_right := control.offset_right
	control.offset_left = base_left + dir * distance
	control.offset_right = base_right + dir * distance
	var tw := control.create_tween().set_parallel(true)
	tw.tween_property(control, "modulate:a", 1.0, 0.22)
	tw.tween_property(control, "offset_left", base_left, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(control, "offset_right", base_right, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## The dimmer behind a modal fades in rather than snapping.
static func fade_in(node: CanvasItem, duration: float = 0.18) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is CanvasItem:
		var ci := node as CanvasItem
		ci.modulate.a = 0.0
		var tw := ci.create_tween()
		tw.tween_property(ci, "modulate:a", 1.0, duration)


## The big parchment modal card: thick bamboo-wood border, 3D bottom lip,
## soft drop shadow. This is the Rotate Rings modal look.
static func wood_card() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#FFFDF7")
	box.border_color = Color("#3B5323")
	box.set_border_width_all(5)
	box.border_width_bottom = 9
	box.set_corner_radius_all(28)
	box.shadow_color = Color(0.06, 0.12, 0.04, 0.38)
	box.shadow_size = 22
	box.shadow_offset = Vector2(0, 10)
	box.content_margin_left = 24.0
	box.content_margin_right = 24.0
	box.content_margin_top = 22.0
	box.content_margin_bottom = 22.0
	return box


## The recessed bamboo card the power-up icons sit in.
static func powerup_card(bg: Color = Color("#F4FBF2"), border: Color = Color("#A3C182")) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(3)
	box.border_width_bottom = 6
	box.set_corner_radius_all(24)
	box.shadow_color = Color(0.18, 0.28, 0.14, 0.18)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 4)
	return box


## A small square chip: rarity badge, charge count, stage tag.
static func chip(bg: Color, border: Color, radius: int = 12) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 8.0
	box.content_margin_right = 8.0
	box.content_margin_top = 3.0
	box.content_margin_bottom = 3.0
	return box


## A round well for a tool icon.
static func icon_well(bg: Color = Color("#F4FBF2"), border: Color = Color("#A3C182")) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(40)
	box.shadow_color = Color(0.18, 0.28, 0.14, 0.16)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 3)
	return box


## Dress a modal panel the way Rotate Rings does: a bamboo vine draped over
## the top edge and the celebrating panda peeking over it.
##
## The panda is added to the panel's PARENT, not to the panel - a child of a
## PanelContainer is laid out by the container and would sit on top of the
## content instead of behind it.
static func dress_modal(panel: PanelContainer, host: Node = null, with_panda: bool = true) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	var w: float = maxf(panel.size.x, 420.0)
	# The host must be a plain Control. A Container would re-lay-out its
	# children and override the positions set here.
	if host == null or not is_instance_valid(host):
		host = panel.get_parent()

	if ResourceLoader.exists("res://art/bamboo_vine.png") and not host.has_node("BambooVine"):
		var vine := TextureRect.new()
		vine.name = "BambooVine"
		vine.texture = tex("res://art/bamboo_vine.png")
		vine.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		vine.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vine.size = Vector2(w - 60.0, 52.0)
		vine.position = panel.global_position + Vector2(30.0, -22.0)
		vine.z_index = 1
		vine.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(vine)
	if with_panda and ResourceLoader.exists("res://art/panda_mascot_celebrating.png") and not host.has_node("PandaVictory"):
		var panda := TextureRect.new()
		panda.name = "PandaVictory"
		panda.texture = tex("res://art/panda_mascot_celebrating.png")
		panda.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		panda.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		panda.size = Vector2(96, 96)
		# On the card's top-right corner, so it never sits over the title.
		panda.position = panel.global_position + Vector2(w - 74.0, -58.0)
		panda.z_index = 2
		panda.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(panda)


## Load an asset out of the Zen Bamboo pack.
static func pack_tex(path: String) -> Texture2D:
	if path == "":
		return null
	# A path that already points somewhere is used as-is: the perk catalogue
	# still refers to the SVG icons in assets/icons.
	if path.begins_with("res://"):
		if ResourceLoader.exists(path):
			return load(path)
		return null
	var full := "%s/%s" % [PACK, path]
	if ResourceLoader.exists(full):
		return load(full)
	push_warning("Ring Run asset missing: %s" % full)
	return null


## A full page: bamboo background, a centred gold card that hugs its
## content, a title with its icon, and a scroll area for the body.
##
## The card must NOT fill the screen height - a short page inside a full
## height card reads as a huge empty slab. Returns a dictionary with
## "panel", "title", "status", "scroll" and "list".
static func zen_page(title: String, icon_path: String, scroll_height: float = 380.0) -> Dictionary:
	var page := Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	bamboo_background(page, 0.42)

	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(holder)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	holder.add_child(margin)

	# The card fills the space between the margins. The title sits at the top,
	# the scroll area takes the middle and the action buttons sit at the
	# bottom - so the card never reads as one big empty slab.
	var panel := gold_panel()
	# Without a minimum width the card collapses to the width of its narrowest
	# child, which turns the whole page into a column. Nothing may expand
	# vertically either, so the card ends up exactly as tall as its content.
	# The card is as wide as the screen allows, with a comfortable minimum.
	# A fixed 420px was wider than a small phone. The page is not in the tree
	# yet when this runs, so fall back to the design width.
	var side_pad := 16.0
	var screen_w: float = 720.0
	if page.is_inside_tree():
		screen_w = page.get_viewport_rect().size.x
	var avail: float = screen_w - 2.0 * side_pad
	panel.custom_minimum_size = Vector2(minf(avail, 460.0), 0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margin.add_child(panel)

	var content := panel.get_node("Pad/Content") as VBoxContainer

	# The title row: the real icon, then the name.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	content.add_child(head)
	var icon := TextureRect.new()
	icon.texture = pack_tex(icon_path)
	icon.custom_minimum_size = Vector2(26, 26)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(icon)
	var title_lbl := label(title, 22, INK, HORIZONTAL_ALIGNMENT_LEFT)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(title_lbl)

	var status := label("", 13, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	content.add_child(status)

	# The body scrolls, so a long list never pushes the card off screen. It has
	# a fixed height: the card is exactly as tall as title + body + buttons.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, scroll_height)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	return {
		"page": page,
		"panel": panel,
		"title": title_lbl,
		"status": status,
		"scroll": scroll,
		"list": list,
		"content": content,
	}


## A gold-rimmed parchment panel. Returns the Control; the content goes into
## the VBox it already contains, which is named "Content".
static func gold_panel(radius: int = 24) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.mouse_filter = Control.MOUSE_FILTER_PASS

	# A NinePatchRect, so a tall panel keeps its gold corners and only the
	# middle stretches. A stretched TextureRect distorts the rim.
	# A stylebox, not a nine-patch: the card's own margin was 64px, so a
	# panel shorter than 128px had no stretchable middle and the rim was
	# squashed. A stylebox is correct at any height.
	var skin := Panel.new()
	skin.name = "Skin"
	skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skin.add_theme_stylebox_override("panel", gold_card_style())
	panel.add_child(skin)

	# Inner padding, so the content never sits under the gold rim.
	var pad := MarginContainer.new()
	pad.name = "Pad"
	pad.add_theme_constant_override("margin_left", 22)
	pad.add_theme_constant_override("margin_right", 22)
	pad.add_theme_constant_override("margin_top", 18)
	pad.add_theme_constant_override("margin_bottom", 18)
	pad.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_child(pad)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The content hugs its children: the card grows to fit them and the scroll
	# area is what takes the leftover space.
	content.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pad.add_child(content)

	return panel


## The colours a button slab is built from.
##
## kind: "primary" | "nav" | "gold" | "blue" | "danger" | "daily"
const SLAB_COLORS := {
	"primary": {"fill": Color("7EDC5A"), "press": Color("4FBE3C"), "edge": Color("1E601C"), "ink": Color.WHITE},
	"nav": {"fill": Color("FFFAE2"), "press": Color("EBD9AE"), "edge": Color("C89A3C"), "ink": Color("4A3428")},
	"daily": {"fill": Color("FFFAE2"), "press": Color("EBD9AE"), "edge": Color("C89A3C"), "ink": Color("4A3428")},
	"gold": {"fill": Color("F0B429"), "press": Color("D69A18"), "edge": Color("9A6B0C"), "ink": Color("4A3208")},
	"blue": {"fill": Color("4E8BD4"), "press": Color("2E64A4"), "edge": Color("1E4C80"), "ink": Color.WHITE},
	"danger": {"fill": Color("D9525F"), "press": Color("BC3F4C"), "edge": Color("8C2733"), "ink": Color.WHITE},
}


## A chunky button, drawn with styleboxes.
##
## The button skins used to be nine-patches, but a nine-patch cannot scale a
## pill's rounded caps: the cap pixels never shrink, so a 56px button built
## from a 112px texture with 40px margins had 80px of vertical patch in a
## 56px box - it was squashed, and the gloss smeared into a stripe.
##
## A StyleBoxFlat draws the rounded rect at whatever size it is given, so the
## button is correct at every height. The look is the same: a warm fill, a
## dark edge and a fat bottom lip that reads as an extruded slab.
##
## Returns the Control; add labels and icons to it as children.
static func zen_button(kind: String = "nav", text: String = "", font_size: int = 16, height: float = 56.0) -> Control:
	var spec: Dictionary = SLAB_COLORS.get(kind, SLAB_COLORS["nav"])
	var fill: Color = spec["fill"]
	var press: Color = spec["press"]
	var edge: Color = spec["edge"]
	var ink: Color = spec["ink"]

	var root := Control.new()
	root.custom_minimum_size = Vector2(0, height)
	root.mouse_filter = Control.MOUSE_FILTER_PASS

	var body := Panel.new()
	body.name = "Body"
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_stylebox_override("panel", slab_style(fill, edge, height))
	root.add_child(body)

	var hit := Button.new()
	hit.name = "Hit"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.button_down.connect(func():
		body.add_theme_stylebox_override("panel", slab_style(press, edge, height))
		# The press scale is on the root, so the slab and the text move together.
		root.pivot_offset = root.size * 0.5
		var tw := root.create_tween()
		tw.tween_property(root, "scale", Vector2(0.97, 0.97), 0.07))
	hit.button_up.connect(func():
		body.add_theme_stylebox_override("panel", slab_style(fill, edge, height))
		root.pivot_offset = root.size * 0.5
		var tw := root.create_tween()
		tw.tween_property(root, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	root.add_child(hit)

	# The caption is always created, even with no text: a toggle sets its
	# label after the button is built, and a button with no caption node
	# would show as an empty slab.
	var lbl := label(text, font_size, ink)
	lbl.name = "Caption"
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lbl)

	return root


## The stylebox for a button slab: a rounded pill with a dark edge, a fat
## bottom lip and a soft shadow.
## A card in the collection list. A locked one is dimmed.
static func collection_card_style(unlocked: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("FFFAE2") if unlocked else Color("EDE7D6")
	sb.border_color = Color("C89A3C") if unlocked else Color("A79A80")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0.12, 0.24, 0.10, 0.16)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 2)
	return sb


## The small parchment card the stat readouts sit on.
static func stat_card_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("FFFAE2")
	sb.border_color = Color("C89A3C")
	sb.set_border_width_all(2)
	sb.border_width_bottom = 4
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(0.12, 0.24, 0.10, 0.20)
	sb.shadow_size = 7
	sb.shadow_offset = Vector2(0, 3)
	return sb


## The parchment card with the bamboo-wood border, used by every modal.
static func gold_card_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("FFFDF7")
	sb.border_color = Color("3B5323")
	sb.set_border_width_all(4)
	sb.border_width_bottom = 7
	sb.set_corner_radius_all(24)
	sb.shadow_color = Color(0.06, 0.12, 0.04, 0.34)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 8)
	return sb


## The parchment card with the bamboo-wood border, used by every modal.
static func slab_style(fill: Color, edge: Color, height: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(2)
	# The lip is what makes it look extruded, so it scales with the button.
	sb.border_width_bottom = maxi(4, int(height * 0.14))
	sb.set_corner_radius_all(int(height * 0.5))
	sb.shadow_color = Color(0.12, 0.24, 0.10, 0.26)
	sb.shadow_size = maxi(6, int(height * 0.16))
	sb.shadow_offset = Vector2(0, height * 0.07)
	return sb

static func zen_icon(root: Control, path: String, size: float = 30.0) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = pack_tex(path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(size, size)
	root.add_child(icon)
	return icon


static func card_panel(border: Color = BAMBOO_DARK, radius: int = 22, pad: int = 18) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", card_style(CARD, border, 3, radius, pad))
	return p


static func dimmer(alpha: float = 0.72) -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	r.color = Color(0.06, 0.10, 0.07, alpha)
	return r


# ----------------------------------------------------------------- labels

static func label(text: String, size: int = 16, color: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", UiTheme.rounded_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func title(text: String, size: int = 30) -> Label:
	return label(text, size, BAMBOO_DARK)


static func muted(text: String, size: int = 14) -> Label:
	return label(text, size, MUTED)


# ---------------------------------------------------------------- buttons

## kind: "primary" | "gold" | "secondary" | "danger" | "blue"
##
## Every button is chunky: a rounded pill with a fat bottom lip that reads as
## an extruded slab, and white text with a dark outline so it stays legible on
## the cream card.
static func button(text: String, kind: String = "primary", min_size: Vector2 = Vector2(0, 56), font_size: int = 18) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", UiTheme.rounded_font())
	b.add_theme_font_size_override("font_size", font_size)

	match kind:
		"primary":
			_paint_slab(b, Color("5BB048"), Color("28541D"), Color("68C454"), Color("489638"), font_size, 32)
		"gold":
			_paint_slab(b, Color("F0B429"), Color("A9760C"), Color("F7C64E"), Color("D69A18"), font_size, 22, Color("4A3208"))
		"blue":
			_paint_slab(b, Color("3E7BC4"), Color("1E4C80"), Color("4E8BD4"), Color("2E64A4"), font_size, 26)
		"danger":
			_paint_slab(b, Color("D9525F"), Color("8C2733"), Color("E56874"), Color("BC3F4C"), font_size, 24)
		_:
			_paint_slab(b, Color("F6FAF4"), Color("7FA46B"), Color("FFFFFF"), Color("E4EEDC"), font_size, 22, RingTheme.INK)
	return b


## A chunky extruded slab: fat bottom lip, hover lift, pressed squash.
static func _paint_slab(btn: Button, fill: Color, edge: Color, hover_fill: Color, pressed_fill: Color, font_size: int, radius: int = 26, text_col: Color = Color.WHITE) -> void:
	btn.flat = false
	var normal := StyleBoxFlat.new()
	normal.bg_color = fill
	normal.border_color = edge
	normal.set_border_width_all(2)
	normal.border_width_bottom = 7
	normal.set_corner_radius_all(radius)
	normal.shadow_color = Color(0.12, 0.24, 0.10, 0.26)
	normal.shadow_size = 9
	normal.shadow_offset = Vector2(0, 5)
	normal.content_margin_left = 26.0
	normal.content_margin_right = 26.0
	normal.content_margin_top = 10.0
	normal.content_margin_bottom = 17.0

	var hover := normal.duplicate()
	hover.bg_color = hover_fill
	hover.border_color = edge.darkened(0.1)

	var pressed := normal.duplicate()
	pressed.bg_color = pressed_fill
	pressed.border_width_bottom = 2
	pressed.content_margin_top = 15.0
	pressed.content_margin_bottom = 12.0
	pressed.shadow_size = 3
	pressed.shadow_offset = Vector2(0, 1)

	var disabled := normal.duplicate()
	disabled.bg_color = fill.lightened(0.4) if fill.r > 0.5 else fill.darkened(0.2)
	disabled.border_color = edge.lightened(0.35)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("disabled", disabled)

	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", text_col)
	btn.add_theme_color_override("font_pressed_color", text_col)
	btn.add_theme_color_override("font_focus_color", text_col)
	btn.add_theme_color_override("font_disabled_color", text_col.lightened(0.35))
	btn.add_theme_constant_override("outline_size", 4)
	btn.add_theme_color_override("font_outline_color", edge.darkened(0.35))
	btn.add_theme_constant_override("shadow_offset_y", 2)
	btn.add_theme_color_override("font_shadow_color", Color(0.06, 0.12, 0.04, 0.55))
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER


static func icon_button(icon_path: String, min_size: Vector2 = Vector2(52, 52)) -> Button:
	var b := Button.new()
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.flat = true
	var t := tex(icon_path)
	if t != null:
		b.icon = t
		b.expand_icon = true
	return b


# ----------------------------------------------------------------- header

## The bamboo banner header: stage badge on the left, the move budget in the
## middle, coins and pause on the right.
## Returns {"root": Control, "stage": Label, "budget": Label, "coins": Label}
static func build_header(stage_text: String, budget_text: int, coins: int) -> Dictionary:
	var root := Control.new()
	root.custom_minimum_size = Vector2(0, 116)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var banner := TextureRect.new()
	banner.name = "BambooBanner"
	banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.texture = tex(HEADER_BANNER)
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(banner)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_right = -12
	row.offset_top = 22
	row.offset_bottom = -14
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(row)

	# --- left: the stage badge ---
	var left := Control.new()
	left.custom_minimum_size = Vector2(168, 72)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(left)

	var badge_card := PanelContainer.new()
	badge_card.name = "StageBadge"
	badge_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge_card.add_theme_stylebox_override("panel", card_style(SURFACE, BAMBOO_DARK, 3, 16, 8))
	badge_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(badge_card)

	var badge_vbox := VBoxContainer.new()
	badge_vbox.add_theme_constant_override("separation", 0)
	badge_card.add_child(badge_vbox)

	var stage_cap := label("STAGE", 11, MUTED)
	badge_vbox.add_child(stage_cap)

	var stage_lbl := label(stage_text, 17, BAMBOO_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	stage_lbl.name = "StageLabel"
	badge_vbox.add_child(stage_lbl)

	# --- centre: the move budget pill ---
	var centre_slot := HBoxContainer.new()
	centre_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre_slot.alignment = BoxContainer.ALIGNMENT_CENTER
	centre_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(centre_slot)

	var budget_pill := Control.new()
	budget_pill.name = "BudgetPill"
	budget_pill.custom_minimum_size = Vector2(150, 76)
	budget_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre_slot.add_child(budget_pill)

	var pill_tex := TextureRect.new()
	pill_tex.name = "Pill"
	pill_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pill_tex.texture = tex(MOVES_PILL)
	pill_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pill_tex.stretch_mode = TextureRect.STRETCH_SCALE
	pill_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	budget_pill.add_child(pill_tex)

	var budget_lbl := label(str(budget_text), 38, BAMBOO_DARK)
	budget_lbl.name = "BudgetLabel"
	budget_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	budget_lbl.offset_top = 2
	budget_lbl.offset_bottom = -16
	budget_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	budget_pill.add_child(budget_lbl)

	var moves_cap := label("MOVES", 12, MUTED)
	moves_cap.name = "MovesCaption"
	moves_cap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	moves_cap.offset_top = -18
	moves_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	budget_pill.add_child(moves_cap)

	# --- right: coins and pause ---
	var right := HBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(right)

	var coin_box := Control.new()
	coin_box.name = "CoinBox"
	coin_box.custom_minimum_size = Vector2(112, 52)
	coin_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(coin_box)

	var coin_pill := TextureRect.new()
	coin_pill.name = "CoinPill"
	coin_pill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coin_pill.texture = tex(COIN_PILL)
	coin_pill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_pill.stretch_mode = TextureRect.STRETCH_SCALE
	coin_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_box.add_child(coin_pill)

	var coin_icon := TextureRect.new()
	coin_icon.name = "CoinIcon"
	coin_icon.texture = tex(COIN_ICON)
	coin_icon.position = Vector2(8, 10)
	coin_icon.size = Vector2(32, 32)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_box.add_child(coin_icon)

	var coin_lbl := label(str(coins), 18, INK, HORIZONTAL_ALIGNMENT_LEFT)
	coin_lbl.name = "CoinLabel"
	coin_lbl.position = Vector2(40, 12)
	coin_lbl.size = Vector2(66, 30)
	coin_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_box.add_child(coin_lbl)

	return {
		"root": root,
		"stage": stage_lbl,
		"budget": budget_lbl,
		"budget_pill": budget_pill,
		"coins": coin_lbl,
	}


# ------------------------------------------------------------ power cards

## One bamboo booster card: frame, tool icon, charge badge.
static func power_card(icon_path: String, title: String, charges: int, enabled: bool = true) -> Control:
	## One active power: the tool icon in a recessed well, a charge badge and
	## the name. An empty slot shows a padlock instead.
	##
	## The card is drawn with styleboxes, not a nine-patch: a square texture
	## stretched into a wide slot distorts both the card and the round well.
	var card := Control.new()
	card.custom_minimum_size = Vector2(150, 74)

	var body := Panel.new()
	body.name = "Body"
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body_style := StyleBoxFlat.new()
	body_style.bg_color = SURFACE if enabled else Color(0.93, 0.92, 0.88)
	body_style.border_color = GOLD_DARK if enabled else Color(0.72, 0.70, 0.64)
	body_style.set_border_width_all(2)
	body_style.border_width_bottom = 4
	body_style.set_corner_radius_all(14)
	body.add_theme_stylebox_override("panel", body_style)
	card.add_child(body)

	# The recessed well: a circle, drawn as one.
	var well := Panel.new()
	well.name = "Well"
	well.position = Vector2(12, 12)
	well.size = Vector2(42, 42)
	well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var well_style := StyleBoxFlat.new()
	well_style.bg_color = Color(0.93, 0.96, 0.91)
	well_style.border_color = Color(0.78, 0.84, 0.75)
	well_style.set_border_width_all(2)
	well_style.set_corner_radius_all(22)
	well.add_theme_stylebox_override("panel", well_style)
	card.add_child(well)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = pack_tex(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(6, 6)
	icon.size = Vector2(30, 30)
	well.add_child(icon)

	if not enabled:
		var lock := TextureRect.new()
		lock.name = "Lock"
		lock.texture = pack_tex("icons/icon_lock.png")
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock.position = Vector2(6, 6)
		lock.size = Vector2(30, 30)
		well.add_child(lock)

	# An empty slot has no charges to show.
	if enabled:
		var badge := PanelContainer.new()
		badge.name = "Badge"
		badge.add_theme_stylebox_override("panel", card_style(GOLD, GOLD_DARK, 2, 10, 4))
		badge.position = Vector2(108, 6)
		badge.size = Vector2(32, 22)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(badge)
		var badge_lbl := label(str(charges), 14, BAMBOO_DARK)
		badge_lbl.name = "BadgeLabel"
		badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_child(badge_lbl)

		var name_lbl := label(title, 12, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		name_lbl.name = "Title"
		name_lbl.position = Vector2(62, 14)
		name_lbl.size = Vector2(86, 18)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_lbl.clip_text = true
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name_lbl)

		var desc := label("TAP TO USE", 10, BAMBOO_DARK, HORIZONTAL_ALIGNMENT_LEFT)
		desc.name = "Hint"
		desc.position = Vector2(62, 33)
		desc.size = Vector2(86, 16)
		desc.autowrap_mode = TextServer.AUTOWRAP_OFF
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(desc)

	return card


static func perk_pill(perk_name: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", card_style(BAMBOO_TINT, BAMBOO_DARK, 2, 12, 5))
	p.custom_minimum_size = Vector2(0, 24)
	var l := label(perk_name, 12, BAMBOO_DARK)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	p.add_child(l)
	return p
