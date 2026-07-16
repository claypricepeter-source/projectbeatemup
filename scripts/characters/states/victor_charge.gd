extends FighterState
## Phase-two charging grab. A missed pass leaves Victor open longer.

const TELEGRAPH_TIME := 0.34
const CHARGE_TIME := 0.58
const END_TIME := 1.02
const CHARGE_SPEED := 410.0

var _elapsed := 0.0
var _started := false
var _charging := false


func enter() -> void:
	var boss := fighter as Victor
	boss.last_attack_was_charge = true
	boss.charge_connected = false
	boss.charge_cooldown = 5.0
	boss.velocity = Vector2.ZERO
	boss.play(&"enrage")
	var target := boss.target_player()
	if target and target.global_position.x != boss.global_position.x:
		boss.set_facing(int(signf(target.global_position.x - boss.global_position.x)))
	_elapsed = 0.0
	_started = false
	_charging = false


func exit() -> void:
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	_elapsed += delta
	var boss := fighter as Victor
	if not _started and _elapsed >= TELEGRAPH_TIME:
		_started = true
		_charging = true
		boss.play(&"charge")
		boss.velocity = Vector2(boss.facing * CHARGE_SPEED, 0.0)
		boss.hitbox.activate(18, true)
	if _charging and _elapsed >= TELEGRAPH_TIME + CHARGE_TIME:
		_charging = false
		boss.velocity = Vector2.ZERO
		boss.hitbox.deactivate()
	if _charging:
		boss.velocity = Vector2(boss.facing * CHARGE_SPEED, 0.0)
	boss.apply_movement(delta)
	if _elapsed >= END_TIME:
		machine.transition("Recover")
