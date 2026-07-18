extends FighterState
## A 3.2-second vulnerability window earned by dodging the liquid barrage.

const DURATION := 3.2

var _elapsed := 0.0


func enter() -> void:
	var boss := fighter as Marta
	boss.velocity = Vector2.ZERO
	boss.invulnerable = false
	boss.hyper_armor = false
	boss.reset_dizzy_hit_chain()
	boss.sprite.animation = &"hurt"
	boss.sprite.pause()
	boss.sprite.frame = 0
	boss.set_dizzy_visual(true)
	_elapsed = 0.0


func exit() -> void:
	var boss := fighter as Marta
	boss.set_dizzy_visual(false)
	boss.reset_dizzy_hit_chain()


func physics_update(delta: float) -> void:
	_elapsed += delta
	var boss := fighter as Marta
	boss.sprite.frame = int(_elapsed * 8.0) % 4
	boss.sprite.rotation = sin(_elapsed * 13.0) * 0.055
	boss.apply_movement(delta)
	if _elapsed >= DURATION:
		machine.transition("Recover")
