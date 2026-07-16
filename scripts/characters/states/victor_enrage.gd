extends FighterState

const ENRAGE_TIME := 0.9
var _timer := 0.0


func enter() -> void:
	var boss := fighter as Victor
	boss.begin_phase_two()
	boss.invulnerable = true
	boss.velocity = Vector2.ZERO
	boss.play(&"enrage")
	_timer = ENRAGE_TIME


func exit() -> void:
	var boss := fighter as Victor
	boss.invulnerable = false
	boss.hyper_armor = false


func physics_update(delta: float) -> void:
	_timer -= delta
	fighter.apply_movement(delta)
	if _timer <= 0.0:
		machine.transition("Approach")
