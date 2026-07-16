class_name WaveData
extends Resource
## A data-authored enemy lineup and its spawn positions for one camera-lock fight.

@export var enemy_scenes: Array[PackedScene] = []
@export var enemy_stats: Array[EnemyStats] = []
@export var spawn_positions: Array[Vector2] = []
@export var spawn_delay := 0.15


func is_valid() -> bool:
	return not enemy_scenes.is_empty() \
			and enemy_scenes.size() == spawn_positions.size() \
			and (enemy_stats.is_empty() or enemy_stats.size() == enemy_scenes.size())
