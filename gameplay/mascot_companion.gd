class_name MascotCompanion
extends Node2D
## MascotCompanion — Expressive Panda companion stationed above the puzzle corner.
##
## The panda is a real sprite (the Rotate Rings art), not a drawn blob, and it
## reacts to the run:
##   - "calm": default idle bob
##   - "celebrate": arms up, cheering after a clear
##   - "ghabraya": shivering, sweating when the budget is nearly gone
##   - "boss": determined, for boss puzzles
##   - "run_over": sleepy, on the run over screen

const TARGET_HEIGHT := 150.0

var current_mood: String = "calm"
var bob_time: float = 0.0

var _sprite_idle: Sprite2D = null
var _sprite_celebrate: Sprite2D = null
var _tex_idle: Texture2D = null
var _tex_celebrating: Texture2D = null
var _tween: Tween = null


func _ready() -> void:
	_tex_idle = _load_first([
		"res://art/gameplay/panda_standing_full.png",
		"res://art/panda_mascot.png",
		"res://art/gameplay/panda_companion.png",
	])
	_tex_celebrating = _load_first([
		"res://art/panda_mascot_celebrating.png",
	])

	if _tex_idle != null:
		_sprite_idle = Sprite2D.new()
		_sprite_idle.texture = _tex_idle
		_sprite_idle.centered = true
		var s := TARGET_HEIGHT / float(maxi(_tex_idle.get_height(), 1))
		_sprite_idle.scale = Vector2(s, s)
		add_child(_sprite_idle)

	if _tex_celebrating != null:
		_sprite_celebrate = Sprite2D.new()
		_sprite_celebrate.texture = _tex_celebrating
		_sprite_celebrate.centered = true
		var s2 := TARGET_HEIGHT / float(maxi(_tex_celebrating.get_height(), 1))
		_sprite_celebrate.scale = Vector2(s2, s2)
		_sprite_celebrate.modulate.a = 0.0
		add_child(_sprite_celebrate)


func _load_first(paths: Array) -> Texture2D:
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path)
	return null


func set_mood(mood: String) -> void:
	if current_mood == mood:
		return
	current_mood = mood
	_apply_mood()


## Swap to the celebrating sprite when the mood calls for it, and always
## animate so the panda never looks like a static sticker.
func _apply_mood() -> void:
	if _sprite_idle == null:
		return
	var celebrating := current_mood == "celebrate" and _sprite_celebrate != null
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_sprite_idle, "modulate:a", 0.0 if celebrating else 1.0, 0.18)
	if _sprite_celebrate != null:
		_tween.tween_property(_sprite_celebrate, "modulate:a", 1.0 if celebrating else 0.0, 0.18)


func _process(delta: float) -> void:
	bob_time += delta * (6.0 if current_mood == "ghabraya" else 2.2)
	var target := _sprite_idle
	if target == null:
		return
	var y_off := sin(bob_time) * (3.5 if current_mood == "ghabraya" else 1.8)
	var squash := 1.0
	if current_mood == "celebrate":
		squash = 1.0 + sin(bob_time * 4.0) * 0.05
		y_off -= 4.0 + absf(sin(bob_time * 2.0)) * 5.0
	elif current_mood == "ghabraya":
		squash = 1.0 + sin(bob_time * 9.0) * 0.03
	target.position.y = y_off
	target.scale.y = target.scale.x * squash
	# A sweat drop when the budget is nearly gone.
	if current_mood == "ghabraya" and is_instance_valid(_sweat):
		_sweat.position = Vector2(26, -18 + fmod(bob_time, 1.0) * 14.0)
		_sweat.queue_redraw()


var _sweat: Node2D = null


func _draw() -> void:
	# Only used when there is no sprite art at all: a simple drawn panda so the
	# companion is never missing.
	if _sprite_idle != null:
		return
	var c := Vector2(0, sin(bob_time) * 1.8)
	draw_circle(c + Vector2(-18, -18), 9.0, Color(0.12, 0.23, 0.18))
	draw_circle(c + Vector2(18, -18), 9.0, Color(0.12, 0.23, 0.18))
	draw_circle(c, 24.0, Color(1.0, 0.99, 0.96))
	draw_arc(c, 24.0, 0.0, TAU, 36, Color(0.12, 0.23, 0.18), 3.0, true)
	draw_circle(c + Vector2(-9, -3), 5.5, Color(0.12, 0.23, 0.18))
	draw_circle(c + Vector2(9, -3), 5.5, Color(0.12, 0.23, 0.18))
	draw_circle(c + Vector2(-9, -4), 2.0, Color.WHITE)
	draw_circle(c + Vector2(9, -4), 2.0, Color.WHITE)
	draw_circle(c + Vector2(0, 4), 3.2, Color(0.12, 0.23, 0.18))
	if current_mood == "ghabraya":
		draw_circle(c + Vector2(20, -6), 4.0, Color(0.25, 0.65, 0.96))
	elif current_mood == "celebrate":
		draw_circle(c + Vector2(-14, 4), 4.0, Color(0.95, 0.55, 0.55, 0.7))
		draw_circle(c + Vector2(14, 4), 4.0, Color(0.95, 0.55, 0.55, 0.7))
