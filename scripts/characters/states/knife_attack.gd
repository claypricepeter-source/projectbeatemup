extends FighterState
## Fast horizontal knife lunge. The short recovery creates the punish window.

const LUNGE_SPEED := 190.0
const LUNGE_TIME := 0.24

var _timer := 0.0
var _activated := false


func enter() -> void:
	_timer = LUNGE_TIME
	_activated = false
	fighter.velocity = Vector2(fighter.facing * LUNGE_SPEED, 0)
	fighter.play(&"attack")


func exit() -> void:
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	var enemy := fighter as Enemy
	_timer -= delta
	if not _activated and fighter.sprite.frame >= 1:
		_activated = true
		fighter.hitbox.activate(enemy.stats.damage, false)
	if _timer <= 0.0:
		fighter.velocity = Vector2.ZERO
	fighter.apply_movement(delta)
	if not fighter.sprite.is_playing():
		machine.transition("Recover")
