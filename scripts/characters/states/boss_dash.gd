extends FighterState
## Brief tell followed by a fast horizontal knife charge and punishable stop.

const TELEGRAPH_TIME := 0.3
const DASH_TIME := 0.42
const DASH_SPEED := 330.0

var _elapsed := 0.0
var _active := false


func enter() -> void:
	var boss := fighter as SlickRick
	boss.dash_ready = false
	_elapsed = 0.0
	_active = false
	fighter.velocity = Vector2.ZERO
	fighter.play(&"idle")


func exit() -> void:
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	_elapsed += delta
	if not _active:
		var boss := fighter as SlickRick
		var target := boss.target_player()
		if target and target.global_position.x != boss.global_position.x:
			boss.set_facing(int(signf(target.global_position.x - boss.global_position.x)))
	if not _active and _elapsed >= TELEGRAPH_TIME:
		_active = true
		fighter.velocity = Vector2(fighter.facing * DASH_SPEED, 0)
		fighter.play(&"attack")
		fighter.hitbox.activate(12, true)
	if _active and _elapsed >= TELEGRAPH_TIME + DASH_TIME:
		fighter.velocity = Vector2.ZERO
		fighter.hitbox.deactivate()
	fighter.apply_movement(delta)
	if _elapsed >= TELEGRAPH_TIME + DASH_TIME + 0.12:
		machine.transition("Recover")
