class_name ChainParallax
extends Node2D
## Foreground chain strip. Moving slightly faster than the camera sells the chains
## as the closest layer while keeping them in the world below the HUD.

const CHAIN_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_2/chain_foreground.png")

@export var stage_width := 5120.0
@export_range(0.0, 0.5, 0.01) var extra_scroll := 0.18
@export var vertical_offset := -28.0

var _camera: Camera2D


func _ready() -> void:
	z_as_relative = false
	z_index = 20
	queue_redraw()


func _process(_delta: float) -> void:
	if not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_2d()
	if is_instance_valid(_camera):
		position.x = -roundf(_camera.global_position.x * extra_scroll)


func _draw() -> void:
	var strip_width := float(CHAIN_TEXTURE.get_width())
	var strip_x := -strip_width
	while strip_x < stage_width + strip_width:
		draw_texture(CHAIN_TEXTURE, Vector2(strip_x, vertical_offset), Color(0.82, 0.86, 0.72, 0.82))
		strip_x += strip_width
