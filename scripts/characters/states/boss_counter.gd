extends FighterState
## Hyper-armored retaliation after three quick hits prevents boss stun-locking.

const WINDUP := 0.16
const ACTIVE_END := 0.42
const END_TIME := 0.62

var _elapsed := 0.0
var _active := false


func enter() -> void:
	_elapsed = 0.0
	_active = false
	fighter.velocity = Vector2.ZERO
	fighter.play(&"idle")


func exit() -> void:
	var boss := fighter as SlickRick
	boss.hyper_armor = false
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	_elapsed += delta
	if not _active and _elapsed >= WINDUP:
		_active = true
		fighter.velocity = Vector2(fighter.facing * 155.0, 0)
		fighter.play(&"heavy_attack_magnetic_crush")
		fighter.hitbox.activate(10, true)
	if _active and _elapsed >= ACTIVE_END:
		fighter.velocity = Vector2.ZERO
		fighter.hitbox.deactivate()
	fighter.apply_movement(delta)
	if _elapsed >= END_TIME:
		machine.transition("Recover")
