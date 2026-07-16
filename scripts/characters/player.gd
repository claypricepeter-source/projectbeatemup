class_name Player
extends Fighter
## Player-controlled fighter. All input actions are suffixed with the player
## index (co-op-ready, see AGENTS.md §7.7).

@export var player_index := 1


func action(base: String) -> StringName:
	return StringName("%s_p%d" % [base, player_index])


func input_vector() -> Vector2:
	return Input.get_vector(
		action("move_left"), action("move_right"),
		action("move_up"), action("move_down"))


func jump_just_pressed() -> bool:
	return Input.is_action_just_pressed(action("jump"))


func attack_just_pressed() -> bool:
	return Input.is_action_just_pressed(action("attack"))


func end_knockdown() -> void:
	start_iframes(1.0)


func finish_death() -> void:
	died.emit()
	EventBus.player_died.emit()
	visible = false
	set_physics_process(false)


func respawn(respawn_position: Vector2) -> void:
	position = respawn_position
	hp = max_hp
	is_dead = false
	invulnerable = false
	visible = true
	modulate = Color.WHITE
	sprite.modulate = Color.WHITE
	sprite.rotation = 0.0
	sprite.position.y = _sprite_base_y
	air_height = 0.0
	air_velocity = 0.0
	velocity = Vector2.ZERO
	hitbox.deactivate()
	set_physics_process(true)
	state_machine.transition("Idle")
	start_iframes(2.0)
	EventBus.fighter_damaged.emit(self)
