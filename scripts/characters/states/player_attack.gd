extends FighterState
## SoR2 ground combo (Axel's values from the SoR2 move FAQ):
##   jab 6 → jab 6 → straight 8 → low sidekick 10 → high sidekick 14 (KD).
## The string only advances on hits: a whiffed swing starts over at the jab.
## The low sidekick knocks down on its own; pressing ATTACK in the short window
## as the straight retracts chains both kicks instead (the SoR2 timing trick).
## Armed, ATTACK swings the held weapon instead.

const STEPS: Array[Dictionary] = [
	{"anim": &"light_punch", "duration": 0.2, "hit_at": 0.05, "hit_len": 0.07, "damage": 6, "knockdown": false},
	{"anim": &"light_punch", "duration": 0.2, "hit_at": 0.05, "hit_len": 0.07, "damage": 6, "knockdown": false},
	{"anim": &"strong_punch", "duration": 0.26, "hit_at": 0.08, "hit_len": 0.08, "damage": 8, "knockdown": false},
	{"anim": &"light_kick", "duration": 0.3, "hit_at": 0.1, "hit_len": 0.09, "damage": 10, "knockdown": true},
	{"anim": &"strong_kick", "duration": 0.36, "hit_at": 0.12, "hit_len": 0.1, "damage": 14, "knockdown": true},
]
const STRAIGHT_STEP := 2
const LOW_KICK_STEP := 3
## Seconds at the end of the straight in which a press chains both kicks.
const DOUBLE_KICK_WINDOW := 0.05

var _step := 0
var _elapsed := 0.0
var _hit_started := false
var _hit_open := false
var _connected := false
var _buffered := false
var _double_kick := false
var _weapon_mode := false
var _data: Dictionary


func enter() -> void:
	var player := fighter as Player
	fighter.velocity = Vector2.ZERO
	_weapon_mode = player.weapon != &""
	_double_kick = false
	_start_step(0 if _weapon_mode else player.next_combo_step())


func exit() -> void:
	fighter.hitbox.deactivate()
	fighter.sprite.speed_scale = 1.0
	(fighter as Player).held_weapon.swing = 0.0


func _start_step(step: int) -> void:
	var player := fighter as Player
	_step = step
	_elapsed = 0.0
	_hit_started = false
	_hit_open = false
	_connected = false
	_buffered = false
	_data = Weapons.info(player.weapon) if _weapon_mode else STEPS[step]
	player.begin_attack_swing()
	fighter.play_timed(_data["anim"], float(_data["duration"]))


func physics_update(delta: float) -> void:
	var player := fighter as Player
	_elapsed += delta
	if _handle_cancels(player):
		return
	if player.attack_just_pressed():
		_buffered = true
		if not _weapon_mode and _step == STRAIGHT_STEP \
				and _elapsed >= float(_data["duration"]) - DOUBLE_KICK_WINDOW:
			_double_kick = true
	var hit_at := float(_data["hit_at"])
	if not _hit_started and _elapsed >= hit_at:
		_hit_started = true
		_hit_open = true
		var knockdown := bool(_data["knockdown"])
		if not _weapon_mode and _step == LOW_KICK_STEP and _double_kick:
			knockdown = false
		fighter.hitbox.activate(int(_data["damage"]), knockdown)
	if _hit_open and _elapsed >= hit_at + float(_data["hit_len"]):
		_close_hit()
	if _weapon_mode:
		player.held_weapon.swing = clampf(_elapsed / maxf(hit_at + 0.02, 0.01), 0.0, 1.0)
	fighter.apply_movement(delta)
	if _elapsed >= float(_data["duration"]):
		if _hit_open:
			_close_hit()
		_finish_step(player)


## SoR2 lets the blitz, back attack and specials interrupt the combo.
func _handle_cancels(player: Player) -> bool:
	if player.special_just_pressed() or (player.jump_just_pressed() and player.attack_held()):
		fighter.hitbox.deactivate()
		return player.try_ground_actions()
	if player.attack_just_pressed() and player.blitz_ready() and not _weapon_mode:
		player.consume_blitz()
		machine.transition("Blitz")
		return true
	return false


func _close_hit() -> void:
	_hit_open = false
	_connected = fighter.hitbox.hits_this_swing > 0
	fighter.hitbox.deactivate()
	(fighter as Player).finish_attack_swing()


func _finish_step(player: Player) -> void:
	if _weapon_mode:
		if _buffered and player.weapon != &"":
			_start_step(0)
		else:
			machine.transition("Idle")
		return
	var next := 0
	if _connected:
		next = _step + 1
		# A lone low sidekick (no double-kick timing) ends the string.
		if _step == LOW_KICK_STEP and not _double_kick:
			next = 0
		if next >= STEPS.size():
			next = 0
	player.remember_combo(next)
	if _connected and _step == STRAIGHT_STEP and _double_kick:
		_start_step(LOW_KICK_STEP)
		return
	if _connected and _step == LOW_KICK_STEP and _double_kick:
		_start_step(LOW_KICK_STEP + 1)
		return
	if _buffered:
		_start_step(next)
		return
	machine.transition("Idle" if player.input_vector() == Vector2.ZERO else "Move")
