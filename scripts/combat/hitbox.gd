class_name Hitbox
extends Area2D
## Deals hits while active. Sits under a HitboxPivot node that flips with
## facing. Attacks only connect within a Y-depth band (AGENTS.md §7.3).

@export var depth_band := 24.0

var damage := 0
var knockdown := false
var source: Fighter

var _hit_targets: Array[Node] = []

@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	shape.disabled = true
	area_entered.connect(_on_area_entered)


func activate(new_damage: int, new_knockdown: bool) -> void:
	damage = new_damage
	knockdown = new_knockdown
	_hit_targets.clear()
	shape.set_deferred("disabled", false)


func deactivate() -> void:
	shape.set_deferred("disabled", true)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("breakables"):
		if area in _hit_targets:
			return
		if absf(source.global_position.y - area.global_position.y) > depth_band:
			return
		_hit_targets.append(area)
		area.call("take_hit", damage, source)
		return
	var hurtbox := area as Hurtbox
	if hurtbox == null:
		return
	var target := hurtbox.fighter
	if target == null or target == source or target in _hit_targets:
		return
	if absf(source.global_position.y - target.global_position.y) > depth_band:
		return
	_hit_targets.append(target)
	target.take_hit(damage, knockdown, source)
