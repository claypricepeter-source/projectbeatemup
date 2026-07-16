extends FighterState
## Punish window after flurry/dash/counter; dash recharges afterward.

var _timer := 0.0


func enter() -> void:
	fighter.velocity = Vector2.ZERO
	fighter.play(&"hurt")
	_timer = 0.85


func physics_update(delta: float) -> void:
	_timer -= delta
	fighter.apply_movement(delta)
	if _timer <= 0.0:
		var boss := fighter as SlickRick
		boss.dash_ready = true
		machine.transition("Approach")
