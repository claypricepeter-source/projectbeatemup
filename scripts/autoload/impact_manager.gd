extends Node
## Central connected-hit feedback. The unscaled timer guarantees that the game
## always returns to normal speed, including when another hit extends the pause.

const HIT_PAUSE_SCALE := 0.08
const NORMAL_HIT_SECONDS := 0.04
const KNOCKDOWN_HIT_SECONDS := 0.055
const PLAYER_KO_SCALE := 0.28
const PLAYER_KO_SECONDS := 0.9

var _pause_generation := 0
var _ko_generation := 0
var _hit_pause_active := false
var _ko_active := false


func connected_hit(target: Fighter, knockdown_hit: bool) -> void:
	if is_instance_valid(target):
		target.flash_hit()
	_trigger_hit_pause(KNOCKDOWN_HIT_SECONDS if knockdown_hit else NORMAL_HIT_SECONDS)
	if knockdown_hit:
		AudioManager.play_sfx(&"knockdown", -3.0)
		get_tree().call_group(&"camera_directors", &"shake", 4.0, 0.18)


func _trigger_hit_pause(duration: float) -> void:
	_pause_generation += 1
	var generation := _pause_generation
	_hit_pause_active = true
	Engine.time_scale = HIT_PAUSE_SCALE
	await get_tree().create_timer(duration, true, false, true).timeout
	if generation == _pause_generation:
		_hit_pause_active = false
		Engine.time_scale = PLAYER_KO_SCALE if _ko_active else 1.0


func player_ko_slowdown() -> void:
	_ko_generation += 1
	var generation := _ko_generation
	_ko_active = true
	if not _hit_pause_active:
		Engine.time_scale = PLAYER_KO_SCALE
	await get_tree().create_timer(PLAYER_KO_SECONDS, true, false, true).timeout
	if generation == _ko_generation:
		_ko_active = false
		if not _hit_pause_active:
			Engine.time_scale = 1.0


func _exit_tree() -> void:
	_pause_generation += 1
	_ko_generation += 1
	_hit_pause_active = false
	_ko_active = false
	Engine.time_scale = 1.0
