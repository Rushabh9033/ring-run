class_name ConfettiBurst
extends Node2D
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


static func fire(parent: Node, pos: Vector2, amount: int = 18) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var burst := ConfettiBurst.new()
	burst.position = pos
	burst.z_index = 200
	parent.add_child(burst)
	burst._launch(amount)


func _launch(amount: int) -> void:
	var chunk_tex := _chunk_texture()
	for c in COLORS:
		var p := CPUParticles2D.new()
		p.one_shot = true
		p.explosiveness = 0.92
		p.lifetime = 2.2
		p.amount = amount
		p.direction = Vector2(0, -1)
		p.spread = 140.0
		p.gravity = Vector2(0, 720.0)
		p.initial_velocity_min = 280.0
		p.initial_velocity_max = 760.0
		p.angular_velocity_min = -540.0
		p.angular_velocity_max = 540.0
		p.scale_amount_min = 0.45
		p.scale_amount_max = 1.15
		p.texture = chunk_tex
		p.color = c
		p.position = Vector2(randf_range(-24.0, 24.0), randf_range(-12.0, 12.0))
		add_child(p)
		p.emitting = true
		_particles.append(p)
	var tw := create_tween()
	tw.tween_callback(queue_free).set_delay(2.6)


## A torn-paper chunk, drawn once and shared by every particle.
static func _chunk_texture() -> Texture2D:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var pts: Array[Vector2] = [
		Vector2(24, 6), Vector2(40, 16), Vector2(42, 32),
		Vector2(28, 44), Vector2(10, 34), Vector2(8, 16),
	]
	for y in range(48):
		for x in range(48):
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, pts):
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)
