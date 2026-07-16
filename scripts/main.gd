class_name MainFlow
extends Node2D
## Minimal Phase 3 run flow. Phase 4 expands this into title cards, persistent
## high scores, and campaign stage transitions.

const STAGE_1_SCENE := preload("res://scenes/stages/stage_1.tscn")
const CONTINUE_SECONDS := 10.0

enum FlowState { PLAYING, DEATH, CONTINUE, GAME_OVER, STAGE_CLEAR }

@onready var stage_slot: Node2D = $StageSlot
@onready var flow_screen: Control = $FlowUI/Screen
@onready var flow_title: Label = $FlowUI/Screen/Panel/Margin/VBox/Title
@onready var flow_body: Label = $FlowUI/Screen/Panel/Margin/VBox/Body
@onready var flow_prompt: Label = $FlowUI/Screen/Panel/Margin/VBox/Prompt

var stage: Stage
var player: Player
var flow_state := FlowState.PLAYING
var stage_clear_bonus := 0
var continue_time_left := CONTINUE_SECONDS
var _respawn_position := Vector2.ZERO
var _input_lock := 0.0


func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	EventBus.stage_cleared.connect(_on_stage_cleared)
	GameState.reset_run()
	_load_stage()


func _process(delta: float) -> void:
	_input_lock = maxf(_input_lock - delta, 0.0)
	if flow_state == FlowState.CONTINUE:
		continue_time_left = maxf(continue_time_left - delta, 0.0)
		flow_body.text = "CONTINUES %d\nTIME %02d" % [GameState.continues, ceili(continue_time_left)]
		if continue_time_left <= 0.0:
			show_game_over()
			return
	if _input_lock > 0.0 or not Input.is_action_just_pressed(&"attack_p1"):
		return
	match flow_state:
		FlowState.CONTINUE:
			accept_continue()
		FlowState.GAME_OVER, FlowState.STAGE_CLEAR:
			get_tree().reload_current_scene()


func _load_stage() -> void:
	stage = STAGE_1_SCENE.instantiate() as Stage
	stage_slot.add_child(stage)
	player = stage.get_node("Entities/Player") as Player
	_respawn_position = player.position


func _on_player_died() -> void:
	if flow_state != FlowState.PLAYING:
		return
	flow_state = FlowState.DEATH
	_respawn_position = player.position
	GameState.lose_life()
	await get_tree().create_timer(0.8).timeout
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


func show_game_over() -> void:
	flow_state = FlowState.GAME_OVER
	_input_lock = 0.35
	_set_stage_paused(true)
	flow_title.text = "GAME OVER"
	flow_body.text = "FINAL SCORE\n%06d" % GameState.score
	flow_prompt.text = "PRESS ATTACK TO RETRY"
	flow_screen.visible = true


func _on_stage_cleared() -> void:
	if flow_state != FlowState.PLAYING:
		return
	flow_state = FlowState.STAGE_CLEAR
	stage_clear_bonus = player.hp * 10
	GameState.add_score(stage_clear_bonus)
	_input_lock = 0.35
	_set_stage_paused(true)
	flow_title.text = "STAGE 1 CLEAR"
	flow_body.text = "HEALTH %d x 10\nBONUS %06d\nTOTAL %06d" % [player.hp, stage_clear_bonus, GameState.score]
	flow_prompt.text = "PRESS ATTACK TO PLAY AGAIN"
	flow_screen.visible = true


func _set_stage_paused(paused: bool) -> void:
	if is_instance_valid(stage):
		stage.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT


func get_flow_state_name() -> String:
	return FlowState.keys()[flow_state]
