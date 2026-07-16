extends FighterState


func enter() -> void:
	fighter.play(&"walk")


func physics_update(delta: float) -> void:
	var player := fighter as Player
	if player.attack_just_pressed():
		machine.transition("Attack")
		return
	if player.jump_just_pressed():
		machine.transition("Jump")
		return
	var input := player.input_vector()
	if input == Vector2.ZERO:
		machine.transition("Idle")
		return
	player.set_facing(int(signf(input.x)))
	player.velocity = input * player.move_speed
	player.apply_movement(delta)
