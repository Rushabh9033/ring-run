class_name RingReleaseFX
extends RefCounted
## RingReleaseFX — the celebration that plays when a ring comes off the board.
##
## A ring release is three things at once: the ring itself falls away, the
## tube shatters into bamboo shards, and a ring of stars pops out along the
## gap the ring was pointing at. A praise word floats up on top of it.
##
## Every position here is a GLOBAL (canvas) coordinate. Vfx converts it into
## the parent's local space, so the effect always lands on the ring that
## produced it - whatever the board's transform happens to be.

const CArcStarBurstScript = preload("res://gameplay/c_arc_star_burst.gd")
const RingShardBurstScript = preload("res://gameplay/ring_shard_burst.gd")
const FloatingTextScript = preload("res://gameplay/floating_text.gd")
const VfxLib = preload("res://gameplay/vfx.gd")

const PRAISE := [
	{"text": "Great!", "color": Color("#22C55E")},
	{"text": "Excellent!", "color": Color("#0EA5E9")},
	{"text": "Amazing!", "color": Color("#A855F7")},
	{"text": "Fantastic!", "color": Color("#EC4899")},
]


## Burst at the ring: shards, a star ring along the gap, and a praise word.
static func play(parent: Node, global_pos: Vector2, radius: float, color: Color, thickness: float, combo: int, gap_angle: float = 0.0, gap_width: float = 44.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return

	VfxLib.debug_marker(parent, global_pos, Vector2.UP, Color(1, 0.4, 0.4, 0.9))

	var shards = RingShardBurstScript.new()
	VfxLib.spawn_at(parent, global_pos, shards)
	shards.setup(global_pos, radius, 0.0, TAU, color, thickness)

	var stars = CArcStarBurstScript.new()
	VfxLib.spawn_at(parent, global_pos, stars)
	stars.setup(global_pos, radius, gap_angle, maxf(deg_to_rad(gap_width), 0.6))

	var praise: Dictionary = PRAISE[clampi(combo - 1, 0, PRAISE.size() - 1)]
	var label = FloatingTextScript.new()
	VfxLib.spawn_at(parent, global_pos + Vector2(0, -radius * 0.6), label)
	label.setup(global_pos + Vector2(0, -radius * 0.6), String(praise["text"]), praise["color"])


## The small sparkle when a ring is grabbed, so the touch feels connected.
static func pickup_spark(parent: Node, global_pos: Vector2, color: Color) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var stars = CArcStarBurstScript.new()
	VfxLib.spawn_at(parent, global_pos, stars)
	stars.setup(global_pos, 8.0, 0.0, TAU)


## A soft burst of stars for the danger zone, the danger moment.
static func danger_pulse(parent: Node, global_pos: Vector2) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var stars = CArcStarBurstScript.new()
	VfxLib.spawn_at(parent, global_pos, stars)
	stars.setup(global_pos, 26.0, 0.0, TAU)
