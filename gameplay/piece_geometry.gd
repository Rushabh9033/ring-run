class_name PieceGeometry
extends RefCounted
## PieceGeometry — Computes ring outlines, gap arcs, and connector pin positions
## for all 4 supported ring shapes: circle, oval, square, and triangle.

const STEPS := 8
const STEP_RAD := TAU / float(STEPS)

static func step_to_rad(step: int) -> float:
	return float((step % STEPS + STEPS) % STEPS) * STEP_RAD

static func rad_to_nearest_step(angle_rad: float) -> int:
	var norm := fposmod(angle_rad, TAU)
	return int(round(norm / STEP_RAD)) % STEPS

static func is_angle_near_target(current_rad: float, target_steps: Array, tolerance_rad: float = 0.22) -> bool:
	for st in target_steps:
		var target_rad := step_to_rad(int(st))
		var diff := absf(angle_difference(current_rad, target_rad))
		if diff <= tolerance_rad:
			return true
	return false

static func build_ring_arc_points(shape: String, radius: float, gap_Width_deg: float, has_double_gap: bool) -> Array[PackedVector2Array]:
	var segments: Array[PackedVector2Array] = []
	var half_gap_rad := deg_to_rad(gap_Width_deg * 0.5)
	if has_double_gap:
		segments.append(_sample_shape_arc(shape, radius, half_gap_rad, PI - half_gap_rad, 32))
		segments.append(_sample_shape_arc(shape, radius, PI + half_gap_rad, TAU - half_gap_rad, 32))
	else:
		segments.append(_sample_shape_arc(shape, radius, half_gap_rad, TAU - half_gap_rad, 56))
	return segments

static func _sample_shape_arc(shape: String, radius: float, start_a: float, end_a: float, steps: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var a := lerpf(start_a, end_a, t)
		pts.append(point_on_shape(shape, radius, a))
	return pts

static func point_on_shape(shape: String, radius: float, angle_rad: float) -> Vector2:
	match shape:
		"oval":
			return Vector2(cos(angle_rad) * radius * 1.18, sin(angle_rad) * radius * 0.84)
		"square":
			var c := cos(angle_rad)
			var s := sin(angle_rad)
			var m := maxf(absf(c), absf(s))
			var blend := lerpf(1.0, 1.0 / maxf(0.001, m), 0.65)
			return Vector2(c, s) * radius * blend
		"triangle":
			var r_mod := 1.0 + 0.18 * cos(3.0 * angle_rad)
			return Vector2(cos(angle_rad), sin(angle_rad)) * radius * r_mod
		_:
			return Vector2(cos(angle_rad), sin(angle_rad)) * radius
