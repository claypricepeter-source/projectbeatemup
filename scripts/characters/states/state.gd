class_name FighterState
extends Node
## Base class for FighterStateMachine states.

var fighter: Fighter
var machine: FighterStateMachine


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
