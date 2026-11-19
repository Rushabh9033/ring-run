extends Node2D
class_name CArcStarBurst

const COLORS = [
	Color("2CE8F5"), # Cyan
	Color("FF55B8"), # Pink / Magenta
	Color("FFEA28"), # Sunny Yellow
	Color("4B6BFF"), # Royal Blue
]

var stars: Array = []
var elapsed: float = 0.0
var total_lifetime: float = 0.42

func setup(center_pos: Vector2, radius: float, start_ang: float = 0.0, arc_len: float = TAU) -> void:
	global_position = center_pos
	z_index = 100
	var count := randi_range(16, 20)
	for i in count:
		var t := float(i) / float(maxi(count - 1, 1))
		var ang := start_ang + t * arc_len
		var r_offset := randf_range(-4.0, 4.0)
		var spawn_pos := Vector2.from_angle(ang) * (radius + r_offset)
		var out_dir := Vector2.from_angle(ang + randf_range(-0.35, 0.35))
		var speed := randf_range(25.0, 50.0)
		var is_outline := (i % 2 == 1)
		var star_color: Color = COLORS[randi() % COLORS.size()]
		var star_size := randf_range(6.0, 9.0)
		
		stars.append({
			"pos": spawn_pos,
			"vel": out_dir * speed + Vector2(randf_range(-8.0, 8.0), randf_range(-18.0, 4.0)),
			"rot": randf() * TAU,
			"rot_speed": randf_range(-3.5, 3.5),
			"size": star_size,
			"color": star_color,
			"outline": is_outline,
			"life": randf_range(0.32, 0.42),
		})
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= total_lifetime:
		queue_free()
		return
	for s in stars:
		s.pos += s.vel * delta
		s.rot += s.rot_speed * delta
		s.vel *= 0.94 # gentle dampening
	queue_redraw()

func _draw() -> void:
	for s in stars:
		var progress: float = clampf(elapsed / s.life, 0.0, 1.0)
		if progress >= 1.0:
			continue
		var scale_factor: float = 1.0 - progress * progress
		var cur_size: float = s.size * scale_factor
		if cur_size < 1.0:
			continue
		
		var pts := _generate_star_pts(s.pos, cur_size, s.rot)
		if s.outline:
			pts.append(pts[0])
			draw_polyline(pts, s.color, 2.2, true)
		else:
			draw_colored_polygon(pts, s.color)

func _generate_star_pts(center: Vector2, outer_r: float, rotation: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var inner_r := outer_r * 0.44
	for i in 10:
		var a := rotation + float(i) * (TAU / 10.0)
		var r := outer_r if (i % 2 == 0) else inner_r
		pts.append(center + Vector2.from_angle(a) * r)
	return pts
