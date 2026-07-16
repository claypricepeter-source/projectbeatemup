extends FighterState

var _timer := 0.0


func enter() -> void:
	var boss := fighter as Marta
	boss.velocity = Vector2.ZERO
	boss.play(&"hurt")
	_timer = 1.0 if boss.last_attack_was_sweep else 0.72


func physics_update(delta: float) -> void:
	_timer -= delta
	fighter.apply_movement(delta)
	if _timer <= 0.0:
		var boss := fighter as Marta
		boss.hyper_armor = false
		machine.transition("Approach")
