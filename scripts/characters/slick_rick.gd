class_name SlickRick
extends Enemy
## Stage 1 boss: knife flurries up close, lane dashes at range, and recurring
## two-Punk reinforcements. A third quick hit triggers an armored counter.

const PUNK_SCENE := preload("res://scenes/characters/enemies/punk.tscn")
const SUMMON_INTERVAL := 11.0
const ANIMATION_ALIASES := {
	&"idle": &"idle_walk",
	&"walk": &"idle_walk",
	&"attack": &"light_attack_metal_swipe",
}

@export var debug_combat_shapes := false

@onready var rainbow_meteor_effect: AnimatedSprite2D = $Visuals/RainbowMeteorEffect
@onready var throw_victim_overlay: AnimatedSprite2D = $Visuals/ThrowVictimOverlay
@onready var movement_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var attack_shape: CollisionShape2D = $HitboxPivot/Hitbox/CollisionShape2D

var hyper_armor := false
var dash_ready := true
var _boss_chain_hits := 0
var _boss_last_hit_ms := 0
var _summon_timer := 6.0


func _ready() -> void:
	super()
	EventBus.boss_health_changed.emit(1.0)


func _physics_process(delta: float) -> void:
	if debug_combat_shapes:
		queue_redraw()
	if is_dead:
		return
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = SUMMON_INTERVAL
		summon_adds()


func set_facing(dir: int) -> void:
	super(dir)
	if is_instance_valid(rainbow_meteor_effect):
		rainbow_meteor_effect.flip_h = sprite.flip_h
	if is_instance_valid(throw_victim_overlay):
		throw_victim_overlay.flip_h = sprite.flip_h


func play(anim: StringName) -> void:
	var resolved: StringName = ANIMATION_ALIASES.get(anim, anim)
	super(resolved)


## Asset-pack QA hook and future special-state entry point. The boss holds the
## second casting pose while the four effect-only frames play on their own layer.
func play_rainbow_meteor_preview() -> void:
	state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO
	throw_victim_overlay.visible = false
	rainbow_meteor_effect.visible = false
	sprite.play(&"special_attack_rainbow_meteor")
	await sprite.animation_finished
	sprite.pause()
	sprite.frame = 1
	rainbow_meteor_effect.flip_h = sprite.flip_h
	rainbow_meteor_effect.visible = true
	rainbow_meteor_effect.play(&"rainbow_meteor_effect")
	await rainbow_meteor_effect.animation_finished
	rainbow_meteor_effect.visible = false
	state_machine.process_mode = Node.PROCESS_MODE_INHERIT
	play(&"idle")


## Keeps the boss pose on the main layer and renders the manifest's second
## throw frame only as a victim overlay. Grabs remain deferred gameplay in v1.
func play_throw_preview() -> void:
	state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO
	rainbow_meteor_effect.visible = false
	throw_victim_overlay.visible = false
	sprite.play(&"throw")
	await sprite.animation_finished
	sprite.pause()
	throw_victim_overlay.flip_h = sprite.flip_h
	throw_victim_overlay.visible = true
	throw_victim_overlay.play(&"throw_victim_overlay")
	await get_tree().create_timer(0.35).timeout
	throw_victim_overlay.visible = false
	state_machine.process_mode = Node.PROCESS_MODE_INHERIT
	play(&"idle")


func set_debug_combat_shapes(enabled: bool) -> void:
	debug_combat_shapes = enabled
	queue_redraw()


func _draw() -> void:
	if not debug_combat_shapes:
		return
	var movement_radius := (movement_shape.shape as CircleShape2D).radius
	draw_arc(Vector2.ZERO, movement_radius, 0.0, TAU, 32, Color(0.25, 1.0, 0.35), 2.0)
	var hurt_size := (hurtbox_shape.shape as RectangleShape2D).size
	var hurt_rect := Rect2(hurtbox_shape.position - hurt_size * 0.5, hurt_size)
	draw_rect(hurt_rect, Color(0.2, 0.65, 1.0, 0.18), true)
	draw_rect(hurt_rect, Color(0.2, 0.75, 1.0), false, 2.0)
	var attack_size := (attack_shape.shape as RectangleShape2D).size
	var attack_center := Vector2(attack_shape.position.x * facing, attack_shape.position.y)
	var attack_rect := Rect2(attack_center - attack_size * 0.5, attack_size)
	var attack_color := Color(1.0, 0.2, 0.16, 0.75 if not attack_shape.disabled else 0.3)
	draw_rect(attack_rect, Color(attack_color, 0.12), true)
	draw_rect(attack_rect, attack_color, false, 2.0)


func take_hit(damage: int, knockdown_hit: bool, attacker: Fighter) -> bool:
	if is_dead or invulnerable:
		return false
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
		return true
	if hyper_armor:
		return true
	if _boss_chain_hits >= 3:
		_boss_chain_hits = 0
		_make_counter_room()
		hyper_armor = true
		state_machine.transition("Counter")
	elif knockdown_hit:
		state_machine.transition("Knockdown")
	else:
		state_machine.transition("Hurt")
	return true


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
