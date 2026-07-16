extends FighterState
## Three rapid knife hit windows; the final slash knocks down.

const STRIKE_TIMES: Array[float] = [0.12, 0.38, 0.64]
const DAMAGES: Array[int] = [6, 6, 10]
const END_TIME := 0.92

var _elapsed := 0.0
var _strike := 0
var _active_until := 0.0


func enter() -> void:
	_elapsed = 0.0
	_strike = 0
	_active_until = 0.0
	fighter.velocity = Vector2.ZERO
	fighter.play(&"attack")


func exit() -> void:
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	_elapsed += delta
	if _strike < STRIKE_TIMES.size() and _elapsed >= STRIKE_TIMES[_strike]:
		fighter.sprite.frame = 0
		fighter.play(&"attack")
		fighter.hitbox.activate(DAMAGES[_strike], _strike == STRIKE_TIMES.size() - 1)
		_active_until = _elapsed + 0.1
		_strike += 1
	if _active_until > 0.0 and _elapsed >= _active_until:
		fighter.hitbox.deactivate()
		_active_until = 0.0
	fighter.apply_movement(delta)
	if _elapsed >= END_TIME:
		machine.transition("Recover")
