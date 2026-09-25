extends FighterState
## SoR2 holding moves (Axel's values from the SoR2 move FAQ).
## From the front:
##   Toward + ATTACK → knee (8), knee (8), double knee (8 + 10, KD)
##   ATTACK          → headbutt (22, KD)
##   Away + ATTACK   → back throw (24, KD; the body hits other enemies for 16)
##   JUMP            → vault over to the enemy's back (twice = it breaks loose)
## From behind:
##   ATTACK          → body slam (28, KD)
## The player drops any weapon on grabbing and is invulnerable during throws
## and vaults. Doing nothing lets the enemy struggle free.

enum Action { NONE, KNEE, DOUBLE_KNEE, HEADBUTT, THROW, SLAM, VAULT }

const HOLD_DISTANCE := 34.0
const VAULT_TIME := 0.38
const VAULT_HEIGHT := 46.0

var _target: Fighter
var _from_behind := false
var _knees := 0
var _vaults := 0
var _action := Action.NONE
var _action_time := 0.0
var _action_fired := 0
var _vault_from_x := 0.0
var _vault_to_x := 0.0


func enter() -> void:
	var player := fighter as Player
	_target = player.grab_target
	player.grab_target = null
	player.drop_weapon()
	fighter.velocity = Vector2.ZERO
	_knees = 0
	_vaults = 0
	_action = Action.NONE
	if _target == null:
		machine.transition.call_deferred("Idle")
		return
	var dx := _target.global_position.x - fighter.global_position.x
	fighter.set_facing(int(signf(dx)) if dx != 0.0 else fighter.facing)
	# Enemy facing the same way as the player = the player is behind it.
	_from_behind = _target.facing == fighter.facing
	if not _from_behind:
		_target.set_facing(-fighter.facing)
	_hold_pose()


func exit() -> void:
	fighter.invulnerable = false
	fighter.sprite.speed_scale = 1.0
	fighter.air_height = 0.0
	fighter.update_air(0.0)
	if _target_is_held():
		_target.release_from_grab(fighter.facing * 40.0)
	_target = null


func _target_is_held() -> bool:
	return is_instance_valid(_target) and _target.held_by == fighter \
			and _target.current_state_name() == &"Grabbed"


func _hold_pose() -> void:
	fighter.play(&"throw")
	fighter.sprite.pause()
	fighter.sprite.frame = 0


func physics_update(delta: float) -> void:
	var player := fighter as Player
	if _action == Action.NONE:
		if not _target_is_held():
			machine.transition("Idle")
			return
		_place_target()
		_read_input(player)
	else:
		_update_action(player, delta)
	fighter.apply_movement(delta)


func _place_target() -> void:
	_target.global_position = Vector2(
		fighter.global_position.x + fighter.facing * HOLD_DISTANCE,
		fighter.global_position.y)


func _read_input(player: Player) -> void:
	if player.jump_just_pressed():
		_begin(Action.VAULT)
		return
	if not player.attack_just_pressed():
		return
	var dir := player.input_x()
	if _from_behind:
		_begin(Action.SLAM)
	elif dir == -fighter.facing:
		_begin(Action.THROW)
	elif dir == fighter.facing:
		_begin(Action.DOUBLE_KNEE if _knees >= 2 else Action.KNEE)
	else:
		_begin(Action.HEADBUTT)


func _begin(next: Action) -> void:
	_action = next
	_action_time = 0.0
	_action_fired = 0
	(fighter as Player).begin_attack_swing()
	match next:
		Action.KNEE:
			fighter.play_timed(&"light_kick", 0.24)
		Action.DOUBLE_KNEE:
			fighter.play_timed(&"light_kick", 0.46)
		Action.HEADBUTT:
			fighter.play_timed(&"strong_punch", 0.3)
		Action.THROW, Action.SLAM:
			fighter.invulnerable = true
			fighter.play_timed(&"throw", 0.5)
		Action.VAULT:
			fighter.invulnerable = true
			_vault_from_x = fighter.global_position.x
			_vault_to_x = _target.global_position.x + fighter.facing * HOLD_DISTANCE
			fighter.play(&"jump")


func _update_action(player: Player, delta: float) -> void:
	_action_time += delta
	match _action:
		Action.KNEE:
			_hold_target_if_valid()
			if _fire_at(0.1):
				player.land_direct_hit(_target, 8, false)
				_extend_hold()
			if _action_time >= 0.24:
				_knees += 1
				_end_action()
		Action.DOUBLE_KNEE:
			_hold_target_if_valid()
			if _fire_at(0.1):
				player.land_direct_hit(_target, 8, false)
			if _fire_at(0.3, 2):
				player.land_direct_hit(_target, 10, true)
			if _action_time >= 0.46:
				_finish()
		Action.HEADBUTT:
			_hold_target_if_valid()
			if _fire_at(0.12):
				player.land_direct_hit(_target, 22, true)
			if _action_time >= 0.3:
				_finish()
		Action.THROW:
			if _fire_at(0.22) and is_instance_valid(_target):
				_throw_target(player, 24, false)
			if _action_time >= 0.5:
				_finish()
		Action.SLAM:
			if _fire_at(0.26) and is_instance_valid(_target):
				_throw_target(player, 28, true)
			if _action_time >= 0.5:
				_finish()
		Action.VAULT:
			_update_vault()


func _fire_at(time: float, index: int = 1) -> bool:
	if _action_fired < index and _action_time >= time:
		_action_fired = index
		return true
	return false


func _hold_target_if_valid() -> void:
	if _target_is_held():
		_place_target()


func _extend_hold() -> void:
	if _target_is_held():
		_target.state_machine.current.call("extend_hold", 1.1)


func _throw_target(player: Player, damage: int, slam: bool) -> void:
	if not _target_is_held():
		return
	var thrown := _target
	_target = null
	player.award_hit(damage)
	AudioManager.play_sfx(&"knockdown", -4.0)
	# Back throw / body slam: the victim goes over the player's shoulder.
	thrown.start_thrown(player, -fighter.facing, damage, slam)


func _update_vault() -> void:
	var t := clampf(_action_time / VAULT_TIME, 0.0, 1.0)
	fighter.global_position.x = lerpf(_vault_from_x, _vault_to_x, t)
	fighter.air_height = sin(t * PI) * VAULT_HEIGHT
	fighter.sprite.position.y = fighter._sprite_base_y - fighter.air_height
	if t < 1.0:
		return
	fighter.air_height = 0.0
	fighter.sprite.position.y = fighter._sprite_base_y
	fighter.set_facing(-fighter.facing)
	fighter.invulnerable = false
	_vaults += 1
	_from_behind = not _from_behind
	if _vaults >= 2 or not _target_is_held():
		_finish()
		return
	_end_action()


func _end_action() -> void:
	_action = Action.NONE
	(fighter as Player).finish_attack_swing()
	if not _target_is_held():
		_finish()
		return
	_hold_pose()


func _finish() -> void:
	(fighter as Player).finish_attack_swing()
	_action = Action.NONE
	machine.transition("Idle")
