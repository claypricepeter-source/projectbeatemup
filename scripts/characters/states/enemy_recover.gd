extends FighterState
## Post-attack pause, then a short backstep before re-engaging.

var _timer := 0.0
var _retreating := false


func enter() -> void:
	var enemy := fighter as Enemy
	_timer = enemy.stats.recover_time
	_retreating = false
	fighter.velocity = Vector2.ZERO
	fighter.play(&"idle")


func physics_update(delta: float) -> void:
	_timer -= delta
	fighter.apply_movement(delta)
	if _timer > 0.0:
		return
	if _retreating:
		machine.transition("Approach")
		return
	var enemy := fighter as Enemy
	_retreating = true
	_timer = enemy.stats.retreat_time
	fighter.play(&"walk")
	fighter.velocity = Vector2(-fighter.facing * fighter.move_speed.x * 0.8, 0)
