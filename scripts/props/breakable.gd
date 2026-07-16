class_name Breakable
extends Area2D
## Player attacks damage this prop through the normal hitbox overlap path. On
## break, its configured Pickup scene is spawned at the prop's feet.

@export var max_hp := 12
@export var pickup_scene: PackedScene

var hp := 0
var broken := false

@onready var visuals: Node2D = $Visuals
@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	hp = max_hp


func take_hit(damage: int, _source: Fighter) -> void:
	if broken:
		return
	hp = maxi(hp - damage, 0)
	if hp <= 0:
		_break_open()
	else:
		var flash := create_tween()
		visuals.modulate = Color(1.8, 1.8, 1.8, 1.0)
		flash.tween_property(visuals, "modulate", Color.WHITE, 0.1)


func _break_open() -> void:
	broken = true
	set_deferred("collision_layer", 0)
	set_deferred("monitoring", false)
	shape.set_deferred("disabled", true)
	if pickup_scene:
		_spawn_pickup.call_deferred(global_position)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visuals, "scale", Vector2(1.35, 0.2), 0.16)
	tween.tween_property(visuals, "modulate:a", 0.0, 0.16)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


func _spawn_pickup(spawn_position: Vector2) -> void:
	var pickup := pickup_scene.instantiate() as Pickup
	if pickup:
		get_parent().add_child(pickup)
		pickup.global_position = spawn_position
