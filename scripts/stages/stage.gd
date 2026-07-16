class_name Stage
extends Node2D
## Stage root: owns the walkable depth band and hands it to fighters.

@export var walk_min_x := 0.0
@export var walk_max_x := 100000.0
@export var walk_min_y := 200.0
@export var walk_max_y := 320.0


func _ready() -> void:
	for p in get_tree().get_nodes_in_group("fighters"):
		var fighter := p as Fighter
		if fighter:
			apply_bounds(fighter)


func apply_bounds(fighter: Fighter) -> void:
	fighter.walk_min_x = walk_min_x
	fighter.walk_max_x = walk_max_x
	fighter.walk_min_y = walk_min_y
	fighter.walk_max_y = walk_max_y
