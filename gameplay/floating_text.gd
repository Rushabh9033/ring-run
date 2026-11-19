class_name FloatingText
extends Node2D

const VfxLib = preload("res://gameplay/vfx.gd")

# Game praise popup ("Good!", "Great!", "Excellent!") with glossy white body, cyan/green/purple outline and glow
var label: Label
func setup(pos: Vector2, text_content: String, outline_accent: Color) -> void:
	VfxLib.place_at_self(self, pos)
	z_index = 100
	label = Label.new()
	label.text = text_content
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Larger punchy font
	label.add_theme_font_size_override("font_size", 40)
	# Vibrant celebratory fill inside
	label.add_theme_color_override("font_color", outline_accent)
	# Crisp white border/outline
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 9)
	# Rich ambient shadow behind white border for high contrast against light sand
	label.add_theme_color_override("font_shadow_color", Color(0.12, 0.20, 0.08, 0.45))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 5)
	# Center label pivot
	label.position = Vector2(-160, -32)
	label.custom_minimum_size = Vector2(320, 70)
	label.add_theme_font_override("font", preload("res://app/ui_theme.gd").rounded_font())
	add_child(label)
	# Micro-burst of sparkling stars around the praise text
	var sparkles := Node2D.new()
	add_child(sparkles)
	for i in 8:
		var sp := Sprite2D.new()
		var sp_tw := create_tween().set_parallel(true)
		var ang := randf() * TAU
		var dist := randf_range(28.0, 62.0)
		var target := Vector2.from_angle(ang) * dist
		var col := outline_accent.lightened(randf_range(0.1, 0.4))
		# Draw mini star
		var star_drawer := _MiniSparkle.new(col)
		sparkles.add_child(star_drawer)
		star_drawer.scale = Vector2.ZERO
		sp_tw.tween_property(star_drawer, "position", target, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		sp_tw.tween_property(star_drawer, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		sp_tw.chain().tween_property(star_drawer, "scale", Vector2.ZERO, 0.35)
	scale = Vector2(0.2, 0.2)
	modulate.a = 1.0
	var tween = create_tween().set_parallel(true)
	# Punchy pop-in
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - 52.0, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.35)
	tween.chain().tween_callback(queue_free)
class _MiniSparkle extends Node2D:
	var color: Color
	func _init(c: Color) -> void:
		color = c
	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 10:
			var a := float(i) * (TAU / 10.0)
			var r := 5.0 if (i % 2 == 0) else 2.2
			pts.append(Vector2.from_angle(a) * r)
		draw_colored_polygon(pts, color)
		draw_polyline(pts, Color.WHITE, 1.0, true)