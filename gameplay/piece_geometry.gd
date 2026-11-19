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

## The distance from a point to the nearest SOLID part of a ring's outline.
##
## This is the same outline the ring is drawn from, so a touch lands where
## the player sees the tube. The gaps are open: a touch inside a gap is not
## on the ring at all, which is what lets the exit channel be reached.
##
## A pure radial test (comparing |point| with the radius) is wrong for every
## shape but the circle - a square's radius depends on the angle, and an oval
## and a triangle are not round at all.
static func distance_to_ring(shape: String, radius: float, gap_width_deg: float, has_double_gap: bool, point: Vector2) -> float:
	# A circle is exact, and it is the common case.
	if shape != "circle" and shape != "oval" and shape != "square" and shape != "triangle":
		return absf(point.length() - radius)

	var half_gap := deg_to_rad(gap_width_deg * 0.5)
	var arcs: Array[Vector2] = []
	if has_double_gap:
		arcs.append(Vector2(half_gap, PI - half_gap))
		arcs.append(Vector2(PI + half_gap, TAU - half_gap))
	else:
		arcs.append(Vector2(half_gap, TAU - half_gap))

	var best := INF
	for arc in arcs:
		var steps := 72
		var prev := point_on_shape(shape, radius, arc.x)
		for i in range(1, steps + 1):
			var a: float = lerpf(arc.x, arc.y, float(i) / float(steps))
			var cur := point_on_shape(shape, radius, a)
			best = minf(best, _distance_to_segment(point, prev, cur))
			prev = cur
	return best


## The distance from a point to a line segment.
static func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len2 := ab.length_squared()
	if len2 < 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Does a touch at `point` land on the ring?
##
## `tolerance` is the finger pad: the tube's half width plus enough slack to
## make a fingertip count.
static func ring_hit_test(shape: String, radius: float, gap_width_deg: float, has_double_gap: bool, point: Vector2, thickness: float) -> bool:
	var tolerance: float = maxf(thickness * 0.5 + 12.0, 16.0)
	return distance_to_ring(shape, radius, gap_width_deg, has_double_gap, point) <= tolerance


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
