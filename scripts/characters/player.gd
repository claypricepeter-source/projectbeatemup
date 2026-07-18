class_name Player
extends Fighter
## Player-controlled fighter. All input actions are suffixed with the player
## index (co-op-ready, see AGENTS.md §7.7).

@export var player_index := 1

@onready var punch_1_player: AudioStreamPlayer = $Punch1Player
@onready var punch_2_player: AudioStreamPlayer = $Punch2Player
@onready var punch_3_player: AudioStreamPlayer = $Punch3Player
@onready var blood_pool: BloodPool = $Visuals/BloodPool

var _next_punch_sound := 0
var _swing_connected := false

const SMOOTH_PLAYER_FRAMES: SpriteFrames = preload(
	"res://assets/sprites/player/sean_smooth_frames.tres")

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
	_copy_external_animation(frames, &"idle", SMOOTH_PLAYER_FRAMES, &"idle", true)
	_copy_external_animation(frames, &"combo", SMOOTH_PLAYER_FRAMES, &"combo", false)
	_copy_external_animation(frames, &"light_punch", SMOOTH_PLAYER_FRAMES, &"light_punch", false)
	_copy_external_animation(frames, &"strong_punch", SMOOTH_PLAYER_FRAMES, &"strong_punch", false)
	_copy_external_animation(frames, &"strong_kick", SMOOTH_PLAYER_FRAMES, &"strong_kick", false)
	_copy_external_animation(frames, &"flying_knee", SMOOTH_PLAYER_FRAMES, &"flying_knee", false)
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


func _copy_external_animation(
		frames: SpriteFrames,
		target: StringName,
		source_frames: SpriteFrames,
		source: StringName,
		loop: bool) -> void:
	if frames.has_animation(target):
		frames.remove_animation(target)
	frames.add_animation(target)
	frames.set_animation_speed(target, source_frames.get_animation_speed(source))
	frames.set_animation_loop(target, loop)
	for index in source_frames.get_frame_count(source):
		frames.add_frame(
			target,
			source_frames.get_frame_texture(source, index),
			source_frames.get_frame_duration(source, index))


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


func on_attack_connected(target: Fighter, defeated: bool) -> void:
	_swing_connected = true
	
	# Sticky combat: lock onto/magnetize the player to the enemy's depth (Y) and proximity (X)
	# directly on hit, mimicking Streets of Rage 2.
	if is_instance_valid(target) and not target.is_dead:
		global_position.y = target.global_position.y
		var target_x = target.global_position.x
		var current_dist_x = absf(global_position.x - target_x)
		if current_dist_x > 24.0 and current_dist_x < 72.0:
			var desired_x = target_x - (42.0 * facing)
			global_position.x = lerpf(global_position.x, desired_x, 0.55)

	if defeated:
		punch_1_player.stop()
		punch_2_player.stop()
		_restart_sound(punch_3_player)
		return
	var audio_player := punch_1_player if _next_punch_sound == 0 else punch_2_player
	_next_punch_sound = 1 - _next_punch_sound
	_restart_sound(audio_player)


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


func on_death_started() -> void:
	AudioManager.play_sfx(&"player_death", -2.0)
	ImpactManager.player_ko_slowdown()


func on_death_landed() -> void:
	AudioManager.play_sfx(&"after_death", -2.0)
	blood_pool.expand()


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
	blood_pool.reset_pool()
	set_physics_process(true)
	state_machine.transition("Idle")
	start_iframes(2.0)
	EventBus.fighter_damaged.emit(self)
