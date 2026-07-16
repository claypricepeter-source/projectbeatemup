extends Node
## Run-scoped score and credit data plus the small persistent save file.

const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "scores"
const HIGH_SCORE_KEY := "high_score"

var score := 0
var high_score := 0
var lives := 3
var continues := 3
var current_stage_index := 0


func _ready() -> void:
	_load_save()
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
	var previous_high_score := high_score
	high_score = maxi(high_score, score)
	EventBus.score_changed.emit(score)
	if high_score > previous_high_score:
		commit_high_score()


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


func next_stage() -> int:
	current_stage_index += 1
	return current_stage_index


func commit_high_score() -> void:
	if score > high_score:
		high_score = score
	var save := ConfigFile.new()
	save.set_value(SAVE_SECTION, HIGH_SCORE_KEY, high_score)
	var error := save.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save high score (error %d)." % error)


func _load_save() -> void:
	var save := ConfigFile.new()
	var error := save.load(SAVE_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_warning("Could not load high score (error %d)." % error)
		return
	high_score = maxi(int(save.get_value(SAVE_SECTION, HIGH_SCORE_KEY, 0)), 0)


func _on_enemy_died(points) -> void:
	add_score(int(points))
