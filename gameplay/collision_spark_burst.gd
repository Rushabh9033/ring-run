class_name CollisionSparkBurst
extends Node2D
## CollisionSparkBurst — Emits golden contact sparks when a ring is blocked
## or bamboo/bubble shards when Snip or Pop is triggered.

var particles: Array[Dictionary] = []
var elapsed: float = 0.0
var lifetime: float = 0.35

func emit_burst(pos: Vector2, color: Color = Color(1.0, 0.84, 0.25), count: int = 12, duration: float = 0.35) -> void:
	position = pos
	lifetime = duration
	particles.clear()
	for i in range(count):
		var ang := (TAU * float(i)) / float(count) + randf_range(-0.2, 0.2)
		var spd := randf_range(65.0, 175.0)
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"color": color,
			"size": randf_range(3.0, 6.0)
		})

func _process(delta: float) -> void:
	elapsed += delta
	for p in particles:
		p["pos"] += p["vel"] * delta
	queue_redraw()
	if elapsed >= lifetime:
		queue_free()

func _draw() -> void:
	var alpha := clampf(1.0 - (elapsed / lifetime), 0.0, 1.0)
	for p in particles:
		var c: Color = p["color"]
		c.a = alpha
		draw_circle(p["pos"], float(p["size"]), c)
