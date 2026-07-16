class_name FighterStateMachine
extends Node
## Minimal FSM. Child nodes are FighterState instances; one is active at a time.

@export var initial_state: FighterState

var current: FighterState


func setup(fighter: Fighter) -> void:
	for child in get_children():
		if child is FighterState:
			child.fighter = fighter
			child.machine = self
	current = initial_state
	current.enter()


func _physics_process(delta: float) -> void:
	if current:
		current.physics_update(delta)


func transition(state_name: String) -> void:
	var next := get_node_or_null(state_name) as FighterState
	if next == null or next == current:
		return
	current.exit()
	current = next
	current.enter()
