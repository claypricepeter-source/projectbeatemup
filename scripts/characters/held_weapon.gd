class_name HeldWeapon
extends Node2D
## Draws the player's current weapon at hand height. The art has no weapon
## frames, so the weapon is drawn procedurally and swung by attack states.

var kind: StringName = &""
var swing := 0.0
var facing := 1


func show_weapon(weapon_kind: StringName) -> void:
	kind = weapon_kind
	visible = weapon_kind != &""
	queue_redraw()


func set_pose(new_facing: int, new_swing: float) -> void:
	facing = new_facing
	swing = new_swing
	position = Vector2(22.0 * facing, -86.0)
	queue_redraw()


func _draw() -> void:
	if kind == &"":
		return
	# swing 0 = held low and forward, 1 = fully extended strike.
	var angle := lerpf(1.1, -0.15, clampf(swing, 0.0, 1.0))
	if facing < 0:
		angle = PI - angle
	Weapons.draw_weapon(self, kind, angle)
