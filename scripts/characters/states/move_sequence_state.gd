class_name MoveSequenceState
extends FighterState
## Plays a fixed list of timed steps (animation + optional hit window). Used by
## SoR2 moves whose shape does not depend on input once started: blitz, back
## attack, double sidekick and both specials. Subclasses return the steps.
##
## Step keys: anim, duration, hit_at (-1 = no hit), hit_len, damage, knockdown,
## reach ("front" | "back" | "both"), advance (px/s along facing).

var steps: Array[Dictionary] = []
var step_index := -1
var step_elapsed := 0.0
## Total targets hit across the whole move.
var total_hits := 0
var finished := false

var _hit_started := false
var _hit_open := false


func build_steps() -> Array[Dictionary]:
	return []


## Hooks for subclasses.
func on_move_started() -> void:
	pass


func on_step_started(_step: Dictionary) -> void:
	pass


func on_hits_landed(_count: int) -> void:
	pass


func on_move_finished() -> void:
	pass


func enter() -> void:
	steps = build_steps()
	step_index = -1
	total_hits = 0
	finished = false
	fighter.velocity = Vector2.ZERO
	var player := fighter as Player
	if player:
		player.begin_attack_swing()
	on_move_started()
	_start_next_step()


func exit() -> void:
	fighter.hitbox.deactivate()
	fighter.sprite.speed_scale = 1.0
	fighter.set_facing(fighter.facing)


func physics_update(delta: float) -> void:
	if finished or step_index >= steps.size():
		return
	var step := steps[step_index]
	step_elapsed += delta
	var hit_at: float = step.get("hit_at", -1.0)
	if hit_at >= 0.0 and not _hit_started and step_elapsed >= hit_at:
		_hit_started = true
		_hit_open = true
		var reach := Hitbox.Reach.BOTH if step.get("reach", "front") == "both" else Hitbox.Reach.FRONT
		fighter.hitbox.activate(int(step.get("damage", 0)), bool(step.get("knockdown", false)), reach)
	if _hit_open and step_elapsed >= hit_at + float(step.get("hit_len", 0.08)):
		_close_hit()
	fighter.velocity = Vector2(fighter.facing * float(step.get("advance", 0.0)), 0.0)
	fighter.apply_movement(delta)
	if step_elapsed >= float(step["duration"]):
		if _hit_open:
			_close_hit()
		_start_next_step()


func _close_hit() -> void:
	_hit_open = false
	var hits := fighter.hitbox.hits_this_swing
	fighter.hitbox.deactivate()
	if hits > 0:
		total_hits += hits
		on_hits_landed(hits)


func _start_next_step() -> void:
	step_index += 1
	if step_index >= steps.size():
		finished = true
		var player := fighter as Player
		if player:
			player.finish_attack_swing()
		fighter.set_facing(fighter.facing)
		on_move_finished()
		if machine.current == self:
			machine.transition(next_state())
		return
	var step := steps[step_index]
	step_elapsed = 0.0
	_hit_started = false
	_hit_open = false
	if step.get("reach", "front") == "back":
		fighter.face_art_backwards()
	else:
		fighter.set_facing(fighter.facing)
	fighter.play_timed(step["anim"], float(step["duration"]))
	on_step_started(step)


func next_state() -> String:
	var player := fighter as Player
	if player and player.input_vector() != Vector2.ZERO:
		return "Move"
	return "Idle"
