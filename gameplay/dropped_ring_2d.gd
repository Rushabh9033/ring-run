class_name DroppedRing2D
extends Node2D
## DroppedRing2D — 600ms physics drop & spin animation when a ring is released
## or when remaining rings fall on Run Over.
##
## The falling ring is drawn as a real bamboo tube, not a flat arc, so it keeps
## looking like the ring the player just let go of.

var velocity: Vector2 = Vector2(0, -140)
var gravity: float = 980.0
var angular_vel: float = 3.2
var elapsed: float = 0.0
var duration: float = 0.60
var ring_radius: float = 70.0
var ring_color: Color = Color(0.3, 0.69, 0.31)
var thickness: float = 14.0
var gap_deg: float = 44.0


func start_drop(radius_px: float, col: Color, custom_duration: float = 0.60, thick: float = 14.0, gap_width_deg: float = 44.0) -> void:
	ring_radius = radius_px
	ring_color = col
	thickness = thick
	gap_deg = gap_width_deg
	duration = custom_duration
	velocity = Vector2(randf_range(-90.0, 90.0), randf_range(-180.0, -95.0))
	angular_vel = randf_range(-4.5, 4.5)


func _process(delta: float) -> void:
	elapsed += delta
	velocity.y += gravity * delta
	position += velocity * delta
	rotation += angular_vel * delta
	modulate.a = clampf(1.0 - (elapsed / duration), 0.0, 1.0)
	if elapsed >= duration:
		queue_free()


func _draw() -> void:
	var half_gap := deg_to_rad(gap_deg * 0.5)
	var segs := 40
	var pts := PackedVector2Array()
	for i in range(segs + 1):
		var a := lerpf(half_gap, TAU - half_gap, float(i) / float(segs))
		pts.append(Vector2.from_angle(a) * ring_radius)
	var dark := ring_color.darkened(0.36)
	var light := ring_color.lightened(0.38)
	light.a = 0.6
	var shadow_pts := PackedVector2Array()
	for p in pts:
		shadow_pts.append(p + Vector2(4.0, 5.0))
	draw_polyline(shadow_pts, Color(0.12, 0.20, 0.10, 0.20), thickness + 3.0, true)
	draw_polyline(pts, dark, thickness + 2.0, true)
	draw_polyline(pts, ring_color, thickness, true)
	var sheen_pts := PackedVector2Array()
	for p in pts:
		sheen_pts.append(p + Vector2(-1.4, -1.8))
	draw_polyline(sheen_pts, light, thickness * 0.34, true)
	draw_circle(pts[0], thickness * 0.5, Color("#E7C88A"))
	draw_circle(pts[pts.size() - 1], thickness * 0.5, Color("#E7C88A"))
