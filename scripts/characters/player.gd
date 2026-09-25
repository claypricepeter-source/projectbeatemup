class_name Player
extends Fighter
## Player-controlled fighter with the Streets of Rage 2 moveset (AGENTS.md §4.2).
## All input actions are suffixed with the player index (co-op-ready, §7.7).
##
## Buttons follow the SoR2 pad: SPECIAL (A), ATTACK (B), JUMP (C).

const SPECIAL_COST := 8
const HOLD_RELEASE_TIME := 0.4
const DOUBLE_TAP_MS := 300
const BLITZ_WINDOW_MS := 450
const COMBO_MEMORY_MS := 550
const GRAB_REACH_X := 42.0
const GRAB_DEPTH := 8.0
const PICKUP_REACH_X := 26.0
const PICKUP_DEPTH := 14.0
const POINTS_PER_DAMAGE := 10

@export var player_index := 1

@onready var punch_1_player: AudioStreamPlayer = $Punch1Player
@onready var punch_2_player: AudioStreamPlayer = $Punch2Player
@onready var punch_3_player: AudioStreamPlayer = $Punch3Player
@onready var blood_pool: BloodPool = $Visuals/BloodPool

## Next ground-combo step (0 = jab) and when that memory expires.
var combo_step := 0
var combo_expire_ms := 0
## Weapon currently held (&"" = bare hands) and its remaining drops.
var weapon: StringName = &""
var weapon_drops_left := 0
var held_weapon: HeldWeapon
## Enemy chosen by the Move state for the Grab state.
var grab_target: Fighter

var _next_punch_sound := 0
var _swing_connected := false
var _last_hit_sound_frame := -1
var _attack_hold_time := 0.0
var _attack_released_after_hold := false
var _last_tap_dir := 0
var _last_tap_ms := -10000
var _blitz_dir := 0
var _blitz_until_ms := 0

const SMOOTH_PLAYER_FRAMES: SpriteFrames = preload(
	"res://assets/sprites/player/sean_smooth_frames.tres")

const CANONICAL_ANIMATION_SOURCES := {
	&"attack_1": &"light_punch",
	&"attack_2": &"strong_punch",
	&"attack_3": &"strong_kick",
	&"jump_kick": &"flying_knee",
}


func _ready() -> void:
	_install_canonical_animations()
	held_weapon = HeldWeapon.new()
	held_weapon.name = "HeldWeapon"
	held_weapon.visible = false
	$Visuals.add_child(held_weapon)
	super()
	# SoR2 life bar: 104 HP (an apple restores 32, a special costs 8).
	anti_stunlock = true
	hitstun_time = 0.3
	grab_escape_time = 0.9


func _install_canonical_animations() -> void:
	var source := sprite.sprite_frames
	var frames := source.duplicate(true) as SpriteFrames

	# Copy smooth base animations
	_copy_external_animation(frames, &"idle", SMOOTH_PLAYER_FRAMES, &"idle", true)
	_copy_external_animation(frames, &"walk", SMOOTH_PLAYER_FRAMES, &"walk", true)
	_copy_external_animation(frames, &"combo", SMOOTH_PLAYER_FRAMES, &"combo", false)
	_copy_external_animation(frames, &"light_punch", SMOOTH_PLAYER_FRAMES, &"light_punch", false)
	_copy_external_animation(frames, &"strong_punch", SMOOTH_PLAYER_FRAMES, &"strong_punch", false)
	_copy_external_animation(frames, &"strong_kick", SMOOTH_PLAYER_FRAMES, &"strong_kick", false)
	_copy_external_animation(frames, &"flying_knee", SMOOTH_PLAYER_FRAMES, &"flying_knee", false)
	_copy_external_animation(frames, &"jump", SMOOTH_PLAYER_FRAMES, &"jump", false)
	_copy_external_animation(frames, &"hurt", SMOOTH_PLAYER_FRAMES, &"hurt", false)
	_copy_external_animation(frames, &"knockdown", SMOOTH_PLAYER_FRAMES, &"knockdown", false)
	_copy_external_animation(frames, &"death", SMOOTH_PLAYER_FRAMES, &"death", false)
	_copy_external_animation(frames, &"victory", SMOOTH_PLAYER_FRAMES, &"victory", false)

	for canonical: StringName in CANONICAL_ANIMATION_SOURCES:
		var source_name: StringName = CANONICAL_ANIMATION_SOURCES[canonical]
		_copy_animation(frames, canonical, source_name, false)

	# Generate reversed getup animation from knockdown
	_copy_animation(frames, &"getup", &"knockdown", true)

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


func _physics_process(delta: float) -> void:
	_track_attack_hold(delta)
	_track_double_tap()
	held_weapon.set_pose(facing, held_weapon.swing)


# --- Input -----------------------------------------------------------------

