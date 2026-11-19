extends CanvasLayer
class_name CoinFlyAnimation

var _arrived_count: int = 0
var _total_coins: int = 0
var _is_completed: bool = false
var _on_all_arrived_cb: Callable = Callable()

static func play_fly_coins(
	tree_node: Node,
	from_global: Vector2,
	to_global: Vector2,
	coin_count: int = 8,
	audio_service: Node = null,
	wallet_control: Control = null,
	on_all_arrived: Callable = Callable(),
	on_coin_hit: Callable = Callable()
) -> CoinFlyAnimation:
	if tree_node == null or not is_instance_valid(tree_node) or not tree_node.is_inside_tree():
		if on_all_arrived.is_valid():
			on_all_arrived.call()
		return null
		
	var anim_layer := CoinFlyAnimation.new()
	anim_layer.layer = 150 # High z-order above modals and game HUD
	var tree := tree_node.get_tree()
	if tree and tree.root:
		tree.root.add_child(anim_layer)
	else:
		tree_node.add_child(anim_layer)
		
	anim_layer._launch(from_global, to_global, coin_count, audio_service, wallet_control, on_all_arrived, on_coin_hit)
	return anim_layer

func _finish_all() -> void:
	if _is_completed: return
	_is_completed = true
	if _on_all_arrived_cb.is_valid():
		_on_all_arrived_cb.call()
	queue_free()

func _launch(
	from_global: Vector2,
	to_global: Vector2,
	coin_count: int,
	audio_service: Node,
	wallet_control: Control,
	on_all_arrived: Callable,
	on_coin_hit: Callable
) -> void:
	var coin_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/ui/bamboo_zen/hud/coin_icon.png"):
		coin_tex = load("res://assets/ui/bamboo_zen/hud/coin_icon.png")
	elif ResourceLoader.exists("res://art/coin.png"):
		coin_tex = load("res://art/coin.png")
		
	_arrived_count = 0
	_total_coins = maxi(1, coin_count)
	_is_completed = false
	_on_all_arrived_cb = on_all_arrived
	
	# Master safety timer: ensures completion is guaranteed to trigger even if interrupted
	var pop_dur: float = 0.20
	var flight_dur: float = 0.40
	var max_dur := pop_dur + (0.05 * float(_total_coins)) + flight_dur + 0.6
	var safety_tw := create_tween()
	safety_tw.tween_interval(max_dur)
	safety_tw.tween_callback(_finish_all)
	
	for i in range(_total_coins):
		var coin := TextureRect.new()
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin.texture = coin_tex
		var coin_size := Vector2(40, 40)
		coin.custom_minimum_size = coin_size
		coin.size = coin_size
		coin.pivot_offset = coin_size * 0.5
		coin.position = from_global - coin_size * 0.5
		coin.scale = Vector2(0.2, 0.2)
		coin.modulate.a = 0.0
		add_child(coin)
		
		# 1. Radial explosion burst outwards
		var angle: float = (float(i) / float(_total_coins)) * TAU + randf_range(-0.3, 0.3)
		var burst_dist: float = randf_range(45.0, 95.0)
		var burst_pos: Vector2 = from_global + Vector2(cos(angle), sin(angle)) * burst_dist
		
		# Mid-flight Bezier curve control points
		var arc_lift: float = randf_range(-140.0, -70.0)
		var mid_ctrl: Vector2 = from_global.lerp(to_global, 0.45) + Vector2(randf_range(-80.0, 80.0), arc_lift)
		
		var tw := create_tween()
		
		# Phase A: Pop in & burst
		tw.tween_property(coin, "position", burst_pos - coin_size * 0.5, pop_dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(coin, "scale", Vector2(1.15, 1.15), pop_dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(coin, "modulate:a", 1.0, 0.10)
		
		# Phase B: Curved flight toward wallet
		var flight_delay: float = 0.04 * float(i)
		tw.chain().tween_interval(flight_delay)
		
		# Animate Bezier arc using tween_method
		var flight_step := func(t: float) -> void:
			var p0: Vector2 = burst_pos
			var p1: Vector2 = mid_ctrl
			var p2: Vector2 = to_global
			# Quadratic Bezier
			var cur_pos: Vector2 = (1.0 - t) * (1.0 - t) * p0 + 2.0 * (1.0 - t) * t * p1 + t * t * p2
			if is_instance_valid(coin):
				coin.position = cur_pos - coin_size * 0.5
				coin.rotation += 0.25
		
		tw.chain().tween_method(flight_step, 0.0, 1.0, flight_dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(coin, "scale", Vector2(0.85, 0.85), flight_dur)
		
		# Phase C: Impact on wallet
		var coin_idx: int = i
		var impact_callback := func() -> void:
			if is_instance_valid(coin):
				coin.queue_free()
				
			# Chime sound
			if audio_service:
				if audio_service.has_method("play_coin_chime"):
					audio_service.play_coin_chime(coin_idx)
				elif audio_service.has_method("play_ui_tap"):
					audio_service.play_ui_tap()
					
			# Pulse wallet target
			if is_instance_valid(wallet_control):
				wallet_control.pivot_offset = wallet_control.size * 0.5
				var p_tw := wallet_control.create_tween()
				p_tw.tween_property(wallet_control, "scale", Vector2(1.22, 1.22), 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				p_tw.tween_property(wallet_control, "scale", Vector2.ONE, 0.10)
				
			_spawn_hit_spark(to_global)
			
			if on_coin_hit.is_valid():
				on_coin_hit.call(coin_idx, _total_coins)
			
			_arrived_count += 1
			if _arrived_count >= _total_coins:
				_finish_all()
		
		tw.chain().tween_callback(impact_callback)

func _spawn_hit_spark(pos: Vector2) -> void:
	var spark := Node2D.new()
	spark.position = pos
	add_child(spark)
	
	var tw := create_tween()
	var spark_color := Color("#FFE600")
	
	# Mini procedural starburst
	var draw_node := _SparkDraw.new()
	draw_node.color = spark_color
	spark.add_child(draw_node)
	
	tw.tween_property(draw_node, "radius", 24.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(draw_node, "alpha", 0.0, 0.18)
	tw.tween_callback(spark.queue_free)

class _SparkDraw extends Node2D:
	var radius: float = 4.0
	var alpha: float = 1.0
	var color: Color = Color("#FFE600")
	
	func _process(_delta: float) -> void:
		queue_redraw()
		
	func _draw() -> void:
		if alpha <= 0.01: return
		var col = color
		col.a = alpha
		for k in 6:
			var ang := (float(k) / 6.0) * TAU
			var p1 := Vector2(cos(ang), sin(ang)) * (radius * 0.3)
			var p2 := Vector2(cos(ang), sin(ang)) * radius
			draw_line(p1, p2, col, 2.2)
		draw_circle(Vector2.ZERO, radius * 0.35, Color(1, 1, 1, alpha * 0.8))
