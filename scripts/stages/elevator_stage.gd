class_name ElevatorStage
extends Stage
## Stage 4: Elevator Ascent / Penthouse Showdown.
## Centrally locks the camera, scrolls the elevator shaft background vertically
## downward, programmatically spawns enemy waves dropping from above, and stops
## at the penthouse to spawn the final boss Victor Bayshore.

const BG_TEXTURE: Texture2D = preload("res://assets/backgrounds/elevator/elevator_shaft_bg.png")
const BOSS_SCENE: PackedScene = preload("res://scenes/characters/bosses/victor.tscn")

const WAVES: Array[StringName] = [
	&"res://resources/waves/stage_4_wave_1.tres",
	&"res://resources/waves/stage_4_wave_2.tres",
	&"res://resources/waves/stage_4_wave_3.tres",
	&"res://resources/waves/stage_4_wave_4.tres"
]

@onready var camera: CameraDirector = $Camera
@onready var entities: Node2D = $Entities

var _scroll_offset := 0.0
var _scroll_speed := 120.0 # pixels per second
var _current_wave_index := 0
var _wave_data: WaveData = null
var _alive_enemies: Array[Enemy] = []
var _spawning := false
var _boss_spawned := false


func _ready() -> void:
	super()
	AudioManager.play_music(&"stage_4")
	camera.lock(320.0)
	
	# Start first wave after 3 seconds of elevator ride
	get_tree().create_timer(3.0).timeout.connect(_start_next_wave)


func _process(delta: float) -> void:
	# Scroll the background vertically downward
	_scroll_offset = fmod(_scroll_offset + _scroll_speed * delta, 360.0)
	queue_redraw()


func _draw() -> void:
	# 1. Draw scrolling background
	var bg_h := 360.0
	draw_texture(BG_TEXTURE, Vector2(0, _scroll_offset - bg_h))
	draw_texture(BG_TEXTURE, Vector2(0, _scroll_offset))
	
	# 2. Draw elevator platform
	# Platform bounds: x in [60, 580], y in [192, 310]
	draw_rect(Rect2(56, 192, 528, 118), Color(0.24, 0.25, 0.28, 1))
	draw_rect(Rect2(60, 196, 520, 110), Color(0.35, 0.36, 0.4, 1))
	
	# 3. Draw hazard stripes on left/right edges
	# Left border
	for y in range(196, 306, 10):
		var stripe_color := Color(0.9, 0.7, 0.1, 1) if int(y / 10) % 2 == 0 else Color(0.1, 0.1, 0.1, 1)
		draw_rect(Rect2(56, float(y), 8, 10), stripe_color)
	# Right border
	for y in range(196, 306, 10):
		var stripe_color := Color(0.9, 0.7, 0.1, 1) if int(y / 10) % 2 == 0 else Color(0.1, 0.1, 0.1, 1)
		draw_rect(Rect2(576, float(y), 8, 10), stripe_color)

	# 4. Draw metal cables/chains
	draw_line(Vector2(70, 0), Vector2(70, 196), Color(0.15, 0.16, 0.18, 1), 6.0)
	draw_line(Vector2(70, 0), Vector2(70, 196), Color(0.45, 0.47, 0.5, 1), 2.0)
	draw_line(Vector2(570, 0), Vector2(570, 196), Color(0.15, 0.16, 0.18, 1), 6.0)
	draw_line(Vector2(570, 0), Vector2(570, 196), Color(0.45, 0.47, 0.5, 1), 2.0)


func _start_next_wave() -> void:
	if _current_wave_index >= WAVES.size():
		# Reached the top! Penthouse landing.
		_scroll_speed = 0.0
		AudioManager.play_music(&"boss")
		get_tree().create_timer(2.0).timeout.connect(_spawn_boss)
		return
		
	_spawning = true
	_wave_data = load(WAVES[_current_wave_index]) as WaveData
	_alive_enemies.clear()
	
	# Spawn lineup dropping from above
	for i in _wave_data.enemy_scenes.size():
		var enemy := _wave_data.enemy_scenes[i].instantiate() as Enemy
		if enemy == null:
			continue
			
		if i < _wave_data.enemy_stats.size() and _wave_data.enemy_stats[i] != null:
			enemy.stats = _wave_data.enemy_stats[i]
			
		entities.add_child(enemy)
		apply_bounds(enemy)
		
		# Enter the shared knockdown state first, then override its launch values
		# so the enemy visibly drops from above instead of popping upward.
		var spawn_pos := _wave_data.spawn_positions[i]
		enemy.global_position = spawn_pos
		enemy.state_machine.transition("Knockdown")
		enemy.air_height = 240.0
		enemy.air_velocity = -10.0
		enemy.died.connect(func() -> void: _on_enemy_died(enemy))
		
		_alive_enemies.append(enemy)
		
		if _wave_data.spawn_delay > 0.0 and i < _wave_data.enemy_scenes.size() - 1:
			await get_tree().create_timer(_wave_data.spawn_delay).timeout
			
	_spawning = false


func _on_enemy_died(enemy: Enemy) -> void:
	_alive_enemies.erase(enemy)
	if _alive_enemies.is_empty() and not _spawning:
		# Wave cleared! Transition to next wave
		_current_wave_index += 1
		EventBus.wave_cleared.emit()
		get_tree().create_timer(3.0).timeout.connect(_start_next_wave)


func _spawn_boss() -> void:
	if _boss_spawned:
		return
	_boss_spawned = true
	
	var boss := BOSS_SCENE.instantiate() as Enemy
	entities.add_child(boss)
	apply_bounds(boss)
	
	# Boss crashes down from the skylight!
	boss.global_position = Vector2(320.0, 240.0)
	boss.state_machine.transition("Knockdown")
	boss.air_height = 260.0
	boss.air_velocity = -20.0
	
	boss.died.connect(_on_boss_died)


func _on_boss_died() -> void:
	# End of stage and game clear routing
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		EventBus.stage_cleared.emit()
	)
