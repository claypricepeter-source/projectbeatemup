extends FighterState
## Thrown through the air (SoR2). While flying, the body is a hitbox against its
## own team (16 damage + knockdown, like every SoR2 throw). Damage to the thrown
## fighter is applied on landing, then the shared Knockdown bounce takes over.
## A thrown player holding Up + Jump lands on their feet ("Land", SoR2).

const THROW_SPEED := 250.0
const THROW_POP := 250.0
const SLAM_POP := 120.0
const BODY_DAMAGE := 16

var _landed_on_feet := false


func enter() -> void:
	fighter.hitbox.deactivate()
	fighter.invulnerable = true
	fighter.on_knocked_off_feet()
	fighter.play(&"hurt")
	fighter.sprite.pause()
	fighter.set_facing(-fighter.thrown_direction)
	_landed_on_feet = false
	if fighter.thrown_is_slam:
		fighter.velocity = Vector2(fighter.thrown_direction * 90.0, 0.0)
		fighter.air_velocity = SLAM_POP
	else:
		fighter.velocity = Vector2(fighter.thrown_direction * THROW_SPEED, 0.0)
		fighter.air_velocity = THROW_POP
		fighter.hitbox.activate(BODY_DAMAGE, true, Hitbox.Reach.BOTH)
		fighter.hitbox.target_own_team(true)


func exit() -> void:
	fighter.hitbox.deactivate()
	fighter.sprite.rotation = 0.0


func physics_update(delta: float) -> void:
	var spin := -fighter.thrown_direction * 9.0 * delta
	fighter.sprite.rotation += spin
	var player := fighter as Player
	if player and player.wants_to_land():
		_landed_on_feet = true
	var landed := fighter.update_air(delta)
	fighter.apply_movement(delta)
	if not landed:
		return
	fighter.hitbox.deactivate()
	fighter.sprite.rotation = 0.0
	if _landed_on_feet and not fighter.thrown_is_slam:
		# SoR2 "Land": no damage, brief invulnerability, back in control.
		fighter.velocity = Vector2.ZERO
		fighter.end_knockdown()
		machine.transition("Idle")
		return
	_apply_landing_damage()


func _apply_landing_damage() -> void:
	var thrower := fighter.thrown_by
	fighter.invulnerable = false
	fighter.knockdown_pop_scale = 0.0
	fighter.knockdown_push_scale = 0.4
	var accepted := fighter.take_hit(fighter.thrown_damage, true, thrower if is_instance_valid(thrower) else null)
	if accepted:
		ImpactManager.connected_hit(fighter, true)
	# Armored bosses may accept damage without changing state; never leave a
	# landed body stuck in Thrown.
	if machine.current == self:
		fighter.knockdown_pop_scale = 0.0
		machine.transition("Knockdown")
