class_name Hurtbox
extends Area2D
## Receives hits. Owned by a Fighter scene; layer identifies the team
## (2 = player, 3 = enemy — see AGENTS.md §7.5).

var fighter: Fighter


func _ready() -> void:
	fighter = owner as Fighter
