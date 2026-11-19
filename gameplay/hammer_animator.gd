class_name HammerAnimator
extends Node2D
## HammerAnimator (Refactored for Ring Run "Snip" Power) —
## Replaces legacy hammer visuals with a Panda-themed Bamboo Cutter slash (500ms)
## that cleanly slices a connector pin without making any puzzle unsolvable.

signal snip_completed(ring_index: int)

func play_bamboo_snip(target_pos: Vector2, ring_index: int) -> void:
	position = target_pos
	var burst := CollisionSparkBurst.new()
	get_parent().add_child(burst)
	burst.emit_burst(target_pos, Color(0.4, 0.73, 0.42), 14, 0.50)
	var tw := create_tween()
	tw.tween_interval(0.50)
	tw.tween_callback(func():
		snip_completed.emit(ring_index)
		queue_free()
	)
