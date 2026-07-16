extends FighterState
## Amber lane marker gives the player time to move in Y before the crate swings.

const TELEGRAPH_TIME := 0.78
const ACTIVE_TIME := 0.30
const END_TIME := 1.45

var _elapsed := 0.0
var _active := false
var _started := false


func enter() -> void:
	var boss := fighter as Marta
	boss.last_attack_was_sweep = true
	boss.sweep_cooldown = Marta.SWEEP_COOLDOWN
	boss.velocity = Vector2.ZERO
	boss.sprite.play(&"attack")
	boss.sprite.pause()
	boss.sprite.frame = 0
	boss.set_lane_warning(true, false)
	_elapsed = 0.0
	_active = false
	_started = false


func exit() -> void:
	var boss := fighter as Marta
	boss.sweep_hitbox.deactivate()
	boss.set_lane_warning(false, false)


func physics_update(delta: float) -> void:
	_elapsed += delta
	var boss := fighter as Marta
	if not _started and _elapsed >= TELEGRAPH_TIME:
		_started = true
		_active = true
		boss.sprite.play(&"attack")
		boss.set_lane_warning(true, true)
		boss.sweep_hitbox.activate(boss.stats.damage + 4, true)
	if _active and _elapsed >= TELEGRAPH_TIME + ACTIVE_TIME:
		_active = false
		boss.sweep_hitbox.deactivate()
		boss.set_lane_warning(false, false)
	boss.apply_movement(delta)
	if _elapsed >= END_TIME:
		machine.transition("Recover")
