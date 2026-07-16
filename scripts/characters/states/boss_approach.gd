extends FighterState
## Close distance, choosing a dash from mid-range or a flurry up close.

const ALIGN_Y := 11.0
const FLURRY_RANGE := 78.0
const DASH_MIN_RANGE := 135.0
const DASH_MAX_RANGE := 330.0


func enter() -> void:
	fighter.play(&"walk")


func physics_update(delta: float) -> void:
	var boss := fighter as SlickRick
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
	if aligned and slot_available and distance_x <= FLURRY_RANGE:
		machine.transition("Attack")
		return
	if aligned and slot_available and boss.dash_ready and distance_x >= DASH_MIN_RANGE and distance_x <= DASH_MAX_RANGE:
		machine.transition("Dash")
		return
	var goal := Vector2(
		target.global_position.x - signf(diff.x) * FLURRY_RANGE * 0.85,
		target.global_position.y)
	var to_goal := goal - boss.global_position
	boss.velocity = to_goal.normalized() * boss.move_speed if to_goal.length() > 4.0 else Vector2.ZERO
	boss.play(&"walk")
	boss.apply_movement(delta)
