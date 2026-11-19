class_name RingPiece2D
extends Node2D
## RingPiece2D — Renders an interactive ring with shape support (circle, oval,
## square, triangle), Golden Ring shimmer, Curse dark pulse outline, gap glow,
## slider pin lock handle, and 80ms 1.04x grab scale animation.
##
## The ring body is drawn as a lacquered bamboo tube: a soft drop shadow, a
## dark contour rim for separation, the lacquer body, golden node bands,
## embossed leaf crests, a specular sheen and a wooden end cap at each gap
## edge. That layering is what makes the rings read as solid objects on the
## sand garden rather than as flat outlines.

const PieceGeometry = preload("res://gameplay/piece_geometry.gd")

var ring_data: Dictionary = {}
var ring_index: int = 0
var is_grabbed: bool = false
var is_near_aligned: bool = false
var is_hinted: bool = false
var curse_pulse_time: float = 0.0
var jiggle_offset_rad: float = 0.0

# --- tube colours, derived from the ring colour ---
var _c_shadow := Color(0.12, 0.20, 0.10, 0.22)
var _c_dark := Color.WHITE
var _c_main := Color.WHITE
var _c_light := Color.WHITE
var _c_specular := Color(1.0, 1.0, 1.0, 0.5)
var _c_inner := Color.WHITE

# The arcs the ring is made of, in local space.
var _segments: Array[PackedVector2Array] = []
var _seg_angles: Array[Vector2] = []  # (start angle, end angle) per segment


func setup(idx: int, spec: Dictionary) -> void:
	ring_index = idx
	ring_data = spec.duplicate(true)
	_rebuild_geometry()
	_precompute_colors()
	var st := int(ring_data.get("current_step", ring_data.get("start_step", 0)))
	rotation = PieceGeometry.step_to_rad(st)
	queue_redraw()


func sync_from_state(spec: Dictionary) -> void:
	ring_data = spec.duplicate(true)
	_rebuild_geometry()
	if not is_grabbed:
		var st := int(ring_data.get("current_step", 0))
		rotation = PieceGeometry.step_to_rad(st)
	queue_redraw()


## Recompute the outline arcs. Cheap enough to call whenever the gap width
## changes (the Stretch power widens a gap).
func _rebuild_geometry() -> void:
	var radius := float(ring_data.get("radius_px", 70.0))
	var gap_deg := float(ring_data.get("gap_width_deg", 44.0))
	if bool(ring_data.get("stretched", false)):
		gap_deg *= 1.65
	var targets: Array = ring_data.get("target_steps", [0])
	var has_double_gap := targets.size() >= 2
	var shape := str(ring_data.get("shape", "circle"))
	_segments = PieceGeometry.build_ring_arc_points(shape, radius, gap_deg, has_double_gap)
	_seg_angles.clear()
	var half_gap := deg_to_rad(gap_deg * 0.5)
	if has_double_gap:
		_seg_angles.append(Vector2(half_gap, PI - half_gap))
		_seg_angles.append(Vector2(PI + half_gap, TAU - half_gap))
	else:
		_seg_angles.append(Vector2(half_gap, TAU - half_gap))


func _precompute_colors() -> void:
	var base := _base_color()
	_c_shadow = Color(0.12, 0.20, 0.10, 0.22)
	_c_dark = base.darkened(0.36)
	_c_main = base.lightened(0.02)
	_c_light = base.lightened(0.34)
	_c_light.a = 0.42
	_c_specular = Color(1.0, 1.0, 1.0, 0.34)
	_c_inner = base.darkened(0.30)
	_c_inner.a = 0.7


func _base_color() -> Color:
	if bool(ring_data.get("is_golden", false)):
		return Color("#FFB300")
	return Color.from_string(str(ring_data.get("color", "#4CAF50")), Color(0.3, 0.69, 0.31))


func set_grabbed(grabbed: bool) -> void:
	is_grabbed = grabbed
	var target_scale := Vector2(1.04, 1.04) if grabbed else Vector2.ONE
	var tw := create_tween()
	tw.tween_property(self, "scale", target_scale, 0.08)
	queue_redraw()


func trigger_blocked_jiggle() -> void:
	if SaveService.is_reduced_motion():
		return
	var base_rot := rotation
	var tw := create_tween()
	tw.tween_property(self, "rotation", base_rot + deg_to_rad(3.5), 0.05)
	tw.tween_property(self, "rotation", base_rot - deg_to_rad(3.5), 0.05)
	tw.tween_property(self, "rotation", base_rot, 0.08)


func play_rewind_spin(target_step: int) -> void:
	var target_rad := PieceGeometry.step_to_rad(target_step)
	var tw := create_tween()
	tw.tween_property(self, "rotation", target_rad, 0.20)
	tw.tween_callback(func(): queue_redraw())


func _process(delta: float) -> void:
	if bool(ring_data.get("is_heavy", false)) or bool(ring_data.get("is_one_way", false)) or bool(ring_data.get("initially_locked", false)) or is_hinted or bool(ring_data.get("is_golden", false)):
		curse_pulse_time += delta * 4.0
		queue_redraw()


