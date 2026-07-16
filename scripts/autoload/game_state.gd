extends Node
## Run-scoped score and credit data. Persistence and full campaign transitions
## are added in Phase 4; Phase 3 uses this for enemies, Cash, lives, and continues.

var score := 0
var high_score := 0
var lives := 3
var continues := 3
var current_stage_index := 0


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)


func reset_run() -> void:
	score = 0
	lives = 3
	continues = 3
	current_stage_index = 0
	EventBus.score_changed.emit(score)
	EventBus.lives_changed.emit(lives, continues)


func add_score(amount: int) -> void:
	score = maxi(score + amount, 0)
	high_score = maxi(high_score, score)
	EventBus.score_changed.emit(score)


func lose_life() -> int:
	lives = maxi(lives - 1, 0)
	EventBus.lives_changed.emit(lives, continues)
	return lives


func use_continue() -> bool:
	if continues <= 0:
		return false
	continues -= 1
	lives = 3
	EventBus.lives_changed.emit(lives, continues)
	return true


func _on_enemy_died(points) -> void:
	add_score(int(points))
