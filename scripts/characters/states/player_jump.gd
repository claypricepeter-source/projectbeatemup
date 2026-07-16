extends FighterState
## Classic brawler jump: the horizontal arc is locked at takeoff.
## Attacking while airborne turns the jump into a jump kick (knockdown hit).

const JUMP_KICK_DAMAGE := 10

var _kicking := false


func enter() -> void:
	_kicking = false
	fighter.start_jump()
	fighter.play(&"jump")


func exit() -> void:
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	var player := fighter as Player
	if not _kicking and player.attack_just_pressed():
		_kicking = true
		fighter.play(&"jump_kick")
		fighter.hitbox.activate(JUMP_KICK_DAMAGE, true)
	var landed := player.update_air(delta)
	player.apply_movement(delta)
	if landed:
		fighter.hitbox.deactivate()
		machine.transition("Idle" if player.input_vector() == Vector2.ZERO else "Move")
