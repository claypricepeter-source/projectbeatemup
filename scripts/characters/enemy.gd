class_name Enemy
extends Fighter
## AI-controlled fighter driven by an EnemyStats resource.

const MAX_ATTACKERS := 2

@export var stats: EnemyStats
@export var separation_radius := 44.0
@export var separation_strength := 85.0


func _ready() -> void:
	if stats:
		max_hp = stats.max_hp
		move_speed = stats.move_speed
		sprite.self_modulate = stats.tint
	super()


func target_player() -> Fighter:
	var best: Fighter = null
	var best_d := INF
	for p in get_tree().get_nodes_in_group("players"):
		var f := p as Fighter
		if f == null or f.is_dead:
			continue
		var d := global_position.distance_squared_to(f.global_position)
		if d < best_d:
			best_d = d
			best = f
	return best


## Classic brawler courtesy rule: at most MAX_ATTACKERS enemies may be in
## their Attack state at once; the rest hold position (AGENTS.md §4.2).
func attackers_count() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy and enemy.is_committed_attack():
			n += 1
	return n


func is_committed_attack() -> bool:
	if state_machine.current == null:
		return false
	return state_machine.current.name in [&"Attack", &"Dash", &"Counter"]


## Gentle steering prevents enemies from occupying the same feet position while
## preserving deliberate formation and the two-attacker courtesy rule.
func apply_movement(delta: float) -> void:
	var intended_velocity := velocity
	if not is_dead:
		velocity += _separation_velocity()
		velocity = velocity.limit_length(maxf(intended_velocity.length(), maxf(move_speed.x * 1.8, 220.0)))
	super(delta)
	# Separation is steering for this frame, not persistent acceleration. Restoring
	# the state's intended velocity also preserves boss dash/knockback speeds.
	velocity = intended_velocity


func _separation_velocity() -> Vector2:
	var push := Vector2.ZERO
	for node in get_tree().get_nodes_in_group("enemies"):
		var other := node as Enemy
		if other == null or other == self or other.is_dead:
			continue
		var diff := global_position - other.global_position
		if absf(diff.y) > 28.0:
			continue
		var distance := diff.length()
		if distance >= separation_radius:
			continue
		if distance < 0.01:
			diff = Vector2(1.0 if get_instance_id() > other.get_instance_id() else -1.0, 0.25)
			distance = diff.length()
		push += diff.normalized() * (1.0 - distance / separation_radius)
	return push.limit_length(1.0) * separation_strength


func finish_death() -> void:
	EventBus.enemy_died.emit(stats.points if stats else 0)
	super()
