class_name CameraDirector
extends Camera2D
## Follows the average X of all players; Y stays fixed. Camera limits are set
## per stage in the scene. lock()/unlock() will drive wave fights in Phase 3.

var _players: Array[Node2D] = []
var _locked := false
var _stage: Stage
var _shake_strength := 0.0
var _shake_time := 0.0


func _ready() -> void:
	add_to_group(&"camera_directors")
	_players.assign(get_tree().get_nodes_in_group("players"))
	_stage = get_parent() as Stage


func _process(delta: float) -> void:
	var valid_players: Array[Node2D] = []
	for player in _players:
		if is_instance_valid(player) and not player.is_queued_for_deletion():
			valid_players.append(player)
	_players = valid_players
	if not _locked and not _players.is_empty():
		var x := 0.0
		for p in _players:
			x += p.global_position.x
		global_position.x = x / _players.size()
	_update_shake(delta)


func shake(strength: float, duration: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_time = maxf(_shake_time, duration)


func _update_shake(delta: float) -> void:
	if _shake_time <= 0.0:
		offset = Vector2.ZERO
		return
	_shake_time = maxf(_shake_time - delta, 0.0)
	offset = Vector2(
		roundf(randf_range(-_shake_strength, _shake_strength)),
		roundf(randf_range(-_shake_strength, _shake_strength)))


func lock(x_center: float) -> void:
	_locked = true
	global_position.x = x_center
	if _stage:
		for node in _players:
			var player := node as Fighter
			if is_instance_valid(player) and not player.is_queued_for_deletion():
				player.walk_min_x = maxf(_stage.walk_min_x, x_center - 296.0)
				player.walk_max_x = minf(_stage.walk_max_x, x_center + 296.0)


func unlock() -> void:
	_locked = false
	if _stage:
		for node in _players:
			var player := node as Fighter
			if is_instance_valid(player) and not player.is_queued_for_deletion():
				_stage.apply_bounds(player)


func is_locked() -> bool:
	return _locked
