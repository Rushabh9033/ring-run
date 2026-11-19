class_name ConfettiBurst
extends Node2D

const VfxLib = preload("res://gameplay/vfx.gd")
## ConfettiBurst — the celebration when a puzzle is cleared.
##
## Five colours of paper chunks burst upward and fall back down. The chunks
## are drawn as a texture so the particles behave like real paper.

const COLORS: Array[Color] = [
	Color("FF6A45"),
	Color("3DDC97"),
	Color("3EBEFF"),
	Color("F0B429"),
	Color("7B61FF"),
]

var _particles: Array[CPUParticles2D] = []


## Fire the celebration at a GLOBAL (canvas) position.
static func fire(parent: Node, global_pos: Vector2, amount: int = 9) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var burst := ConfettiBurst.new()
	burst.z_index = 200
	VfxLib.spawn_at(parent, global_pos, burst)
	burst._launch(amount)


func _launch(amount: int) -> void:
	var chunk_tex := _chunk_texture()
	for c in COLORS:
		var p := CPUParticles2D.new()
		p.one_shot = true
		p.explosiveness = 0.92
		p.lifetime = 2.2
		p.amount = amount
		# Up and outward, with a wide spread so the paper scatters instead of
		# firing as one column.
		p.direction = Vector2(0, -1)
		p.spread = 165.0
		# A little sideways drift per colour group, so the burst never looks
		# like everything is travelling the same way.
		p.gravity = Vector2(randf_range(-40.0, 40.0), 760.0)
		p.initial_velocity_min = 240.0
		p.initial_velocity_max = 720.0
		p.damping_min = 12.0
		p.damping_max = 48.0
		p.angular_velocity_min = -540.0
		p.angular_velocity_max = 540.0
		p.scale_amount_min = 0.7
		p.scale_amount_max = 1.5
		# The chunks shrink away as they fall.
		var shrink := Curve.new()
		shrink.add_point(Vector2(0.0, 1.0))
		shrink.add_point(Vector2(0.7, 1.0))
		shrink.add_point(Vector2(1.0, 0.55))
		p.scale_amount_curve = shrink
		# And fade out.
		var fade := Gradient.new()
		fade.set_color(0, Color(1, 1, 1, 1))
		fade.set_color(1, Color(1, 1, 1, 0))
		fade.add_point(0.6, Color(1, 1, 1, 1))
		p.color_ramp = fade
		p.texture = chunk_tex
		p.color = c
		p.position = Vector2(randf_range(-24.0, 24.0), randf_range(-12.0, 12.0))
		add_child(p)
		p.emitting = true
		_particles.append(p)
	var tw := create_tween()
	tw.tween_callback(queue_free).set_delay(2.6)


## A torn-paper chunk, drawn once and shared by every particle.
##
## Small on purpose: at a 48px canvas the chunks were big hexagons that
## covered the puzzle instead of reading as confetti.
static func _chunk_texture() -> Texture2D:
	var size := 20
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# An irregular torn rectangle rather than a clean polygon.
	var pts: Array[Vector2] = [
		Vector2(2, 4), Vector2(11, 1), Vector2(18, 5), Vector2(17, 13),
		Vector2(19, 18), Vector2(10, 19), Vector2(3, 16), Vector2(4, 9),
	]
	for y in range(size):
		for x in range(size):
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, pts):
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)
