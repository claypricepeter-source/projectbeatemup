extends FighterState
## Phase two compresses the same three-hit string and raises each strike's damage.

var _strike_times: Array[float] = []
var _damages: Array[int] = []
var _end_time := 0.0
var _elapsed := 0.0
var _strike := 0
var _active_until := 0.0


func enter() -> void:
	var boss := fighter as Victor
	boss.last_attack_was_charge = false
	if boss.phase_two:
		_strike_times = [0.12, 0.32, 0.52]
		_damages = [10, 10, 14]
		_end_time = 0.76
	else:
		_strike_times = [0.16, 0.42, 0.68]
		_damages = [8, 8, 12]
		_end_time = 0.96
	_elapsed = 0.0
	_strike = 0
	_active_until = 0.0
	boss.velocity = Vector2.ZERO
	boss.play(&"attack")


func exit() -> void:
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	_elapsed += delta
	var boss := fighter as Victor
	if _strike < _strike_times.size() and _elapsed >= _strike_times[_strike]:
		boss.sprite.frame = 0
		boss.play(&"attack")
		boss.hitbox.activate(_damages[_strike], _strike == _strike_times.size() - 1)
		_active_until = _elapsed + 0.1
		_strike += 1
	if _active_until > 0.0 and _elapsed >= _active_until:
		boss.hitbox.deactivate()
		_active_until = 0.0
	boss.apply_movement(delta)
	if _elapsed >= _end_time:
		machine.transition("Recover")
