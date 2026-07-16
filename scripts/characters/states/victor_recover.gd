extends FighterState

var _timer := 0.0


func enter() -> void:
	var boss := fighter as Victor
	boss.velocity = Vector2.ZERO
	boss.play(&"hurt")
	_timer = 1.0 if boss.last_attack_was_charge and not boss.charge_connected else 0.62


func physics_update(delta: float) -> void:
	_timer -= delta
	fighter.apply_movement(delta)
	if _timer <= 0.0:
		var boss := fighter as Victor
		boss.hyper_armor = false
		machine.transition("Approach")
