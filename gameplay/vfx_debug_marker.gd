extends Node2D
## VfxDebugMarker — a development-only overlay that shows where an effect was
## spawned and which way it was meant to travel.
##
## Enabled only while Vfx.DEBUG_MARKERS is true. It is not used in a normal
## build, and the marker removes itself after a moment.

var direction: Vector2 = Vector2.ZERO
var color: Color = Color(1, 0.4, 0.4, 0.9)
var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t > 3.0:
		queue_free()


func _draw() -> void:
	# the emitter centre
	draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 32, color, 2.0, true)
	draw_line(Vector2(-34, 0), Vector2(34, 0), color, 1.0, true)
	draw_line(Vector2(0, -34), Vector2(0, 34), color, 1.0, true)
	# the intended direction
	if direction.length_squared() > 0.001:
		var d := direction.normalized() * 46.0
		draw_line(Vector2.ZERO, d, color, 3.0, true)
		draw_circle(d, 4.0, color)
