extends Node
## Windowed capture of key SoR2 moments for visual review (not headless).
##   godot --path . res://tests/visual_capture.tscn -- <output_dir>

const STAGE := preload("res://scenes/stages/stage_1.tscn")
const PUNK := preload("res://scenes/characters/enemies/punk.tscn")
const KNIFE_PUNK := preload("res://scenes/characters/enemies/knife_punk.tscn")

var out_dir := "user://captures"
var stage: Stage
var player: Player


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	stage = STAGE.instantiate() as Stage
	add_child(stage)
	player = stage.get_node("Entities/Player") as Player
	await _wait(0.6)
	var x := player.global_position.x
	var y := player.global_position.y
	var a := _spawn(PUNK, Vector2(x + 90.0, y))
	var b := _spawn(KNIFE_PUNK, Vector2(x - 110.0, y + 12.0))
	a.set_facing(-1)
	await _wait(0.3)
	await _capture("01_hud_idle")
	# Jab into the punk so the enemy bar appears.
	player.global_position.x = a.global_position.x - 60.0
	for i in 3:
		await _tap(&"attack_p1")
		await _wait(0.16)
	await _capture("02_combo_enemy_bar")
	await _wait(1.2)
	# Grab.
	a.global_position = Vector2(player.global_position.x + 50.0, player.global_position.y)
	a.set_facing(-1)
	Input.action_press(&"move_right_p1")
	await _wait(0.3)
	Input.action_release(&"move_right_p1")
	await _capture("03_grab")
	Input.action_press(&"move_left_p1")
	await _tap(&"attack_p1")
	Input.action_release(&"move_left_p1")
	await _wait(0.35)
	await _capture("04_back_throw")
	await _wait(1.5)
	await _tap(&"special_p1")
	await _wait(0.2)
	await _capture("05_defensive_special")
	await _wait(1.0)
	player.equip_weapon(&"pipe", 3)
	await _wait(0.2)
	await _tap(&"attack_p1")
	await _wait(0.12)
	await _capture("06_pipe_swing")
	WeaponPickup.spawn(stage.get_node("Entities"), &"knife", 3, player.global_position + Vector2(40.0, 6.0))
	await _wait(0.3)
	await _capture("07_weapon_on_ground")
	get_tree().quit()


func _spawn(scene: PackedScene, pos: Vector2) -> Enemy:
	var enemy := scene.instantiate() as Enemy
	stage.get_node("Entities").add_child(enemy)
	enemy.global_position = pos
	stage.apply_bounds(enemy)
	enemy.stats.damage = 0
	return enemy


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(out_dir.path_join(file_name + ".png"))
	print("captured ", file_name)
