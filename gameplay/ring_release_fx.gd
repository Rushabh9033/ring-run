class_name RingReleaseFX
extends RefCounted
## RingReleaseFX — the celebration that plays when a ring comes off the board.
##
## A ring release is three things at once: the ring itself falls away, the
## tube shatters into bamboo shards, and a ring of stars pops out along the
## gap the ring was pointing at. A praise word floats up on top of it.

const CArcStarBurstScript = preload("res://gameplay/c_arc_star_burst.gd")
const RingShardBurstScript = preload("res://gameplay/ring_shard_burst.gd")
const FloatingTextScript = preload("res://gameplay/floating_text.gd")

const PRAISE := [
	{"text": "Great!", "color": Color("#22C55E")},
	{"text": "Excellent!", "color": Color("#0EA5E9")},
	{"text": "Amazing!", "color": Color("#A855F7")},
	{"text": "Fantastic!", "color": Color("#EC4899")},
]


## Burst at the ring: shards, a star ring along the gap, and a praise word.
static func play(parent: Node, pos: Vector2, radius: float, color: Color, thickness: float, combo: int, gap_angle: float = 0.0, gap_width: float = 44.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return

	var shards = RingShardBurstScript.new()
	parent.add_child(shards)
	shards.setup(pos, radius, 0.0, TAU, color, thickness)

	var stars = CArcStarBurstScript.new()
	parent.add_child(stars)
	stars.setup(pos, radius, gap_angle, maxf(deg_to_rad(gap_width), 0.6))

	var praise: Dictionary = PRAISE[clampi(combo - 1, 0, PRAISE.size() - 1)]
	var label = FloatingTextScript.new()
	parent.add_child(label)
	label.setup(pos + Vector2(0, -radius * 0.6), String(praise["text"]), praise["color"])


## The small sparkle when a ring is grabbed, so the touch feels connected.
static func pickup_spark(parent: Node, pos: Vector2, color: Color) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var stars = CArcStarBurstScript.new()
	parent.add_child(stars)
	stars.setup(pos, 8.0, 0.0, TAU)


## A soft burst of stars for the danger zone, the danger moment.
static func danger_pulse(parent: Node, pos: Vector2) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var stars = CArcStarBurstScript.new()
	parent.add_child(stars)
	stars.setup(pos, 26.0, 0.0, TAU)
