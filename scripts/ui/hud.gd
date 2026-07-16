extends CanvasLayer
## HUD skeleton: player health bar plus a temporary bar for the last-hit enemy.

@onready var player_bar: ProgressBar = $Root/PlayerBox/PlayerBar
@onready var enemy_box: VBoxContainer = $Root/EnemyBox
@onready var enemy_bar: ProgressBar = $Root/EnemyBox/EnemyBar
@onready var enemy_label: Label = $Root/EnemyBox/EnemyLabel
@onready var go_indicator: Label = $Root/GoIndicator
@onready var score_label: Label = $Root/ScoreLabel
@onready var run_label: Label = $Root/RunLabel
@onready var pickup_feedback: Label = $Root/PickupFeedback
@onready var boss_box: VBoxContainer = $Root/BossBox
@onready var boss_bar: ProgressBar = $Root/BossBox/BossBar
@onready var hide_timer: Timer = $HideTimer

var _go_tween: Tween
var _pickup_tween: Tween


func _ready() -> void:
	EventBus.fighter_damaged.connect(_on_fighter_damaged)
	EventBus.wave_cleared.connect(_on_wave_cleared)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.lives_changed.connect(_on_lives_changed)
	EventBus.pickup_collected.connect(_on_pickup_collected)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	hide_timer.timeout.connect(func() -> void: enemy_box.visible = false)
	enemy_box.visible = false
	go_indicator.visible = false
	pickup_feedback.visible = false
	boss_box.visible = false
	_on_score_changed(GameState.score)
	_on_lives_changed(GameState.lives, GameState.continues)
	_init_player_bar.call_deferred()


func _init_player_bar() -> void:
	for p in get_tree().get_nodes_in_group("players"):
		var f := p as Fighter
		if f:
			player_bar.max_value = f.max_hp
			player_bar.value = f.hp
			return


func _on_fighter_damaged(f: Fighter) -> void:
	if f.is_in_group("players"):
		player_bar.max_value = f.max_hp
		player_bar.value = f.hp
		return
	if f.is_in_group("bosses"):
		return
	enemy_bar.max_value = f.max_hp
	enemy_bar.value = f.hp
	var enemy := f as Enemy
	enemy_label.text = enemy.stats.display_name if enemy and enemy.stats else "ENEMY"
	enemy_box.visible = true
	hide_timer.start(2.5)


func _on_wave_cleared() -> void:
	if _go_tween and _go_tween.is_valid():
		_go_tween.kill()
	go_indicator.visible = true
	go_indicator.modulate.a = 1.0
	_go_tween = create_tween()
	for pulse in 3:
		_go_tween.tween_property(go_indicator, "modulate:a", 0.3, 0.12)
		_go_tween.tween_property(go_indicator, "modulate:a", 1.0, 0.12)
	_go_tween.tween_interval(3.0)
	_go_tween.tween_property(go_indicator, "modulate:a", 0.0, 0.35)
	_go_tween.tween_callback(func() -> void: go_indicator.visible = false)


func _on_score_changed(score) -> void:
	score_label.text = "SCORE %06d" % int(score)


func _on_lives_changed(lives, continues) -> void:
	run_label.text = "LIVES %d   CONT %d" % [int(lives), int(continues)]


func _on_pickup_collected(kind) -> void:
	if _pickup_tween and _pickup_tween.is_valid():
		_pickup_tween.kill()
	match StringName(kind):
		&"coffee": pickup_feedback.text = "TIMBO'S COFFEE  +25 HP"
		&"cash_500": pickup_feedback.text = "CASH  +500"
		&"cash_100": pickup_feedback.text = "LOONIE STACK  +100"
		_: pickup_feedback.text = String(kind).to_upper()
	pickup_feedback.visible = true
	pickup_feedback.modulate.a = 1.0
	_pickup_tween = create_tween()
	_pickup_tween.tween_interval(1.1)
	_pickup_tween.tween_property(pickup_feedback, "modulate:a", 0.0, 0.3)
	_pickup_tween.tween_callback(func() -> void: pickup_feedback.visible = false)


func _on_boss_health_changed(ratio) -> void:
	var health_ratio := clampf(float(ratio), 0.0, 1.0)
	boss_bar.value = health_ratio
	boss_box.visible = health_ratio > 0.0
