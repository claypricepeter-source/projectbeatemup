class_name Marta
extends Enemy
## Stage 2 boss: long boat-hook pokes and a telegraphed full-lane crate sweep.
## Three quick hits trigger a brief armored spin counter.

const SWEEP_COOLDOWN := 6.5

@onready var sweep_hitbox: Hitbox = $SweepHitbox
@onready var sweep_telegraph: Node2D = $SweepTelegraph
@onready var sweep_band: Polygon2D = $SweepTelegraph/Band
@onready var sweep_line: Line2D = $SweepTelegraph/Lane
@onready var sweep_crate: Polygon2D = $SweepTelegraph/Crate

var sweep_cooldown := 2.25
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
	sweep_hitbox.deactivate()
	EventBus.boss_health_changed.emit(0.0)
	super()
