class_name SlickRick
extends Enemy
## Stage 1 boss: knife flurries up close, lane dashes at range, and recurring
## two-Punk reinforcements. A third quick hit triggers an armored counter.

const PUNK_SCENE := preload("res://scenes/characters/enemies/punk.tscn")
const SUMMON_INTERVAL := 11.0

var hyper_armor := false
var dash_ready := true
var _boss_chain_hits := 0
var _boss_last_hit_ms := 0
var _summon_timer := 6.0


func _ready() -> void:
	super()
	EventBus.boss_health_changed.emit(1.0)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = SUMMON_INTERVAL
		summon_adds()


func take_hit(damage: int, knockdown_hit: bool, attacker: Fighter) -> void:
	if is_dead or invulnerable:
		return
	hp = maxi(hp - damage, 0)
	var dir := attacker.global_position.x - global_position.x
	if dir != 0.0:
		set_facing(int(signf(dir)))
	var now := Time.get_ticks_msec()
	_boss_chain_hits = _boss_chain_hits + 1 if now - _boss_last_hit_ms < 700 else 1
	_boss_last_hit_ms = now
	EventBus.fighter_damaged.emit(self)
	EventBus.boss_health_changed.emit(float(hp) / float(max_hp))
	if hp <= 0:
		state_machine.transition("Death")
		return
	if hyper_armor:
		return
	if _boss_chain_hits >= 3:
		_boss_chain_hits = 0
		_make_counter_room()
		hyper_armor = true
		state_machine.transition("Counter")
	elif knockdown_hit:
		state_machine.transition("Knockdown")
	else:
		state_machine.transition("Hurt")


func summon_adds() -> void:
	var existing_adds := get_tree().get_nodes_in_group("boss_adds").size()
	if existing_adds >= 2:
		return
	var stage := get_parent().get_parent() as Stage
	if stage == null:
		return
	_spawn_add(stage, Vector2(global_position.x - 245.0, 218.0))
	if existing_adds == 0:
		_spawn_add(stage, Vector2(global_position.x + 180.0, 258.0))


func _make_counter_room() -> void:
	if attackers_count() < MAX_ATTACKERS:
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy != self and enemy.is_committed_attack():
			enemy.state_machine.transition("Recover")
			return


func _spawn_add(stage: Stage, spawn_position: Vector2) -> void:
	var add := PUNK_SCENE.instantiate() as Enemy
	get_parent().add_child(add)
	add.add_to_group("boss_adds")
	add.global_position = spawn_position
	stage.apply_bounds(add)


func finish_death() -> void:
	EventBus.boss_health_changed.emit(0.0)
	super()
