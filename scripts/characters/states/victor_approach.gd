extends FighterState

const ALIGN_Y := 11.0
const CHARGE_MIN_RANGE := 135.0
const CHARGE_MAX_RANGE := 390.0


func enter() -> void:
	fighter.play(&"walk")


func physics_update(delta: float) -> void:
	var boss := fighter as Victor
	var target := boss.target_player()
	if target == null:
		machine.transition("Idle")
		return
	var diff := target.global_position - boss.global_position
	if diff.x != 0.0:
		boss.set_facing(int(signf(diff.x)))
	var aligned := absf(diff.y) <= ALIGN_Y
	var distance_x := absf(diff.x)
	var slot_available := boss.attackers_count() < Enemy.MAX_ATTACKERS
	if boss.phase_two and aligned and slot_available and boss.charge_cooldown <= 0.0 \
			and distance_x >= CHARGE_MIN_RANGE and distance_x <= CHARGE_MAX_RANGE:
		machine.transition("Charge")
		return
	if aligned and slot_available and distance_x <= boss.stats.attack_range:
		machine.transition("Attack")
		return
	var goal := Vector2(
		target.global_position.x - signf(diff.x) * boss.stats.attack_range * 0.82,
		target.global_position.y)
	var to_goal := goal - boss.global_position
	boss.velocity = to_goal.normalized() * boss.move_speed if to_goal.length() > 4.0 else Vector2.ZERO
	boss.play(&"walk")
	boss.apply_movement(delta)
