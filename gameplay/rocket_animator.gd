class_name RocketAnimator
extends Node2D
## RocketAnimator (Refactored for Ring Run "Pop" Power) —
## Replaces legacy rocket visuals with a Panda-themed Bubble Pop expansion (500ms)
## that inflates and pops a target ring into soft bamboo-mist droplets.

signal pop_completed(ring_index: int)

func play_bubble_pop(target_pos: Vector2, ring_index: int) -> void:
	position = target_pos
	var burst := CollisionSparkBurst.new()
	get_parent().add_child(burst)
	burst.emit_burst(target_pos, Color(0.55, 0.88, 0.98), 18, 0.50)
	var tw := create_tween()
	tw.tween_interval(0.50)
	tw.tween_callback(func():
		pop_completed.emit(ring_index)
		queue_free()
	)
