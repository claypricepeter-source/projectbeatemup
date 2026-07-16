class_name EnemyStats
extends Resource
## Data-driven enemy tuning (AGENTS.md §7.4). Palette swaps are a new .tres
## with a tint and stat changes — no new scenes or scripts.

@export var display_name := "Enemy"
@export var max_hp := 25
@export var move_speed := Vector2(80.0, 60.0)
@export var damage := 5
@export var attack_range := 60.0
@export var recover_time := 0.5
@export var retreat_time := 0.6
@export var points := 100
@export var tint := Color.WHITE
