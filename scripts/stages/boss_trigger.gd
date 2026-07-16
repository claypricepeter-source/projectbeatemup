class_name BossTrigger
extends Area2D
## One-shot boss arena gate. The camera remains locked through the stage-clear
## handoff; the flow controller owns what happens after stage_cleared.

@export var boss_scene: PackedScene
@export var lock_x := 4160.0
@export var spawn_position := Vector2(4380.0, 240.0)

var activated := false
var completed := false
var boss: SlickRick

@onready var stage: Stage = get_parent().get_parent() as Stage
@onready var camera: CameraDirector = stage.get_node("Camera") as CameraDirector
@onready var entities: Node2D = stage.get_node("Entities") as Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		activate()


func activate() -> void:
	if activated or boss_scene == null:
		return
	activated = true
	set_deferred("monitoring", false)
	camera.lock(lock_x)
	_spawn_boss.call_deferred()


func _spawn_boss() -> void:
	boss = boss_scene.instantiate() as SlickRick
	entities.add_child(boss)
	boss.global_position = spawn_position
	stage.apply_bounds(boss)
	boss.died.connect(_on_boss_died, CONNECT_ONE_SHOT)


func _on_boss_died() -> void:
	completed = true
	for node in get_tree().get_nodes_in_group("boss_adds"):
		var add := node as Enemy
		if add and not add.is_dead:
			add.finish_death()
	EventBus.stage_cleared.emit()
