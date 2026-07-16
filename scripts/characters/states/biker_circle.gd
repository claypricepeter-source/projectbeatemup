extends FighterState
## Maintains a wide standoff while changing lanes, then lines up a charge.

const STANDOFF_X := 190.0
const DEPTH_OFFSET := 24.0
const CIRCLE_TIME := 1.15
const ALIGN_Y := 11.0

var _timer := 0.0
var _side := 1.0
var _depth_side := 1.0


func enter() -> void:
	_timer = CIRCLE_TIME
	_side *= -1.0
	_depth_side *= -1.0
	fighter.play(&"walk")


func physics_update(delta: float) -> void:
	var biker := fighter as Biker
	var target := biker.target_player()
	if target == null:
		machine.transition("Idle")
		return
	var to_target := target.global_position - biker.global_position
	if to_target.x != 0.0:
		biker.set_facing(int(signf(to_target.x)))
	_timer -= delta
	var aligned := absf(to_target.y) <= ALIGN_Y
	if _timer <= 0.0 and aligned and biker.attackers_count() < Enemy.MAX_ATTACKERS:
		machine.transition("Charge")
		return
	var depth_offset := 0.0 if _timer <= 0.25 else DEPTH_OFFSET * _depth_side
	var goal := target.global_position + Vector2(STANDOFF_X * _side, depth_offset)
	var difference := goal - biker.global_position
	biker.velocity = difference.normalized() * biker.move_speed if difference.length() > 5.0 else Vector2.ZERO
	biker.play(&"walk")
	biker.apply_movement(delta)