func action(base: String) -> StringName:
	return StringName("%s_p%d" % [base, player_index])


func input_vector() -> Vector2:
	return Input.get_vector(
		action("move_left"), action("move_right"),
		action("move_up"), action("move_down"))


## Horizontal stick direction as -1/0/1.
func input_x() -> int:
	var x := input_vector().x
	return 0 if absf(x) < 0.3 else int(signf(x))


func jump_just_pressed() -> bool:
	return Input.is_action_just_pressed(action("jump"))


func attack_just_pressed() -> bool:
	return Input.is_action_just_pressed(action("attack"))


func attack_held() -> bool:
	return Input.is_action_pressed(action("attack"))


func special_just_pressed() -> bool:
	return Input.is_action_just_pressed(action("special"))


## SoR2 "Land": hold Up + Jump while thrown to land on your feet.
func wants_to_land() -> bool:
	return Input.is_action_pressed(action("jump")) and input_vector().y < -0.3


## True on the frame ATTACK is released after being held (SoR2 hold-release).
func attack_released_after_hold() -> bool:
	return _attack_released_after_hold


## Forward, forward (+ attack) armed in the currently faced direction.
func blitz_ready() -> bool:
	return _blitz_dir == facing and Time.get_ticks_msec() <= _blitz_until_ms


func consume_blitz() -> void:
	_blitz_dir = 0


func _track_attack_hold(delta: float) -> void:
	_attack_released_after_hold = false
	if attack_held():
		_attack_hold_time += delta
	else:
		_attack_released_after_hold = _attack_hold_time >= HOLD_RELEASE_TIME
		_attack_hold_time = 0.0


func _track_double_tap() -> void:
	var tap := 0
	if Input.is_action_just_pressed(action("move_right")):
		tap = 1
	elif Input.is_action_just_pressed(action("move_left")):
		tap = -1
	if tap == 0:
		return
	var now := Time.get_ticks_msec()
	if tap == _last_tap_dir and now - _last_tap_ms <= DOUBLE_TAP_MS:
		_blitz_dir = tap
		_blitz_until_ms = now + BLITZ_WINDOW_MS
	_last_tap_dir = tap
	_last_tap_ms = now


## Shared ground-action routing for Idle/Move. Returns true if it transitioned.
## Priority mirrors SoR2: special, back attack, hold-release, pickup/blitz/attack, jump.
func try_ground_actions() -> bool:
	if special_just_pressed():
		var dir := input_x()
		if dir != 0:
			set_facing(dir)
			state_machine.transition("SpecialOffensive")
		else:
			state_machine.transition("SpecialDefensive")
		return true
	if jump_just_pressed() and attack_held():
		state_machine.transition("BackAttack")
		return true
	if attack_released_after_hold() and weapon == &"":
		state_machine.transition("DoubleKick")
		return true
	if attack_just_pressed():
		if find_pickup() != null:
			state_machine.transition("Pickup")
		elif blitz_ready() and weapon == &"":
			consume_blitz()
			state_machine.transition("Blitz")
		else:
			state_machine.transition("Attack")
		return true
	if jump_just_pressed():
		state_machine.transition("Jump")
		return true
	return false


# --- Combo memory ------------------------------------------------------------

func next_combo_step() -> int:
	if Time.get_ticks_msec() > combo_expire_ms:
		combo_step = 0
	return combo_step


func remember_combo(step: int) -> void:
	combo_step = step
	combo_expire_ms = Time.get_ticks_msec() + COMBO_MEMORY_MS


# --- Grabs and pickups -------------------------------------------------------

## SoR2 grab: walking into an enemy (toward it, or up/down onto it) holds it.
func find_grab_target(move: Vector2) -> Fighter:
	var best: Fighter = null
	var best_dx := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Fighter
		if enemy == null or not enemy.can_be_grabbed():
			continue
		var diff := enemy.global_position - global_position
		if absf(diff.y) > GRAB_DEPTH or absf(diff.x) > GRAB_REACH_X or absf(diff.x) < 4.0:
			continue
		var toward := signf(move.x) == signf(diff.x) and absf(move.x) > 0.3
		var onto := absf(move.y) > 0.3 and absf(diff.x) < GRAB_REACH_X * 0.85
		if not (toward or onto):
			continue
		if absf(diff.x) < best_dx:
			best_dx = absf(diff.x)
			best = enemy
	return best


func on_grab_broken() -> void:
	if current_state_name() == &"Grab":
		state_machine.transition("Idle")


## Nearest food or weapon at the player's feet (picked up with ATTACK).
func find_pickup() -> Node2D:
	for group: StringName in [&"pickups", &"weapons"]:
		for node in get_tree().get_nodes_in_group(group):
			var item := node as Node2D
			if item == null or item.is_queued_for_deletion():
				continue
			if item is Pickup and (item as Pickup).collected:
				continue
			var diff := item.global_position - global_position
			if absf(diff.x) <= PICKUP_REACH_X and absf(diff.y) <= PICKUP_DEPTH:
				return item
	return null


