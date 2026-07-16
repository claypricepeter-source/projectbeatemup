extends FighterState

var _timer := 0.0


func enter() -> void:
	var boss := fighter as Victor
	boss.velocity = Vector2.ZERO
	boss.play(&"idle")
	var target := boss.target_player()
	if target and target.global_position.x != boss.global_position.x:
		boss.set_facing(int(signf(target.global_position.x - boss.global_position.x)))
	_timer = 0.35


func physics_update(delta: float) -> void:
	_timer -= delta
	fighter.apply_movement(delta)
	if _timer <= 0.0:
		machine.transition("Approach")
