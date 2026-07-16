extends FighterState
## Shared hitstun state (player and enemies): 0.3s interrupt, then back to Idle.

var _timer := 0.0


func enter() -> void:
	fighter.hitbox.deactivate()
	fighter.velocity = Vector2.ZERO
	fighter.play(&"hurt")
	_timer = 0.3


func physics_update(delta: float) -> void:
	_timer -= delta
	fighter.apply_movement(delta)
	if _timer <= 0.0:
		machine.transition("Idle")
