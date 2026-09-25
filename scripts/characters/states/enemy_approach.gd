extends FighterState
## Walks to attack range beside the player, aligning on the depth axis. SoR2
## habits: enemies flank to the far side when the near side is taken, and size
## the player up for a moment before swinging. Holds position when the
## attacker slots are full.

const ALIGN_Y := 10.0
const SIDE_REFRESH := 0.8

var _side := 1.0
var _side_timer := 0.0
var _hesitate := 0.0


func enter() -> void:
	fighter.play(&"walk")
	_side_timer = 0.0
	_hesitate = randf_range(0.12, 0.45)


func physics_update(delta: float) -> void:
	var enemy := fighter as Enemy
	var target := enemy.target_player()
	if target == null:
		machine.transition("Idle")
		return
	_side_timer -= delta
	if _side_timer <= 0.0:
		_side_timer = SIDE_REFRESH
		_side = enemy.preferred_side(target)
	var to_x := target.global_position.x - enemy.global_position.x
	if to_x != 0.0:
		enemy.set_facing(int(signf(to_x)))
	var on_side := signf(-to_x) == _side
	var in_range := on_side and absf(to_x) <= enemy.stats.attack_range \
			and absf(target.global_position.y - enemy.global_position.y) <= ALIGN_Y
	if in_range:
		enemy.velocity = Vector2.ZERO
		enemy.play(&"idle")
		enemy.apply_movement(delta)
		_hesitate -= delta
		if _hesitate <= 0.0 and enemy.attackers_count() < Enemy.MAX_ATTACKERS:
			machine.transition("Attack")
		return
	var goal := Vector2(
		target.global_position.x + _side * enemy.stats.attack_range * 0.85,
		target.global_position.y)
	# Flanking: swing wide in depth so the walk around does not pass through.
	if not on_side and absf(to_x) < enemy.stats.attack_range * 1.4:
		goal.y += 26.0 if enemy.global_position.y <= target.global_position.y else -26.0
	var diff := goal - enemy.global_position
	enemy.play(&"walk")
	enemy.velocity = diff.normalized() * enemy.move_speed if diff.length() > 4.0 else Vector2.ZERO
	enemy.apply_movement(delta)
