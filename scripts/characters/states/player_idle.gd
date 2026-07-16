extends FighterState


func enter() -> void:
	fighter.velocity = Vector2.ZERO
	fighter.play(&"idle")


func physics_update(delta: float) -> void:
	var player := fighter as Player
	if player.attack_just_pressed():
		machine.transition("Attack")
		return
	if player.jump_just_pressed():
		machine.transition("Jump")
		return
	if player.input_vector() != Vector2.ZERO:
		machine.transition("Move")
		return
	fighter.apply_movement(delta)
