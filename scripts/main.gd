class_name MainFlow
extends Node2D
## Campaign shell: title, story cards, stage loading, pause, continues, and
## end-of-stage routing. Add future stages to STAGE_SCENES and INTRO_CARDS.

const STAGE_SCENES: Array[PackedScene] = [
	preload("res://scenes/stages/stage_1.tscn"),
	preload("res://scenes/stages/stage_2.tscn"),
	preload("res://scenes/stages/stage_3.tscn"),
]
const INTRO_CARDS: Array[Dictionary] = [
	{
		"heading": "STAGE 1",
		"title": "SECOND AVENUE AT NIGHT",
		"body": "A shakedown outside Sean's favourite coffee shop\nturns a quiet Owen Sound night into a call to action.\n\nThe Bayshore Syndicate picked the wrong town.",
	},
	{
		"heading": "STAGE 2",
		"title": "THE HARBOUR",
		"body": "A beaten punk gives up the Syndicate's route:\ncontraband moves through the Owen Sound docks.\n\nSean follows the lights down to Pier 2.",
	},
	{
		"heading": "STAGE 3",
		"title": "HARRISON PARK TO THE MILL DAM",
		"body": "Marta names the man behind the Syndicate:\nVictor Bayshore is waiting beyond Harrison Park.\n\nSean follows the river toward the Mill Dam.",
	},
]
const CONTINUE_SECONDS := 10.0

enum FlowState { TITLE, INTRO, PLAYING, DEATH, CONTINUE, PAUSED, GAME_OVER, STAGE_CLEAR, ENDING }

@onready var stage_slot: Node2D = $StageSlot
@onready var title_screen: Control = $MenuUI/TitleScreen
@onready var title_high_score: Label = $MenuUI/TitleScreen/Content/HighScore
@onready var start_button: Button = $MenuUI/TitleScreen/Content/Menu/Start
@onready var quit_button: Button = $MenuUI/TitleScreen/Content/Menu/Quit
@onready var intro_screen: Control = $MenuUI/StageIntro
@onready var intro_heading: Label = $MenuUI/StageIntro/Card/Margin/Content/Heading
@onready var intro_title: Label = $MenuUI/StageIntro/Card/Margin/Content/Title
@onready var intro_body: Label = $MenuUI/StageIntro/Card/Margin/Content/Body
@onready var pause_screen: Control = $MenuUI/PauseMenu
@onready var resume_button: Button = $MenuUI/PauseMenu/Card/Margin/Content/Resume
@onready var title_button: Button = $MenuUI/PauseMenu/Card/Margin/Content/Title
@onready var game_over_screen: Control = $MenuUI/GameOver
@onready var game_over_score: Label = $MenuUI/GameOver/Card/Margin/Content/Score
@onready var game_over_high_score: Label = $MenuUI/GameOver/Card/Margin/Content/HighScore
@onready var flow_screen: Control = $FlowUI/Screen
@onready var flow_title: Label = $FlowUI/Screen/Panel/Margin/VBox/Title
@onready var flow_body: Label = $FlowUI/Screen/Panel/Margin/VBox/Body
@onready var flow_prompt: Label = $FlowUI/Screen/Panel/Margin/VBox/Prompt

var stage: Stage
var player: Player
var flow_state := FlowState.TITLE
var stage_clear_bonus := 0
var continue_time_left := CONTINUE_SECONDS
var _respawn_position := Vector2.ZERO
var _input_lock := 0.0


func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	EventBus.stage_cleared.connect(_on_stage_cleared)
	start_button.pressed.connect(start_new_run)
	quit_button.pressed.connect(_quit_game)
	resume_button.pressed.connect(resume_game)
	title_button.pressed.connect(show_title)
	show_title()


func _process(delta: float) -> void:
	_input_lock = maxf(_input_lock - delta, 0.0)
	if Input.is_action_just_pressed(&"pause"):
		if flow_state == FlowState.PLAYING:
			show_pause()
			return
		if flow_state == FlowState.PAUSED:
			resume_game()
			return
	if flow_state == FlowState.CONTINUE:
		continue_time_left = maxf(continue_time_left - delta, 0.0)
		flow_body.text = "CONTINUES %d\nTIME %02d" % [GameState.continues, ceili(continue_time_left)]
		if continue_time_left <= 0.0:
			show_game_over()
			return
	if _input_lock > 0.0 or not Input.is_action_just_pressed(&"attack_p1"):
		return
	AudioManager.play_sfx(&"ui_confirm", -8.0)
	match flow_state:
		FlowState.TITLE, FlowState.PAUSED:
			_activate_focused_button()
		FlowState.INTRO:
			_load_current_stage()
		FlowState.CONTINUE:
			accept_continue()
		FlowState.GAME_OVER:
			show_title()
		FlowState.STAGE_CLEAR:
			_advance_after_stage_clear()
		FlowState.ENDING:
			show_title()


func show_title() -> void:
	GameState.commit_high_score()
	AudioManager.play_music(&"title")
	_clear_stage()
	flow_state = FlowState.TITLE
	_input_lock = 0.25
	_hide_all_screens()
	title_high_score.text = "HIGH SCORE  %06d" % GameState.high_score
	title_screen.visible = true
	start_button.grab_focus.call_deferred()


func start_new_run() -> void:
	if flow_state != FlowState.TITLE:
		return
	GameState.reset_run()
	show_stage_intro()


