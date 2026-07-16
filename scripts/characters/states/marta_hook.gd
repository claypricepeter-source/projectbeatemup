extends FighterState
## Slow long-reach boat-hook strike.

const ANIMATION_START := 0.30
const ACTIVE_START := 0.44
const ACTIVE_END := 0.68
const END_TIME := 1.02

var _elapsed := 0.0
var _started := false
var _hit_started := false
var _active := false


func enter() -> void:
	var boss := fighter as Marta
	boss.last_attack_was_sweep = false
	boss.velocity = Vector2.ZERO
	boss.sprite.play(&"attack")
	boss.sprite.pause()
	boss.sprite.frame = 0
	_elapsed = 0.0
	_started = false
	_hit_started = false
	_active = false


func exit() -> void:
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	_elapsed += delta
	var boss := fighter as Marta
	if not _started and _elapsed >= ANIMATION_START:
		_started = true
		boss.sprite.play(&"attack")
	if not _hit_started and _elapsed >= ACTIVE_START:
		_hit_started = true
		_active = true
		boss.hitbox.activate(boss.stats.damage, false)
	if _active and _elapsed >= ACTIVE_END:
		_active = false
		boss.hitbox.deactivate()
	boss.apply_movement(delta)
	if _elapsed >= END_TIME:
		machine.transition("Recover")
