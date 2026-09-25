extends FighterState
## Crouch to pick up food or a weapon with ATTACK (SoR2). Invulnerable while
## picking anything up, as in SoR2.

const DURATION := 0.24

var _timer := 0.0
var _item: Node2D


func enter() -> void:
	var player := fighter as Player
	_item = player.find_pickup()
	_timer = DURATION
	fighter.velocity = Vector2.ZERO
	fighter.invulnerable = true
	fighter.play(&"crouch_block")
	fighter.sprite.pause()
	fighter.sprite.frame = 0


func exit() -> void:
	fighter.invulnerable = false


func physics_update(delta: float) -> void:
	_timer -= delta
	if _item and _timer <= DURATION * 0.5:
		(fighter as Player).collect(_item)
		_item = null
	fighter.apply_movement(delta)
	if _timer <= 0.0:
		machine.transition("Idle")
