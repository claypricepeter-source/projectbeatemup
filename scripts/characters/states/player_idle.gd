extends FighterState


func enter() -> void:
	fighter.velocity = Vector2.ZERO
	fighter.play(&"idle")


func physics_update(delta: float) -> void:
	var player := fighter as Player
	if player.try_ground_actions():
		return
	if player.input_vector() != Vector2.ZERO:
		machine.transition("Move")
		return
	fighter.apply_movement(delta)
