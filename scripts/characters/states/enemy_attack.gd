extends FighterState
## Single telegraphed swing; hitbox active from frame 1 to the end.

var _activated := false


func enter() -> void:
	_activated = false
	fighter.velocity = Vector2.ZERO
	fighter.play(&"attack")


func exit() -> void:
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	var enemy := fighter as Enemy
	if not _activated and fighter.sprite.frame >= 1:
		_activated = true
		fighter.hitbox.activate(enemy.stats.damage, false)
	fighter.apply_movement(delta)
	if not fighter.sprite.is_playing():
		machine.transition("Recover")
