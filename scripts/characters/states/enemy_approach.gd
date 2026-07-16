extends FighterState
## Walks to attack range beside the player, aligning on the depth axis.
## Holds position when the attacker slots are full.

const ALIGN_Y := 10.0


func enter() -> void:
	fighter.play(&"walk")


func physics_update(delta: float) -> void:
	var enemy := fighter as Enemy
	var target := enemy.target_player()
	if target == null:
		machine.transition("Idle")
		return
	var to_x := target.global_position.x - enemy.global_position.x
	if to_x != 0.0:
		enemy.set_facing(int(signf(to_x)))
	var in_range := absf(to_x) <= enemy.stats.attack_range \
			and absf(target.global_position.y - enemy.global_position.y) <= ALIGN_Y
	if in_range:
		if enemy.attackers_count() < Enemy.MAX_ATTACKERS:
			machine.transition("Attack")
		else:
			enemy.velocity = Vector2.ZERO
			enemy.play(&"idle")
			enemy.apply_movement(delta)
		return
	var goal := Vector2(
		target.global_position.x - signf(to_x) * enemy.stats.attack_range * 0.9,
		target.global_position.y)
	var diff := goal - enemy.global_position
	enemy.play(&"walk")
	enemy.velocity = diff.normalized() * enemy.move_speed if diff.length() > 4.0 else Vector2.ZERO
	enemy.apply_movement(delta)
