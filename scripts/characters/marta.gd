class_name Marta
extends Enemy
## Stage 2 boss: long flaming stinkhorn strikes and a telegraphed full-lane sweep.
## A five-shot liquid barrage rewards three lane dodges with a dizzy punish window.
## Three quick hits outside that window trigger a brief armored spin counter.

const SWEEP_COOLDOWN := 6.5
const BARRAGE_COOLDOWN := 8.5
const TAUNT_COOLDOWN := 9.0
const BARRAGE_RANGE := 440.0
const BARRAGE_DODGES_REQUIRED := 3
const LIQUID_PROJECTILE_SCENE := preload("res://scenes/effects/ragnaros_liquid_projectile.tscn")

signal liquid_projectile_resolved(dodged: bool)

@onready var sweep_hitbox: Hitbox = $SweepHitbox
@onready var sweep_telegraph: Node2D = $SweepTelegraph
@onready var sweep_band: Polygon2D = $SweepTelegraph/Band
@onready var sweep_line: Line2D = $SweepTelegraph/Lane
@onready var sweep_crate: Polygon2D = $SweepTelegraph/Crate
@onready var dizzy_fx: Node2D = $Visuals/DizzyFX

var sweep_cooldown := 2.25
var barrage_cooldown := 3.0
var taunt_cooldown := 4.0
var barrage_shots_fired := 0
var barrage_dodges := 0
var barrage_hits := 0
var hyper_armor := false
var last_attack_was_sweep := false
var _boss_chain_hits := 0
var _boss_last_hit_ms := 0


func _ready() -> void:
	super()
	sweep_hitbox.source = self
	set_lane_warning(false, false)
	EventBus.boss_health_changed.emit(1.0)


func _physics_process(delta: float) -> void:
	if not is_dead:
		sweep_cooldown = maxf(sweep_cooldown - delta, 0.0)
		barrage_cooldown = maxf(barrage_cooldown - delta, 0.0)
		taunt_cooldown = maxf(taunt_cooldown - delta, 0.0)


func liquid_muzzle_position() -> Vector2:
	return global_position + Vector2(112.0 * float(facing), 0.0)


func fire_liquid_projectile() -> bool:
	var target := target_player()
	if target == null:
		return false
	var projectile := LIQUID_PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = liquid_muzzle_position()
	projectile.call("setup", self, target)
	projectile.connect("resolved", _on_liquid_projectile_resolved, CONNECT_ONE_SHOT)
	barrage_shots_fired += 1
	return true


func _on_liquid_projectile_resolved(dodged: bool) -> void:
	if dodged:
		barrage_dodges += 1
	else:
		barrage_hits += 1
	liquid_projectile_resolved.emit(dodged)


func clear_liquid_projectiles() -> void:
	for projectile in get_tree().get_nodes_in_group("ragnaros_liquid_projectiles"):
		if projectile.get("source_fighter") == self:
			projectile.call("cancel")


func set_dizzy_visual(enabled: bool) -> void:
	dizzy_fx.call("set_active", enabled)
	if not enabled:
		sprite.rotation = 0.0


func reset_dizzy_hit_chain() -> void:
	_boss_chain_hits = 0
	_boss_last_hit_ms = 0


func set_lane_warning(enabled: bool, active: bool) -> void:
	if not is_instance_valid(sweep_telegraph):
		return
	sweep_telegraph.visible = enabled
	sweep_band.color = Color(1.0, 0.12, 0.04, 0.22) if active else Color(1.0, 0.68, 0.1, 0.14)
	sweep_line.default_color = Color(1.0, 0.22, 0.08, 0.92) if active else Color(1.0, 0.72, 0.18, 0.68)
	sweep_line.width = 8.0 if active else 3.0
	sweep_crate.color = Color(0.8, 0.24, 0.08, 1.0) if active else Color(0.55, 0.32, 0.12, 0.9)


func take_hit(damage: int, knockdown_hit: bool, attacker: Fighter) -> bool:
	if is_dead or invulnerable:
		return false
	hp = maxi(hp - damage, 0)
	var direction := attacker.global_position.x - global_position.x
	if direction != 0.0:
		set_facing(int(signf(direction)))
	var is_dizzy := state_machine.current != null and state_machine.current.name == &"Dizzy"
	if is_dizzy:
		EventBus.fighter_damaged.emit(self)
		EventBus.boss_health_changed.emit(float(hp) / float(max_hp))
		if hp <= 0:
			state_machine.transition("Death")
		else:
			flash_hit()
		return true
	var now := Time.get_ticks_msec()
	_boss_chain_hits = _boss_chain_hits + 1 if now - _boss_last_hit_ms < 700 else 1
	_boss_last_hit_ms = now
	EventBus.fighter_damaged.emit(self)
	EventBus.boss_health_changed.emit(float(hp) / float(max_hp))
	if hp <= 0:
		state_machine.transition("Death")
		return true
	if hyper_armor:
		return true
	if _boss_chain_hits >= 3:
		_boss_chain_hits = 0
		hyper_armor = true
		state_machine.transition("Counter")
	elif knockdown_hit:
		state_machine.transition("Knockdown")
	else:
		state_machine.transition("Hurt")
	return true


func finish_death() -> void:
	set_lane_warning(false, false)
	set_dizzy_visual(false)
	clear_liquid_projectiles()
	sweep_hitbox.deactivate()
	EventBus.boss_health_changed.emit(0.0)
	super()
