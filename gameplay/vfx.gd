class_name Vfx
extends RefCounted
## Vfx — the one place a visual effect is allowed to be placed.
##
## Every effect in the game is spawned through here, so there is a single
## answer to "where does this particle come from". The rule is simple:
##
##     The caller always passes a GLOBAL (canvas) position.
##     Vfx converts it into the parent's local space.
##
## Getting this wrong is what put the ring-release shards in the top-left
## corner of the screen: the effect node set `global_position` to a coordinate
## that was relative to its parent, so a ring sitting at the board's origin
## placed its shards at screen (0, 0).

## Set to true to draw a marker at every spawn point. This is a development
## aid: it shows the emitter centre, the parent-local spawn position and the
## intended direction, so the markers can be compared against the particles
## that actually appear. It is off in a normal build.
const DEBUG_MARKERS := false

enum Kind {
	RING_BURST,    ## radial shards and sparks, short and fast
	CONFETTI,      ## paper chunks, up and out, then gravity
	SPARKLE,       ## small stars around a point
	COINS,         ## directed flight to a target
}

const RING_BURST_LIFETIME := 1.2
const CONFETTI_LIFETIME := 2.6
const SPARKLE_LIFETIME := 0.5
const COIN_LIFETIME := 1.1


## Spawn `effect` inside `parent` so that it appears at `global_pos`.
##
## `global_pos` is a global canvas coordinate. The effect is placed with the
## parent's inverse transform, so it lands exactly there no matter what the
## parent's scale, position or canvas layer is.
static func spawn_at(parent: Node, global_pos: Vector2, effect: Node) -> Node:
	if parent == null or not is_instance_valid(parent):
		return null
	if effect == null:
		return null
	parent.add_child(effect)
	place_at_self(effect, global_pos)
	return effect


## Place `node` at a global position, expressed in its parent's local space.
##
## Calling this twice with the same point is harmless, so an effect can be
## placed by the spawner and again by its own setup() without either of them
## fighting over the position.
static func place_at_self(node: Node, global_pos: Vector2) -> void:
	if node == null or not is_instance_valid(node):
		return
	var p := node.get_parent()
	if p == null:
		return
	node.position = to_parent_local(p, global_pos)


## Draw a development marker at a spawn point: a ring at the global centre, a
## cross at the parent-local position and an arrow for the intended velocity.
## Nothing is drawn unless DEBUG_MARKERS is on.
static func debug_marker(parent: Node, global_pos: Vector2, direction: Vector2 = Vector2.ZERO, color: Color = Color(1, 0.4, 0.4, 0.9)) -> void:
	if not DEBUG_MARKERS:
		return
	if parent == null or not is_instance_valid(parent):
		return
	var marker := Node2D.new()
	marker.name = "VfxDebugMarker"
	marker.z_index = 500
	marker.position = to_parent_local(parent, global_pos)
	parent.add_child(marker)
	marker.set_script(preload("res://gameplay/vfx_debug_marker.gd"))
	marker.set("direction", direction)
	marker.set("color", color)


## Convert a global (canvas) position into the local space of `parent`.
static func to_parent_local(parent: Node, global_pos: Vector2) -> Vector2:
	if parent is CanvasItem:
		return (parent as CanvasItem).get_global_transform().affine_inverse() * global_pos
	return global_pos


## Convert a position in `parent`'s local space into global (canvas) space.
static func to_global(parent: Node, local_pos: Vector2) -> Vector2:
	if parent is CanvasItem:
		return (parent as CanvasItem).get_global_transform() * local_pos
	return local_pos


## The global centre of a node, whichever kind it is.
##
## A Control reports the middle of its rect; a Node2D reports its own
## position, which is the point it is drawn around.
static func global_centre(node: Node) -> Vector2:
	if node == null or not is_instance_valid(node):
		return Vector2.ZERO
	if node is Control:
		return (node as Control).get_global_rect().get_center()
	if node is Node2D:
		return (node as Node2D).global_position
	return Vector2.ZERO


## A random direction spread evenly around the circle, for radial bursts.
static func radial_direction(angle: float = 0.0, spread: float = TAU) -> Vector2:
	return Vector2.from_angle(angle + randf_range(-spread * 0.5, spread * 0.5))


## A burst direction biased upward, with a little sideways drift, so paper
## scatters instead of firing as one column.
static func confetti_direction() -> Vector2:
	var angle := randf_range(PI * 0.72, PI * 2.28)   # mostly upward
	var speed := randf_range(0.72, 1.18)
	return Vector2.from_angle(angle) * speed


## The direction from a start point to a target, for directed effects.
static func direction_to(from: Vector2, to: Vector2) -> Vector2:
	var d := to - from
	if d.length_squared() < 0.0001:
		return Vector2.RIGHT
	return d.normalized()
