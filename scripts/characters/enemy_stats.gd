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

@export_group("Palette Variant")
@export var base_variant: EnemyStats
@export_range(0.1, 5.0, 0.05) var hp_multiplier := 1.0
@export_range(0.1, 5.0, 0.05) var damage_multiplier := 1.0
@export_range(0.1, 3.0, 0.05) var speed_multiplier := 1.0
@export_range(0.1, 5.0, 0.05) var points_multiplier := 1.0


func resolved() -> EnemyStats:
	if base_variant == null:
		return self
	var result := base_variant.duplicate() as EnemyStats
	result.display_name = display_name
	result.max_hp = maxi(roundi(float(base_variant.max_hp) * hp_multiplier), 1)
	result.move_speed = base_variant.move_speed * speed_multiplier
	result.damage = maxi(roundi(float(base_variant.damage) * damage_multiplier), 1)
	result.points = maxi(roundi(float(base_variant.points) * points_multiplier), 0)
	result.tint = tint
	result.base_variant = null
	return result