func _draw() -> void:
	if _segments.is_empty():
		return
	var thickness := float(ring_data.get("thickness_px", 14.0))
	var base := _base_color()
	var cursed := bool(ring_data.get("is_heavy", false)) or bool(ring_data.get("is_one_way", false)) or bool(ring_data.get("initially_locked", false))

	for i in range(_segments.size()):
		var seg := _segments[i]
		if seg.size() < 2:
			continue

		# 1. Soft drop shadow onto the sand garden
		_draw_tube(_offset_pts(seg, Vector2(5.0, 7.0)), thickness + 3.0, _c_shadow)

		# 2. Curse aura / hint glow / grab glow, under the body
		if cursed:
			var alpha := 0.32 + 0.28 * sin(curse_pulse_time)
			_draw_tube(seg, thickness + 9.0, Color(0.55, 0.12, 0.22, alpha))
		if is_hinted:
			var h_alpha := 0.45 + 0.35 * sin(curse_pulse_time * 1.5)
			_draw_tube(seg, thickness + 10.0, Color(1.0, 0.78, 0.0, h_alpha))
		if is_grabbed or is_near_aligned:
			var glow := Color(1.0, 0.92, 0.30, 0.62) if is_near_aligned else Color(1.0, 1.0, 1.0, 0.42)
			_draw_tube(seg, thickness + 7.0, glow)

		# 3. The golden ring glows - it pays out a bonus if it is freed first.
		if bool(ring_data.get("is_golden", false)):
			var g_alpha := 0.30 + 0.28 * sin(curse_pulse_time * 0.7)
			_draw_tube(seg, thickness + 11.0, Color(1.0, 0.78, 0.25, g_alpha))

		# 4. Dark contour rim for crisp separation
		_draw_tube(seg, thickness + 2.2, _c_dark)

		# 4. Lacquered bamboo body
		_draw_tube(seg, thickness, _c_main)

		# 5. Golden node bands along the arc
		_draw_node_bands(i, thickness)

		# 6. Specular sheen, offset up and left like a studio light
		_draw_tube(_offset_pts(seg, Vector2(-1.3, -1.7)), thickness * 0.30, _c_light)
		_draw_tube(_offset_pts(seg, Vector2(-1.7, -2.2)), thickness * 0.11, _c_specular)

		# 7. Wooden end caps at the gap edges
		_draw_end_caps(i, thickness, base)

	# The gap alignment notch: the ring's gap must line up with the exit gate
	var shape := str(ring_data.get("shape", "circle"))
	var radius := float(ring_data.get("radius_px", 70.0))
	var gap_center := PieceGeometry.point_on_shape(shape, radius, 0.0)
	draw_circle(gap_center, 4.5, Color("#2E7D32") if is_near_aligned else Color(0.12, 0.23, 0.18, 0.55))

	# Connector pins on the ring body
	var thickness2 := float(ring_data.get("thickness_px", 14.0))
	var conn_count := int(ring_data.get("connectors", 1))
	for c_i in range(conn_count):
		var pin_angle := PI + float(c_i) * (PI * 0.5)
		var p := PieceGeometry.point_on_shape(shape, radius, pin_angle)
		draw_circle(p, thickness2 * 0.55, Color("#1E3A2F"))
		draw_circle(p, thickness2 * 0.30, Color("#FFFDF7"))

	# Slider pin lock, if not yet slid open
	if not bool(ring_data.get("slider_unlocked", true)):
		var sp := PieceGeometry.point_on_shape(shape, radius, PI * 0.5)
		draw_circle(sp, 11.0, Color("#EF6C00"))
		draw_circle(sp, 5.0, Color("#FFFDF7"))


## Draw a tube along a polyline: an outer dark rim and a lighter inner body,
## which is what gives the flat polyline its sense of roundness.
func _draw_tube(pts: PackedVector2Array, width: float, col: Color) -> void:
	draw_polyline(pts, col, width, true)
	var n := pts.size()
	if n < 2:
		return
	# Round off both ends so the tube does not look cut off.
	draw_circle(pts[0], width * 0.5, col)
	draw_circle(pts[n - 1], width * 0.5, col)


## The same polyline, shifted by a fixed offset.
static func _offset_pts(pts: PackedVector2Array, off: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + off)
	return out


## The golden joint collars that make the tube read as bamboo segments.
func _draw_node_bands(seg_index: int, thickness: float) -> void:
	var seg := _segments[seg_index]
	if seg.size() < 4:
		return
	var span := _seg_angles[seg_index]
	var arc_span := span.y - span.x
	if arc_span <= 0.4:
		return
	var fracs := [0.34, 0.68] if arc_span < 3.6 else [0.22, 0.50, 0.78]
	var n := seg.size()
	for frac in fracs:
		var idx := clampi(int(float(n - 1) * float(frac)), 1, n - 2)
		var node_center: Vector2 = seg[idx]
		var tangent := (seg[idx + 1] - seg[idx - 1]).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		var w_half := thickness * 0.48
		draw_line(node_center - normal * w_half, node_center + normal * w_half, Color("#C99236"), 4.2, true)
		draw_line(node_center - normal * w_half, node_center + normal * w_half, Color("#E4B45C"), 2.0, true)
		draw_line(node_center - tangent * 2.4 - normal * w_half, node_center - tangent * 2.4 + normal * w_half, Color("#3F260C"), 1.2, true)
		draw_line(node_center + tangent * 2.4 - normal * w_half, node_center + tangent * 2.4 + normal * w_half, Color("#3F260C"), 1.2, true)


## The cut end of a bamboo tube: a wooden cap with a lighter pith in the middle.
func _draw_end_caps(seg_index: int, thickness: float, base: Color) -> void:
	var seg := _segments[seg_index]
	if seg.size() < 2:
		return
	var cap_r := thickness * 0.5
	for endpoint in [seg[0], seg[seg.size() - 1]]:
		var p: Vector2 = endpoint
		draw_circle(p, cap_r * 0.82, Color("#DFC088"))
		draw_circle(p, cap_r * 0.52, Color("#F2DFB6"))
		draw_circle(p, cap_r * 0.20, base.darkened(0.2))
