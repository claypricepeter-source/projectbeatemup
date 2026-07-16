class_name Victor
extends Enemy
## Final boss. Phase one uses grounded three-hit strings; at half health Victor
## enrages, speeds up, and gains a horizontal charging grab.

const ANIMATION_ALIASES := {
	&"idle": &"idle_walk",
	&"walk": &"idle_walk",
	&"attack": &"light_attack_metal_swipe",
	&"charge": &"dash_run",
	&"enrage": &"taunt",
}

@onready var enrage_aura: Polygon2D = $Visuals/EnrageAura

var phase_two := false
var hyper_armor := false
var charge_cooldown := 3.0
var charge_connected := false
var last_attack_was_charge := false
var _boss_chain_hits := 0
var _boss_last_hit_ms := 0


func _ready() -> void:
	super()
	enrage_aura.visible = false
	EventBus.boss_health_changed.emit(1.0)


func _physics_process(delta: float) -> void:
	if not is_dead:
		charge_cooldown = maxf(charge_cooldown - delta, 0.0)


func play(anim: StringName) -> void:
	var resolved: StringName = ANIMATION_ALIASES.get(anim, anim)
	super(resolved)


func begin_phase_two() -> void:
	if phase_two:
		return
	phase_two = true
	hyper_armor = true
	_boss_chain_hits = 0
	move_speed *= 1.3
	charge_cooldown = 0.0
	sprite.self_modulate = Color(1.0, 0.58, 0.58, 1)
	enrage_aura.visible = true


func on_attack_connected(_target: Fighter, _defeated: bool) -> void:
	if state_machine.current and state_machine.current.name == &"Charge":
		charge_connected = true


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
	if not phase_two and hp <= max_hp / 2:
		state_machine.transition("Enrage")
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
	EventBus.boss_health_changed.emit(0.0)
	super()
