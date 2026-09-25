class_name RoundTimer
extends Node
## SoR2 round timer. Counts down from 99; every wave cleared ("set", when the
## GO arrow flashes) refills it, as does losing a life. Reaching zero is TIME
## OVER and costs a life. Lives under the Stage, so pausing the stage (or the
## stage-clear tally) freezes it.

const START_TIME := 99
## Real seconds per timer count. SoR2's counter ticks slower than a clock.
const SECONDS_PER_COUNT := 1.5

var time_left := START_TIME
var running := true
var _accumulator := 0.0


func _ready() -> void:
	EventBus.wave_cleared.connect(refill)
	EventBus.player_respawned.connect(refill)
	EventBus.stage_cleared.connect(stop)
	EventBus.player_died.connect(stop)
	refill()


func refill() -> void:
	time_left = START_TIME
	_accumulator = 0.0
	running = true
	EventBus.timer_changed.emit(time_left)


func stop() -> void:
	running = false


func _physics_process(delta: float) -> void:
	if not running:
		return
	_accumulator += delta
	while _accumulator >= SECONDS_PER_COUNT and time_left > 0:
		_accumulator -= SECONDS_PER_COUNT
		time_left -= 1
		EventBus.timer_changed.emit(time_left)
	if time_left <= 0:
		running = false
		EventBus.time_over.emit()
		for node in get_tree().get_nodes_in_group("players"):
			var player := node as Player
			if player:
				player.time_over()
