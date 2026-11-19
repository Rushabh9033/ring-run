class_name TutorialHand
extends Node2D
## TutorialHand — Animated guide hand used during the first 3 onboarding puzzles
## and when activating the "Panda Eye" power (1.2s smooth arc motion).

var radius_px: float = 80.0
var from_angle: float = 0.0
var to_angle: float = 0.0
var elapsed: float = 0.0
var duration: float = 1.2
var active: bool = false

func play_arc_hint(ring_radius: float, start_rad: float, target_rad: float) -> void:
	radius_px = ring_radius
	from_angle = start_rad
	to_angle = target_rad
	elapsed = 0.0
	active = true
	visible = true

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	var t := clampf(elapsed / duration, 0.0, 1.0)
	var smooth_t := t * t * (3.0 - 2.0 * t)
	var cur_a := lerpf(from_angle, to_angle, smooth_t)
	position = Vector2(cos(cur_a), sin(cur_a)) * radius_px
	queue_redraw()
	if elapsed >= duration:
		active = false
		visible = false

func _draw() -> void:
	if not active:
		return
	draw_circle(Vector2.ZERO, 16.0, Color(0.18, 0.49, 0.20, 0.85))
	draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.99, 0.96))
