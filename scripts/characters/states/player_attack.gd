extends FighterState
## 3-hit ground combo (AGENTS.md §4.2). Pressing attack during a swing buffers
## the next step; the chain advances when the current animation ends.

const STEPS: Array[Dictionary] = [
	{"anim": &"attack_1", "damage": 6, "knockdown": false, "active": [1]},
	{"anim": &"attack_2", "damage": 6, "knockdown": false, "active": [1]},
	{"anim": &"attack_3", "damage": 12, "knockdown": true, "active": [2, 3]},
]

var _step := 0
var _buffered := false
var _activated := false


func enter() -> void:
	_step = 0
	_start_step()


func exit() -> void:
	fighter.hitbox.deactivate()


func physics_update(delta: float) -> void:
	var player := fighter as Player
	if player.attack_just_pressed():
		_buffered = true
	var step: Dictionary = STEPS[_step]
	var active: Array = step["active"]
	if not _activated and fighter.sprite.frame in active:
		_activated = true
		fighter.hitbox.activate(step["damage"], step["knockdown"])
	elif _activated and fighter.sprite.frame not in active:
		fighter.hitbox.deactivate()
	fighter.apply_movement(delta)
	if not fighter.sprite.is_playing():
		if _buffered and _step < STEPS.size() - 1:
			_step += 1
			fighter.hitbox.deactivate()
			_start_step()
		else:
			machine.transition("Idle")


func _start_step() -> void:
	_buffered = false
	_activated = false
	fighter.velocity = Vector2.ZERO
	fighter.play(STEPS[_step]["anim"])