func collect(item: Node2D) -> void:
	if not is_instance_valid(item):
		return
	if item is WeaponPickup:
		var pickup := item as WeaponPickup
		drop_weapon()
		equip_weapon(pickup.kind, pickup.drops_left)
		AudioManager.play_sfx(&"pickup", -6.0)
		EventBus.pickup_collected.emit(pickup.kind)
		pickup.queue_free()
	elif item is Pickup:
		(item as Pickup).collect(self)


# --- Weapons -----------------------------------------------------------------

func equip_weapon(kind: StringName, drops_left: int) -> void:
	weapon = kind
	weapon_drops_left = drops_left
	held_weapon.show_weapon(kind)


## Drops the held weapon at the player's feet (it vanishes after three drops).
func drop_weapon() -> void:
	if weapon == &"":
		return
	var parent := get_parent()
	var kind := weapon
	var remaining := weapon_drops_left - 1
	var drop_at := global_position + Vector2(-facing * 14.0, 2.0)
	weapon = &""
	held_weapon.show_weapon(&"")
	WeaponPickup.spawn.call_deferred(parent, kind, remaining, drop_at)


func throw_weapon() -> void:
	if weapon == &"":
		return
	ThrownWeapon.launch(self, weapon, weapon_drops_left)
	weapon = &""
	held_weapon.show_weapon(&"")


# --- Specials ------------------------------------------------------------------

## SoR2 specials cost 8 HP but can never KO the player.
func pay_special_cost() -> void:
	hp = maxi(hp - SPECIAL_COST, 1)
	EventBus.fighter_damaged.emit(self)


# --- Hits and scoring ----------------------------------------------------------

func on_attack_connected(target: Fighter, defeated: bool) -> void:
	_swing_connected = true
	award_hit(hitbox.damage if hitbox.damage > 0 else Weapons.THROWN_DAMAGE)
	_play_hit_sound(defeated)


## Direct hits that bypass the hitbox (grab knees, headbutts, throws).
func land_direct_hit(target: Fighter, damage: int, knockdown_hit: bool) -> bool:
	if not is_instance_valid(target) or target.is_dead:
		return false
	var was_held := target.current_state_name() == &"Grabbed"
	var accepted := false
	if was_held and not knockdown_hit:
		accepted = _damage_held_target(target, damage)
	else:
		target.invulnerable = false
		accepted = target.take_hit(damage, knockdown_hit, self)
	if accepted:
		_swing_connected = true
		award_hit(damage)
		_play_hit_sound(target.hp <= 0)
		ImpactManager.connected_hit(target, knockdown_hit)
	return accepted


## A holding attack damages without breaking the hold unless it kills.
func _damage_held_target(target: Fighter, damage: int) -> bool:
	target.hp = maxi(target.hp - damage, 0)
	EventBus.fighter_damaged.emit(target)
	if target.is_in_group("bosses"):
		EventBus.boss_health_changed.emit(float(target.hp) / float(target.max_hp))
	if target.hp <= 0:
		target.state_machine.transition("Death")
	return true


func award_hit(damage: int) -> void:
	GameState.add_score(damage * POINTS_PER_DAMAGE)


func _play_hit_sound(defeated: bool) -> void:
	# Avoid playing hit sound more than once per frame (e.g. two enemies at once)
	var current_frame := Engine.get_physics_frames()
	if current_frame == _last_hit_sound_frame:
		return
	_last_hit_sound_frame = current_frame
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


func on_knocked_off_feet() -> void:
	drop_weapon()


func end_knockdown() -> void:
	# SoR2: about one second of invulnerability after getting up.
	start_iframes(1.0)


func on_death_started() -> void:
	AudioManager.play_sfx(&"player_death", -2.0)
	ImpactManager.player_ko_slowdown()


func on_death_landed() -> void:
	AudioManager.play_sfx(&"after_death", -2.0)
	blood_pool.expand()


## Time over: the SoR2 timer reaching zero costs a life.
func time_over() -> void:
	if is_dead:
		return
	hp = 0
	EventBus.fighter_damaged.emit(self)
	state_machine.transition("Death")


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
	sprite.speed_scale = 1.0
	sprite.position.y = _sprite_base_y
	air_height = 0.0
	air_velocity = 0.0
	velocity = Vector2.ZERO
	combo_step = 0
	hitbox.deactivate()
	blood_pool.reset_pool()
	set_physics_process(true)
	state_machine.transition("Idle")
	start_iframes(2.0)
	EventBus.fighter_damaged.emit(self)
	EventBus.player_respawned.emit()
