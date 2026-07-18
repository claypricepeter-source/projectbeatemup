extends FighterState
## Smooth ten-frame three-hit combo. Mashing attack unlocks the later strikes.

const HIT_FRAMES := [2, 5, 8]
const DAMAGES := [6, 6, 12]
const KNOCKDOWNS := [false, false, true]
const EXIT_FRAMES := [4, 7, 10]

var _unlocked_steps := 1
var _completed_hits := 0
var _active_hit := -1
var _last_frame := -1
var _swing_open := false


func enter() -> void:
	_unlocked_steps = 1
	_completed_hits = 0
	_active_hit = -1
	_last_frame = -1
	_swing_open = true
	fighter.velocity = Vector2.ZERO
	(fighter as Player).begin_attack_swing()
	fighter.play(&"combo")


func exit() -> void:
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	var player := fighter as Player
	if player.attack_just_pressed():
		_unlocked_steps = mini(_unlocked_steps + 1, HIT_FRAMES.size())
	_open_next_swing(player)

	var frame := fighter.sprite.frame
	if frame != _last_frame:
		_on_frame_changed(player, frame)
		_last_frame = frame

	fighter.apply_movement(delta)
	if not fighter.sprite.is_playing():
		_finish_active_swing(player)
		machine.transition("Idle")
		return
	if _completed_hits >= _unlocked_steps and frame >= EXIT_FRAMES[_unlocked_steps - 1]:
		machine.transition("Idle")


func _on_frame_changed(player: Player, frame: int) -> void:
	if _active_hit >= 0 and frame != HIT_FRAMES[_active_hit]:
		fighter.hitbox.deactivate()
		player.finish_attack_swing()
		_completed_hits = _active_hit + 1
		_active_hit = -1
		_swing_open = false
		_open_next_swing(player)
	if _completed_hits < _unlocked_steps and frame == HIT_FRAMES[_completed_hits]:
		_active_hit = _completed_hits
		fighter.hitbox.activate(DAMAGES[_active_hit], KNOCKDOWNS[_active_hit])


func _open_next_swing(player: Player) -> void:
	if not _swing_open and _completed_hits < _unlocked_steps:
		player.begin_attack_swing()
		_swing_open = true


func _finish_active_swing(player: Player) -> void:
	if _active_hit >= 0:
		fighter.hitbox.deactivate()
		player.finish_attack_swing()
		_active_hit = -1
		_swing_open = false
