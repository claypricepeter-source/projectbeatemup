extends Node
## Run-scoped score and credit data plus the small persistent save file.

const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "scores"
const HIGH_SCORE_KEY := "high_score"
## Extra life every EXTEND_EVERY points (SoR2-style score extends).
const EXTEND_EVERY := 50000
const MAX_LIVES := 9

var score := 0
var high_score := 0
var lives := 3
var continues := 3
var current_stage_index := 0
var next_extend := EXTEND_EVERY
var _last_save_ms := -100000


func _ready() -> void:
	_load_save()
	EventBus.enemy_died.connect(_on_enemy_died)


func reset_run() -> void:
	score = 0
	lives = 3
	continues = 3
	current_stage_index = 0
	next_extend = EXTEND_EVERY
	EventBus.score_changed.emit(score)
	EventBus.lives_changed.emit(lives, continues)


func add_score(amount: int) -> void:
	score = maxi(score + amount, 0)
	var previous_high_score := high_score
	high_score = maxi(high_score, score)
	EventBus.score_changed.emit(score)
	while score >= next_extend:
		next_extend += EXTEND_EVERY
		lives = mini(lives + 1, MAX_LIVES)
		EventBus.lives_changed.emit(lives, continues)
		EventBus.extra_life.emit()
	# Per-hit scoring raises the score constantly; throttle save-file writes.
	if high_score > previous_high_score and Time.get_ticks_msec() - _last_save_ms > 5000:
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
	_last_save_ms = Time.get_ticks_msec()
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
