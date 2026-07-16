class_name BalanceAutoplayBot
extends Node
## Test-only campaign driver used for repeatable balance smoke runs. It is never
## referenced by a shipping scene; QA injects it into MainFlow at runtime.

signal finished(report: Dictionary)

var flow: MainFlow
var elapsed_seconds := 0.0
var deaths := 0
var stage_results: Array[Dictionary] = []
var _last_flow_state := ""
var _state_time := 0.0
var _attack_cooldown := 0.0
var _release_attack := false
var _done := false
var _report: Dictionary = {}


func _ready() -> void:
	flow = get_tree().current_scene as MainFlow
	EventBus.player_died.connect(_on_player_died)


func _process(delta: float) -> void:
	if _done or flow == null:
		return
	elapsed_seconds += delta
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _release_attack:
		Input.action_release(&"attack_p1")
		_release_attack = false
	var state := flow.get_flow_state_name()
	if state != _last_flow_state:
		_on_flow_changed(state)
		_last_flow_state = state
		_state_time = 0.0
	else:
		_state_time += delta
	match state:
		"TITLE":
			_release_movement()
			if _state_time >= 0.25:
				flow.start_new_run()
		"INTRO":
			_release_movement()
			if _state_time >= 0.4:
				flow.call("_load_current_stage")
		"PLAYING":
			_drive_player()
		"CONTINUE":
			_release_movement()
			if _state_time >= 0.4:
				flow.accept_continue()
		"STAGE_CLEAR":
			_release_movement()
			if _state_time >= 0.5:
				flow.call("_advance_after_stage_clear")
		"ENDING":
			_finish(true, "campaign_complete")
		"GAME_OVER":
			_finish(false, "out_of_credits")


func _drive_player() -> void:
	var player := flow.player
	if player == null or player.is_dead:
		_release_movement()
		return
	var target := _nearest_enemy(player)
	if target == null:
		_set_movement(Vector2.RIGHT)
		return
	var offset := target.global_position - player.global_position
	var movement := Vector2.ZERO
	if absf(offset.x) > 42.0:
		movement.x = signf(offset.x)
	if absf(offset.y) > 7.0:
		movement.y = signf(offset.y)
	_set_movement(movement.normalized())
	if absf(offset.x) <= 50.0 and absf(offset.y) <= 10.0 and _attack_cooldown <= 0.0:
		Input.action_press(&"attack_p1")
		_release_attack = true
		_attack_cooldown = 0.18


func _nearest_enemy(player: Player) -> Enemy:
	var nearest: Enemy = null
	var nearest_distance := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dead:
			continue
		var distance := player.global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _set_movement(direction: Vector2) -> void:
	_set_action(&"move_left_p1", direction.x < -0.2)
	_set_action(&"move_right_p1", direction.x > 0.2)
	_set_action(&"move_up_p1", direction.y < -0.2)
	_set_action(&"move_down_p1", direction.y > 0.2)


func _set_action(action: StringName, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _release_movement() -> void:
	_set_movement(Vector2.ZERO)
	Input.action_release(&"attack_p1")
	_release_attack = false


func _on_flow_changed(state: String) -> void:
	if state != "STAGE_CLEAR" or flow.player == null:
		return
	stage_results.append({
		"stage": GameState.current_stage_index + 1,
		"hp": flow.player.hp,
		"lives": GameState.lives,
		"continues_left": GameState.continues,
		"score": GameState.score,
		"elapsed": snappedf(elapsed_seconds, 0.1),
	})


func _on_player_died() -> void:
	deaths += 1


func _finish(success: bool, reason: String) -> void:
	if _done:
		return
	_done = true
	_release_movement()
	_report = {
		"success": success,
		"reason": reason,
		"elapsed": snappedf(elapsed_seconds, 0.1),
		"deaths": deaths,
		"continues_used": 3 - GameState.continues,
		"lives_left": GameState.lives,
		"score": GameState.score,
		"stages": stage_results,
	}
	Engine.time_scale = 1.0
	finished.emit(_report)


func get_report() -> Dictionary:
	return _report if _done else {
		"running": true,
		"flow": flow.get_flow_state_name() if flow else "missing",
		"stage": GameState.current_stage_index + 1,
		"elapsed": snappedf(elapsed_seconds, 0.1),
		"deaths": deaths,
		"continues_used": 3 - GameState.continues,
		"lives_left": GameState.lives,
	}
