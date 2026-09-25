class_name Hitbox
extends Area2D
## Deals hits while active. Sits under a HitboxPivot node that flips with
## facing. Attacks only connect within a Y-depth band (AGENTS.md §7.3).

enum Reach { FRONT, BOTH }

const PLAYER_HURTBOX_BIT := 2
const ENEMY_HURTBOX_BIT := 4

@export var depth_band := 24.0

var damage := 0
var knockdown := false
var source: Fighter
## Number of distinct targets hit since the last activate().
var hits_this_swing := 0

var _hit_targets: Array[Node] = []
var _default_mask := 0
var _default_position := Vector2.ZERO
var _default_size := Vector2.ZERO

@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	shape.disabled = true
	_default_mask = collision_mask
	_default_position = shape.position
	var rect := shape.shape as RectangleShape2D
	if rect:
		# Each fighter gets its own copy so reach changes never leak between
		# instances sharing the scene's sub-resource.
		rect = rect.duplicate() as RectangleShape2D
		shape.shape = rect
		_default_size = rect.size
	area_entered.connect(_on_area_entered)


func activate(new_damage: int, new_knockdown: bool, reach: Reach = Reach.FRONT) -> void:
	damage = new_damage
	knockdown = new_knockdown
	hits_this_swing = 0
	_hit_targets.clear()
	_set_reach(reach)
	shape.set_deferred("disabled", false)


func deactivate() -> void:
	shape.set_deferred("disabled", true)
	collision_mask = _default_mask


## Thrown bodies collide with their own side's hurtboxes (SoR2 throw damage).
func target_own_team(enabled: bool) -> void:
	if not enabled:
		collision_mask = _default_mask
		return
	# Only the thrown body's teammates: an enemy thrown by the player never hits
	# the player on the way past.
	collision_mask = PLAYER_HURTBOX_BIT if source is Player else ENEMY_HURTBOX_BIT


func _set_reach(reach: Reach) -> void:
	var rect := shape.shape as RectangleShape2D
	if rect == null:
		return
	if reach == Reach.BOTH:
		rect.size = Vector2(absf(_default_position.x) * 2.0 + _default_size.x, _default_size.y)
		shape.position = Vector2(0.0, _default_position.y)
	else:
		rect.size = _default_size
		shape.position = _default_position


func _physics_process(_delta: float) -> void:
	# Re-scan overlaps every active frame: back-to-back activations on the same
	# frame never re-fire area_entered, and _hit_targets keeps this idempotent.
	if shape.disabled or not monitoring:
		return
	for area in get_overlapping_areas():
		_on_area_entered(area)


func _on_area_entered(area: Area2D) -> void:
	if shape.disabled or source == null:
		return
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
	if target == source.held_by or target.held_by == source:
		return
	if absf(source.global_position.y - target.global_position.y) > depth_band:
		return
	_hit_targets.append(target)
	if target.take_hit(damage, knockdown, source):
		hits_this_swing += 1
		source.on_attack_connected(target, target.hp <= 0)
		ImpactManager.connected_hit(target, knockdown)
