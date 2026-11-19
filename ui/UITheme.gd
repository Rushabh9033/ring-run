extends Node
## UITheme — Centralized Bamboo, Cream & Forest Green styling helper for Godot 4.
## Guarantees high-contrast dark ink (#1E3A2F) text on cream cards (#FFFDF7)
## and crisp StyleBoxFlat panels, buttons, and rarity borders.

const COL_BG_CREAM := Color("#F6F4EB")
const COL_CARD := Color("#FFFDF7")
const COL_INK := Color("#1E3A2F")
const COL_MUTED := Color("#4A6358")
const COL_BAMBOO := Color("#2E7D32")
const COL_BAMBOO_LIGHT := Color("#E8F5E9")
const COL_RARE_BLUE := Color("#1976D2")
const COL_EPIC_GOLD := Color("#FFB300")
const COL_AMBER := Color("#EF6C00")
const COL_DANGER_RED := Color("#D32F2F")

func make_card_style(bg: Color = COL_CARD, border: Color = COL_INK, border_w: int = 2, radius: int = 16, pad: int = 12) -> StyleBoxFlat:
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

func make_label(text_str: String, font_size: int = 16, color: Color = COL_INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var lbl := Label.new()
	lbl.text = text_str
	lbl.horizontal_alignment = align
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func make_button(text_str: String, bg: Color = COL_BAMBOO, fg: Color = Color.WHITE, border: Color = COL_INK, min_size: Vector2 = Vector2(120, 50), font_size: int = 16) -> Button:
	var btn := Button.new()
	btn.text = text_str
	btn.custom_minimum_size = min_size
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)
	btn.add_theme_color_override("font_focus_color", fg)
	btn.add_theme_color_override("font_disabled_color", Color(fg.r, fg.g, fg.b, 0.45))

	var normal := make_card_style(bg, border, 2, 14, 10)
	var hover := make_card_style(bg.lightened(0.08), border, 2, 14, 10)
	var pressed := make_card_style(bg.darkened(0.10), border, 2, 14, 10)
	var disabled := make_card_style(Color(bg.r, bg.g, bg.b, 0.45), Color(border.r, border.g, border.b, 0.35), 2, 14, 10)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	return btn

func rarity_color(rarity: String) -> Color:
	match rarity:
		"epic":
			return COL_EPIC_GOLD
		"rare":
			return COL_RARE_BLUE
		_:
			return COL_BAMBOO

func rarity_badge_text(rarity: String) -> String:
	match rarity:
		"epic":
			return "HEXAGON · EPIC"
		"rare":
			return "DIAMOND · RARE"
		_:
			return "CIRCLE · COMMON"
