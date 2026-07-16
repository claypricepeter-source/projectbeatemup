extends FighterState
## Third-hit anti-stunlock response: a quick armored hook spin.

const ACTIVE_START := 0.14
const ACTIVE_END := 0.36
const END_TIME := 0.62

var _elapsed := 0.0
var _started := false


func enter() -> void:
	var boss := fighter as Marta
	boss.last_attack_was_sweep = true
	boss.velocity = Vector2.ZERO
	boss.play(&"attack")
	boss.set_lane_warning(true, false)
	_elapsed = 0.0
	_started = false


func exit() -> void:
	var boss := fighter as Marta
	boss.sweep_hitbox.deactivate()
	boss.set_lane_warning(false, false)


func physics_update(delta: float) -> void:
	_elapsed += delta
	var boss := fighter as Marta
	if not _started and _elapsed >= ACTIVE_START:
		_started = true
		boss.set_lane_warning(true, true)
		boss.sweep_hitbox.activate(10, true)
	if _started and _elapsed >= ACTIVE_END:
		boss.sweep_hitbox.deactivate()
		boss.set_lane_warning(false, false)
	boss.apply_movement(delta)
	if _elapsed >= END_TIME:
		machine.transition("Recover")
