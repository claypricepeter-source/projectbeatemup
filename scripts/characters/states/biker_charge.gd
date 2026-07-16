extends FighterState
## Stationary telegraph followed by a lane-locked horizontal charge.

const TELEGRAPH_TIME := 0.4
const CHARGE_TIME := 0.72
const END_TIME := 1.18
const CHARGE_SPEED := 360.0

var _elapsed := 0.0
var _started := false
var _charging := false


func enter() -> void:
	var biker := fighter as Biker
	biker.charge_connected = false
	biker.charge_missed = false
	biker.charge_start_x = biker.global_position.x
	_elapsed = 0.0
	_started = false
	_charging = false
	biker.velocity = Vector2.ZERO
	var target := biker.target_player()
	if target and target.global_position.x != biker.global_position.x:
		biker.set_facing(int(signf(target.global_position.x - biker.global_position.x)))
	biker.sprite.play(&"charge")
	biker.sprite.pause()
	biker.sprite.frame = 0


func exit() -> void:
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	_elapsed += delta
	var biker := fighter as Biker
	if not _started and _elapsed >= TELEGRAPH_TIME:
		_started = true
		_charging = true
		biker.sprite.play(&"charge")
		biker.velocity = Vector2(biker.facing * CHARGE_SPEED, 0.0)
		biker.hitbox.activate(biker.stats.damage, true)
	if _charging and _elapsed >= TELEGRAPH_TIME + CHARGE_TIME:
		_charging = false
		biker.velocity = Vector2.ZERO
		biker.hitbox.deactivate()
	if _charging:
		biker.velocity = Vector2(biker.facing * CHARGE_SPEED, 0.0)
	biker.apply_movement(delta)
	if _elapsed >= END_TIME:
		biker.charge_missed = not biker.charge_connected
		biker.last_charge_distance = absf(biker.global_position.x - biker.charge_start_x)
		machine.transition("Recover")
