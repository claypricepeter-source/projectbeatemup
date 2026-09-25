extends FighterState
## 8-way walk. Walking into a grabbable enemy holds it (SoR2 grab).


func enter() -> void:
	fighter.play(&"walk")


func physics_update(delta: float) -> void:
	var player := fighter as Player
	if player.try_ground_actions():
		return
	var input := player.input_vector()
	if input == Vector2.ZERO:
		machine.transition("Idle")
		return
	var target := player.find_grab_target(input)
	if target and target.begin_grabbed(player):
		player.grab_target = target
		machine.transition("Grab")
		return
	player.set_facing(int(signf(input.x)))
	player.velocity = input * player.move_speed
	player.apply_movement(delta)
