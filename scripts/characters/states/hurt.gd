extends FighterState
## Shared hitstun state (player and enemies): a short interrupt, then Idle.
## Duration comes from Fighter.hitstun_time so SoR2 combos can chain on enemies.

var _timer := 0.0


func enter() -> void:
	fighter.hitbox.deactivate()
	fighter.velocity = Vector2.ZERO
	fighter.play(&"hurt")
	fighter.sprite.frame = 0
	_timer = fighter.hitstun_time


func physics_update(delta: float) -> void:
	_timer -= delta
	fighter.apply_movement(delta)
	if _timer <= 0.0:
		machine.transition("Idle")
