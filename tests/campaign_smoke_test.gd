extends Node
## Full-campaign smoke run: loads MainFlow, injects the test-only autoplay bot
## and prints its report. Run fast with:
##   godot --headless --fixed-fps 60 --path . res://tests/campaign_smoke_test.tscn

const MAIN := preload("res://scenes/main.tscn")
const MAX_SECONDS := 1800.0

var _bot: BalanceAutoplayBot
var _elapsed := 0.0
var _last_report := 0.0


func _ready() -> void:
	var main := MAIN.instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = main
	_bot = BalanceAutoplayBot.new()
	get_tree().root.add_child(_bot)
	_bot.finished.connect(_on_finished)
	EventBus.time_over.connect(_on_time_over)
	EventBus.player_died.connect(_on_player_died)


func _on_time_over() -> void:
	print("TIME OVER at stage %d" % (GameState.current_stage_index + 1))


func _on_player_died() -> void:
	var bosses := get_tree().get_nodes_in_group("bosses")
	print("death at stage %d (boss fight: %s)" % [GameState.current_stage_index + 1, not bosses.is_empty()])


func _process(delta: float) -> void:
	_elapsed += delta
	if _bot and _elapsed - _last_report >= 60.0:
		_last_report = _elapsed
		print("progress: ", _bot.get_report())
	if _elapsed >= MAX_SECONDS:
		print("CAMPAIGN TIMEOUT: ", _bot.get_report() if _bot else {})
		get_tree().quit(2)


func _on_finished(report: Dictionary) -> void:
	print("CAMPAIGN REPORT: ", report)
	get_tree().quit(0 if report.get("success", false) else 1)
