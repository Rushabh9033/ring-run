extends Node2D
## HomeRingDrawer — one bamboo ring of the home screen diorama.
##
## Draws the same layered tube as the board rings (shadow, contour, lacquer
## body, node bands, specular sheen, wooden caps) and drifts slowly, so the
## home screen shows the game's own art in motion.

var radius: float = 76.0
var ring_color: Color = Color("#2E7D32")
var tube_width: float = 13.0
var phase: float = 0.0
var speed: float = 0.2
var time: float = 0.0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# A slow drift so the rings feel alive rather than spinning like a fan.
	var wobble := sin(time * speed + phase) * 0.22
	rotation = wobble

	var gap_center := sin(time * 0.35 + phase) * TAU
	var half_gap := deg_to_rad(24.0)
	var segs := 44
	var pts := PackedVector2Array()
	for i in range(segs + 1):
		var a := lerpf(gap_center + half_gap, gap_center + TAU - half_gap, float(i) / float(segs))
		pts.append(Vector2.from_angle(a) * radius)

	var shadow := PackedVector2Array()
	var sheen := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(4.0, 5.0))
		sheen.append(p + Vector2(-1.2, -1.6))

	var dark := ring_color.darkened(0.36)
	var light := ring_color.lightened(0.34)
	light.a = 0.42

	draw_polyline(shadow, Color(0.12, 0.20, 0.10, 0.16), tube_width + 3.0, true)
	draw_polyline(pts, dark, tube_width + 2.0, true)
	draw_polyline(pts, ring_color, tube_width, true)

	# A golden node band, so it reads as bamboo.
	var mid := pts[int(segs * 0.5)]
	var tangent := (pts[int(segs * 0.5) + 1] - pts[int(segs * 0.5) - 1]).normalized()
	var normal := Vector2(-tangent.y, tangent.x)
	var w_half := tube_width * 0.46
	draw_line(mid - normal * w_half, mid + normal * w_half, Color("#C99236"), 4.0, true)
	draw_line(mid - normal * w_half, mid + normal * w_half, Color("#E4B45C"), 1.8, true)

	draw_polyline(sheen, light, tube_width * 0.30, true)

	# Wooden caps at the gap edges.
	draw_circle(pts[0], tube_width * 0.40, Color("#DFC088"))
	draw_circle(pts[pts.size() - 1], tube_width * 0.40, Color("#DFC088"))
