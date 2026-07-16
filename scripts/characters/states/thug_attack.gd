extends FighterState
## Slow, readable haymaker. The pose holds before the normal attack frames play.

const ANIMATION_START := 0.44
const ACTIVE_START := 0.58
const ACTIVE_END := 0.76
const END_TIME := 0.95

var _elapsed := 0.0
var _swinging := false
var _hit_started := false
var _active := false


func enter() -> void:
	_elapsed = 0.0
	_swinging = false
	_hit_started = false
	_active = false
	fighter.velocity = Vector2.ZERO
	fighter.sprite.play(&"attack")
	fighter.sprite.pause()
	fighter.sprite.frame = 0


func exit() -> void:
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	_elapsed += delta
	if not _swinging and _elapsed >= ANIMATION_START:
		_swinging = true
		fighter.sprite.play(&"attack")
	if not _hit_started and _elapsed >= ACTIVE_START:
		_hit_started = true
		_active = true
		var enemy := fighter as Enemy
		fighter.hitbox.activate(enemy.stats.damage, false)
	if _active and _elapsed >= ACTIVE_END:
		_active = false
		fighter.hitbox.deactivate()
	fighter.apply_movement(delta)
	if _elapsed >= END_TIME:
		machine.transition("Recover")
