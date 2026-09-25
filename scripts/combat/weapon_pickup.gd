class_name WeaponPickup
extends Node2D
## A weapon lying on the ground. Picked up with the attack button (SoR2). The
## node lives in the stage's y-sorted Entities layer at ground position.

var kind: StringName = Weapons.PIPE
## Remaining drops before the weapon vanishes (SoR2: three drops).
var drops_left := Weapons.MAX_DROPS
var _age := 0.0


static func spawn(parent: Node, weapon_kind: StringName, remaining_drops: int, ground_position: Vector2) -> WeaponPickup:
	if remaining_drops <= 0 or parent == null:
		return null
	var pickup := WeaponPickup.new()
	pickup.kind = weapon_kind
	pickup.drops_left = remaining_drops
	parent.add_child(pickup)
	pickup.global_position = ground_position
	return pickup


func _ready() -> void:
	add_to_group(&"weapons")
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	# Brief glint so dropped weapons read against busy backgrounds.
	if int(_age * 4.0) % 6 == 0:
		modulate = Color(1.5, 1.5, 1.5)
	else:
		modulate = Color.WHITE


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 16.0, Color(0.0, 0.0, 0.0, 0.35))
	# Ground weapons are drawn larger than held ones so they read at a glance.
	draw_set_transform(Vector2(-16.0, -4.0), 0.0, Vector2(1.6, 1.6))
	Weapons.draw_weapon(self, kind, -0.12)
