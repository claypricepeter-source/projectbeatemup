class_name Player
extends Fighter
## Player-controlled fighter. All input actions are suffixed with the player
## index (co-op-ready, see AGENTS.md §7.7).

@export var player_index := 1

@onready var punch_1_player: AudioStreamPlayer = $Punch1Player
@onready var punch_2_player: AudioStreamPlayer = $Punch2Player
@onready var punch_3_player: AudioStreamPlayer = $Punch3Player

var _next_punch_sound := 0
var _swing_connected := false

const CANONICAL_ANIMATION_SOURCES := {
	&"attack_1": &"light_punch",
	&"attack_2": &"strong_punch",
	&"attack_3": &"strong_kick",
	&"jump_kick": &"flying_knee",
	&"hurt": &"get_hit",
	&"knockdown": &"knocked_down",
	&"getup": &"knocked_down",
	&"death": &"knocked_down",
}


func _ready() -> void:
	_install_canonical_animations()
	super()


func _install_canonical_animations() -> void:
	var source := sprite.sprite_frames
	var frames := source.duplicate(true) as SpriteFrames
	for canonical: StringName in CANONICAL_ANIMATION_SOURCES:
		var source_name: StringName = CANONICAL_ANIMATION_SOURCES[canonical]
		_copy_animation(frames, canonical, source_name, canonical == &"getup")
	sprite.sprite_frames = frames


func _copy_animation(frames: SpriteFrames, target: StringName, source: StringName, reverse: bool) -> void:
	if frames.has_animation(target):
		frames.remove_animation(target)
	frames.add_animation(target)
	frames.set_animation_speed(target, frames.get_animation_speed(source))
	frames.set_animation_loop(target, false)
	var count := frames.get_frame_count(source)
	for index in count:
		var source_index := count - index - 1 if reverse else index
		frames.add_frame(
			target,
			frames.get_frame_texture(source, source_index),
			frames.get_frame_duration(source, source_index))


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


func on_attack_connected(_target: Fighter, defeated: bool) -> void:
	_swing_connected = true
	if defeated:
		punch_1_player.stop()
		punch_2_player.stop()
		_restart_sound(punch_3_player)
		return
	var player := punch_1_player if _next_punch_sound == 0 else punch_2_player
	_next_punch_sound = 1 - _next_punch_sound
	_restart_sound(player)


func begin_attack_swing() -> void:
	_swing_connected = false


func finish_attack_swing() -> void:
	if not _swing_connected:
		AudioManager.play_sfx(&"whiff", -8.0)


func _restart_sound(player: AudioStreamPlayer) -> void:
	player.stop()
	player.play()


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
