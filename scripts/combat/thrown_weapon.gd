class_name ThrownWeapon
extends Node2D
## A weapon thrown along the thrower's lane (SoR2 back-attack while armed).
## Hits the first opposing fighter in the ±12 px depth band for 8 damage, then
## falls to the ground as a pickup with one fewer drop remaining.

const SPEED := 420.0
const HEIGHT := 70.0
const MAX_DISTANCE := 420.0
const DEPTH_BAND := 12.0

var kind: StringName = Weapons.KNIFE
var drops_left := Weapons.MAX_DROPS
var thrower: Fighter
var direction := 1
var _travelled := 0.0
var _spin := 0.0


static func launch(from: Fighter, weapon_kind: StringName, remaining_drops: int) -> void:
	var weapon := ThrownWeapon.new()
	weapon.kind = weapon_kind
	weapon.drops_left = remaining_drops
	weapon.thrower = from
	weapon.direction = from.facing
	from.get_parent().add_child(weapon)
	weapon.global_position = from.global_position + Vector2(from.facing * 30.0, 0.0)


func _physics_process(delta: float) -> void:
	var step := SPEED * delta
	global_position.x += direction * step
	_travelled += step
	_spin += delta * 22.0
	queue_redraw()
	var target := _find_target()
	if target:
		if target.take_hit(Weapons.THROWN_DAMAGE, false, thrower if is_instance_valid(thrower) else null):
			ImpactManager.connected_hit(target, false)
			if is_instance_valid(thrower):
				thrower.on_attack_connected(target, target.hp <= 0)
		_fall()
		return
	if _travelled >= MAX_DISTANCE:
		_fall()


func _find_target() -> Fighter:
	var group := &"enemies" if thrower is Player else &"players"
	for node in get_tree().get_nodes_in_group(group):
		var fighter := node as Fighter
		if fighter == null or fighter.is_dead or fighter.invulnerable:
			continue
		if absf(fighter.global_position.y - global_position.y) > DEPTH_BAND:
			continue
		if absf(fighter.global_position.x - global_position.x) <= 18.0:
			return fighter
	return null


func _fall() -> void:
	if is_instance_valid(thrower):
		global_position.x = clampf(global_position.x, thrower.walk_min_x, thrower.walk_max_x)
	WeaponPickup.spawn(get_parent(), kind, drops_left - 1, global_position)
	queue_free()


func _draw() -> void:
	draw_set_transform(Vector2(0.0, -HEIGHT), 0.0, Vector2.ONE)
	Weapons.draw_weapon(self, kind, _spin * direction)
