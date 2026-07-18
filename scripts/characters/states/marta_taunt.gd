extends FighterState
## Periodic flourish that shows the boss's dedicated eight-frame taunt.

const TAUNT_TIME := 1.05

var _timer := 0.0


func enter() -> void:
	var boss := fighter as Marta
	boss.velocity = Vector2.ZERO
	boss.taunt_cooldown = Marta.TAUNT_COOLDOWN
	var target := boss.target_player()
	if target and target.global_position.x != boss.global_position.x:
		boss.set_facing(int(signf(target.global_position.x - boss.global_position.x)))
	boss.play(&"taunt")
	_timer = TAUNT_TIME


func physics_update(delta: float) -> void:
	_timer -= delta
	fighter.apply_movement(delta)
	if _timer <= 0.0:
		machine.transition("Approach")
