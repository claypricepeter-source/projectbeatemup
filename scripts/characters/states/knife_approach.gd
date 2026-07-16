extends FighterState
## Knife Punk maintains a wider standoff than a Punk, then commits to a lunge.

const ALIGN_Y := 10.0
const MIN_RANGE := 66.0
const IDEAL_RANGE := 92.0


func enter() -> void:
	fighter.play(&"walk")


func physics_update(delta: float) -> void:
	var enemy := fighter as Enemy
	var target := enemy.target_player()
	if target == null:
		machine.transition("Idle")
		return
	var to_target := target.global_position - enemy.global_position
	if to_target.x != 0.0:
		enemy.set_facing(int(signf(to_target.x)))
	var aligned := absf(to_target.y) <= ALIGN_Y
	var distance_x := absf(to_target.x)
	if aligned and distance_x >= MIN_RANGE and distance_x <= enemy.stats.attack_range:
		if enemy.attackers_count() < Enemy.MAX_ATTACKERS:
			machine.transition("Attack")
		else:
			enemy.velocity = Vector2.ZERO
			enemy.play(&"idle")
		enemy.apply_movement(delta)
		return
	var side := signf(to_target.x) if to_target.x != 0.0 else float(enemy.facing)
	var goal := Vector2(target.global_position.x - side * IDEAL_RANGE, target.global_position.y)
	if distance_x < MIN_RANGE:
		goal.x = enemy.global_position.x - side * IDEAL_RANGE
	var diff := goal - enemy.global_position
	enemy.play(&"walk")
	enemy.velocity = diff.normalized() * enemy.move_speed if diff.length() > 4.0 else Vector2.ZERO
	enemy.apply_movement(delta)
