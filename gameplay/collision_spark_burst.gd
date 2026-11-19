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
		# A radial burst: each spark gets its own angle around the emitter,
		# with a little speed variation.
		var ang := (TAU * float(i)) / float(count) + randf_range(-0.25, 0.25)
		var spd := randf_range(70.0, 185.0)
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"color": color,
			"size": randf_range(2.5, 5.5),
			"spin": randf_range(-9.0, 9.0),
			"rot": randf() * TAU
		})

func _process(delta: float) -> void:
	elapsed += delta
	for p in particles:
		p["pos"] += p["vel"] * delta
		# The sparks slow down and cool off as they fly.
		p["vel"] *= 1.0 - 2.6 * delta
		p["rot"] += float(p["spin"]) * delta
	queue_redraw()
	if elapsed >= lifetime:
		queue_free()

func _draw() -> void:
	var alpha := clampf(1.0 - (elapsed / lifetime), 0.0, 1.0)
	for p in particles:
		var c: Color = p["color"]
		c.a = alpha
		# A tiny trail behind each spark.
		var tail: Vector2 = p["pos"] - p["vel"].normalized() * float(p["size"]) * 1.6
		draw_line(tail, p["pos"], Color(c.r, c.g, c.b, alpha * 0.5), float(p["size"]) * 0.7, true)
		draw_circle(p["pos"], float(p["size"]), c)
