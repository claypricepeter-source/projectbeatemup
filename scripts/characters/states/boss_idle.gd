extends FighterState

var _timer := 0.0


func enter() -> void:
	var boss := fighter as SlickRick
	var target := boss.target_player()
	if target and target.global_position.x != boss.global_position.x:
		boss.set_facing(int(signf(target.global_position.x - boss.global_position.x)))
	fighter.velocity = Vector2.ZERO
	fighter.play(&"idle")
	_timer = 0.45


func physics_update(delta: float) -> void:
	var boss := fighter as SlickRick
	var target := boss.target_player()
	if target and target.global_position.x != boss.global_position.x:
		boss.set_facing(int(signf(target.global_position.x - boss.global_position.x)))
	_timer -= delta
	fighter.apply_movement(delta)
	if _timer <= 0.0:
		machine.transition("Approach")