func show_stage_intro() -> void:
	flow_state = FlowState.INTRO
	_input_lock = 0.35
	_hide_all_screens()
	var card: Dictionary = INTRO_CARDS[mini(GameState.current_stage_index, INTRO_CARDS.size() - 1)]
	intro_heading.text = String(card["heading"])
	intro_title.text = String(card["title"])
	intro_body.text = String(card["body"])
	intro_screen.visible = true


func _load_current_stage() -> void:
	if GameState.current_stage_index < 0 or GameState.current_stage_index >= STAGE_SCENES.size():
		show_title()
		return
	_clear_stage()
	_hide_all_screens()
	stage = STAGE_SCENES[GameState.current_stage_index].instantiate() as Stage
	stage_slot.add_child(stage)
	AudioManager.play_music(StringName("stage_%d" % (GameState.current_stage_index + 1)))
	player = stage.get_node("Entities/Player") as Player
	_respawn_position = player.position
	flow_state = FlowState.PLAYING
	_set_stage_paused(false)


func _on_player_died() -> void:
	if flow_state != FlowState.PLAYING:
		return
	flow_state = FlowState.DEATH
	_respawn_position = player.position
	GameState.lose_life()
	await get_tree().create_timer(0.8).timeout
	if flow_state != FlowState.DEATH:
		return
	if GameState.lives > 0:
		player.respawn(_respawn_position)
		flow_state = FlowState.PLAYING
	elif GameState.continues > 0:
		show_continue()
	else:
		show_game_over()


func show_continue() -> void:
	flow_state = FlowState.CONTINUE
	continue_time_left = CONTINUE_SECONDS
	_input_lock = 0.35
	_set_stage_paused(true)
	flow_title.text = "CONTINUE?"
	flow_body.text = "CONTINUES %d\nTIME %02d" % [GameState.continues, int(CONTINUE_SECONDS)]
	flow_prompt.text = "PRESS ATTACK"
	flow_screen.visible = true


func accept_continue() -> void:
	if flow_state != FlowState.CONTINUE or not GameState.use_continue():
		return
	flow_screen.visible = false
	_set_stage_paused(false)
	player.respawn(_respawn_position)
	flow_state = FlowState.PLAYING


func show_pause() -> void:
	if flow_state != FlowState.PLAYING:
		return
	AudioManager.play_sfx(&"ui_pause", -8.0)
	flow_state = FlowState.PAUSED
	_input_lock = 0.2
	_set_stage_paused(true)
	pause_screen.visible = true
	resume_button.grab_focus.call_deferred()


func resume_game() -> void:
	if flow_state != FlowState.PAUSED:
		return
	AudioManager.play_sfx(&"ui_confirm", -8.0)
	pause_screen.visible = false
	_set_stage_paused(false)
	flow_state = FlowState.PLAYING
	_input_lock = 0.2


func show_game_over() -> void:
	flow_state = FlowState.GAME_OVER
	AudioManager.play_music(&"game_over")
	_input_lock = 0.35
	_set_stage_paused(true)
	GameState.commit_high_score()
	flow_screen.visible = false
	game_over_score.text = "FINAL SCORE  %06d" % GameState.score
	game_over_high_score.text = "HIGH SCORE   %06d" % GameState.high_score
	game_over_screen.visible = true


func _on_stage_cleared() -> void:
	if flow_state != FlowState.PLAYING:
		return
	flow_state = FlowState.STAGE_CLEAR
	AudioManager.play_music(&"clear")
	stage_clear_bonus = player.hp * 10
	GameState.add_score(stage_clear_bonus)
	GameState.commit_high_score()
	_input_lock = 0.35
	_set_stage_paused(true)
	flow_title.text = "STAGE %d CLEAR" % (GameState.current_stage_index + 1)
	flow_body.text = "HEALTH %d x 10\nBONUS %06d\nTOTAL %06d" % [player.hp, stage_clear_bonus, GameState.score]
	flow_prompt.text = "PRESS ATTACK TO CONTINUE"
	flow_screen.visible = true


func _advance_after_stage_clear() -> void:
	GameState.next_stage()
	if GameState.current_stage_index < STAGE_SCENES.size():
		show_stage_intro()
	else:
		show_ending()


func show_ending() -> void:
	flow_state = FlowState.ENDING
	AudioManager.play_music(&"ending")
	_input_lock = 0.35
	_clear_stage()
	_hide_all_screens()
	intro_heading.text = "OWEN SOUND — MORNING"
	intro_title.text = "QUIET WATER"
	intro_body.text = "Victor drops into the Mill Dam fish ladder.\nBy sunrise, the Bayshore Syndicate is finished.\n\nThe town wakes up quiet again. Sean gets his coffee."
	intro_screen.visible = true


func _hide_all_screens() -> void:
	title_screen.visible = false
	intro_screen.visible = false
	pause_screen.visible = false
	game_over_screen.visible = false
	flow_screen.visible = false


func _clear_stage() -> void:
	if is_instance_valid(stage):
		stage.queue_free()
	stage = null
	player = null


func _set_stage_paused(paused: bool) -> void:
	if is_instance_valid(stage):
		stage.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT


func _activate_focused_button() -> void:
	var focused := get_viewport().gui_get_focus_owner() as Button
	if focused and focused.visible and not focused.disabled:
		focused.pressed.emit()


func _quit_game() -> void:
	get_tree().quit()


func get_flow_state_name() -> String:
	return FlowState.keys()[flow_state]
