class_name WaveTrigger
extends Area2D
## One-shot stage trigger: lock the camera, spawn a WaveData lineup, and unlock
## only after every spawned enemy has emitted died.

@export var wave_data: WaveData
@export var lock_x := 320.0

var activated := false
var cleared := false
var alive_count := 0
var finished_spawning := false

@onready var stage: Stage = get_parent().get_parent() as Stage
@onready var camera: CameraDirector = stage.get_node("Camera") as CameraDirector
@onready var entities: Node2D = stage.get_node("Entities") as Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		activate()


func activate() -> void:
	if activated or wave_data == null or not wave_data.is_valid():
		return
	activated = true
	set_deferred("monitoring", false)
	camera.lock(lock_x)
	_spawn_wave.call_deferred()


func _spawn_wave() -> void:
	for index in wave_data.enemy_scenes.size():
		var enemy := wave_data.enemy_scenes[index].instantiate() as Enemy
		if enemy == null:
			continue
		entities.add_child(enemy)
		enemy.global_position = wave_data.spawn_positions[index]
		stage.apply_bounds(enemy)
		enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)
		alive_count += 1
		if wave_data.spawn_delay > 0.0 and index < wave_data.enemy_scenes.size() - 1:
			await get_tree().create_timer(wave_data.spawn_delay).timeout
	finished_spawning = true
	_try_clear()


func _on_enemy_died() -> void:
	alive_count = maxi(alive_count - 1, 0)
	_try_clear()


func _try_clear() -> void:
	if cleared or not finished_spawning or alive_count > 0:
		return
	cleared = true
	camera.unlock()
	EventBus.wave_cleared.emit()
