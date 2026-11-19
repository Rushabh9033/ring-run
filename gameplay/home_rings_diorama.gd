class_name HomeRingsDiorama
extends Node2D
## HomeRingsDiorama — the animated puzzle on the home screen.
##
## The middle of the home screen was dead space. Instead of a picture, it
## shows a real puzzle: three bamboo rings that turn on their own, a gap that
## catches the light, and a drifting star spark. It is the game, at rest.

var _rings: Array[Node2D] = []
var _time: float = 0.0
var _spark: Node2D = null
var _hub_glow: float = 0.0


func _ready() -> void:
	var radii: Array[float] = [58.0, 96.0, 134.0]
	# The board's own palette, so the home screen shows the real game.
	var colors: Array[Color] = [
		Color("#32ADDA"), Color("#EA7829"), Color("#7B61FF"),
	]
	var widths: Array[float] = [14.0, 14.0, 13.0]
	for i in range(radii.size()):
		var ring := Node2D.new()
		ring.set_script(preload("res://gameplay/home_ring_drawer.gd"))
		ring.set("radius", radii[i])
		ring.set("ring_color", colors[i])
		ring.set("tube_width", widths[i])
		ring.set("phase", float(i) * 2.1)
		ring.set("speed", 0.22 if i == 1 else (-0.13 if i == 0 else 0.09))
		add_child(ring)
		_rings.append(ring)

	_hub_glow = 0.0


func _process(delta: float) -> void:
	_time += delta
	for ring in _rings:
		if is_instance_valid(ring):
			ring.set("time", _time)
	queue_redraw()


func _draw() -> void:
	# A soft glow behind the innermost ring, so the centre looks alive.
	var pulse := 0.5 + 0.5 * sin(_time * 1.4)
	draw_circle(Vector2.ZERO, 16.0 + pulse * 4.0, Color(1.0, 0.92, 0.55, 0.10 + pulse * 0.08))
	draw_circle(Vector2.ZERO, 9.0, Color("#3B5323"))
	draw_circle(Vector2.ZERO, 5.0, Color("#FFFDF7"))
