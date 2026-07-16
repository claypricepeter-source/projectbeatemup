class_name CameraDirector
extends Camera2D
## Follows the average X of all players; Y stays fixed. Camera limits are set
## per stage in the scene. lock()/unlock() will drive wave fights in Phase 3.

var _players: Array[Node2D] = []
var _locked := false
var _stage: Stage


func _ready() -> void:
	_players.assign(get_tree().get_nodes_in_group("players"))
	_stage = get_parent() as Stage


func _process(_delta: float) -> void:
	if _locked or _players.is_empty():
		return
	var x := 0.0
	for p in _players:
		x += p.global_position.x
	global_position.x = x / _players.size()


func lock(x_center: float) -> void:
	_locked = true
	global_position.x = x_center
	if _stage:
		for node in _players:
			var player := node as Fighter
			if player:
				player.walk_min_x = maxf(_stage.walk_min_x, x_center - 296.0)
				player.walk_max_x = minf(_stage.walk_max_x, x_center + 296.0)


func unlock() -> void:
	_locked = false
	if _stage:
		for node in _players:
			var player := node as Fighter
			if player:
				_stage.apply_bounds(player)


func is_locked() -> bool:
	return _locked
