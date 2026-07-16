extends FighterState

const ACTIVE_START := 0.12
const ACTIVE_END := 0.34
const END_TIME := 0.58

var _elapsed := 0.0
var _started := false


func enter() -> void:
	var boss := fighter as Victor
	boss.last_attack_was_charge = false
	boss.velocity = Vector2.ZERO
	boss.play(&"attack")
	_elapsed = 0.0
	_started = false


func exit() -> void:
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	_elapsed += delta
	var boss := fighter as Victor
	if not _started and _elapsed >= ACTIVE_START:
		_started = true
		boss.hitbox.activate(12, true)
	if _started and _elapsed >= ACTIVE_END:
		boss.hitbox.deactivate()
	boss.apply_movement(delta)
	if _elapsed >= END_TIME:
		machine.transition("Recover")
