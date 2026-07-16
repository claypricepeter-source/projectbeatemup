extends FighterState
## A missed charge leaves the Biker exposed for more than twice as long.

const HIT_RECOVERY := 0.45
const MISS_RECOVERY := 1.15

var _timer := 0.0


func enter() -> void:
	var biker := fighter as Biker
	biker.velocity = Vector2.ZERO
	_timer = MISS_RECOVERY if biker.charge_missed else HIT_RECOVERY
	biker.last_recovery_duration = _timer
	biker.play(&"hurt" if biker.charge_missed else &"idle")


func physics_update(delta: float) -> void:
	_timer -= delta
	fighter.apply_movement(delta)
	if _timer <= 0.0:
		machine.transition("Approach")
