extends FighterState
## Brief pause before (re)engaging.

var _timer := 0.0


func enter() -> void:
	fighter.velocity = Vector2.ZERO
	fighter.play(&"idle")
	_timer = randf_range(0.3, 0.7)


func physics_update(delta: float) -> void:
	_timer -= delta
	fighter.apply_movement(delta)
	if _timer <= 0.0:
		machine.transition("Approach")
