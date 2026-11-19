extends Control

var board_mode: bool = false
var _shader_mat: ShaderMaterial = null
var _bg_rect: ColorRect = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	
	# Instantiate full-rect ColorRect with pistachio parchment shader
	_bg_rect = ColorRect.new()
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_rect.offset_left = 0.0
	_bg_rect.offset_top = 0.0
	_bg_rect.offset_right = 0.0
	_bg_rect.offset_bottom = 0.0
	
	var shader = load("res://shaders/pistachio_bg.gdshader")
	if shader:
		_shader_mat = ShaderMaterial.new()
		_shader_mat.shader = shader
		_bg_rect.material = _shader_mat
	else:
		_bg_rect.color = Color("EAF2E8")
		
	add_child(_bg_rect)
