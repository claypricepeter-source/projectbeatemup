class_name Fighter
extends CharacterBody2D
## Base class for all beat-em-up combatants (player and enemies).
##
## Movement happens on a pseudo-3D ground plane: the node's position is the
## fighter's feet on the ground (X = along the street, Y = depth). Jumping is
## purely visual — the sprite is offset upward by [member air_height] while the
## node (and its shadow) stays on the ground plane. See AGENTS.md §7.3.

@export var move_speed := Vector2(120.0, 80.0)
@export var jump_velocity := 230.0
@export var gravity := 700.0
@export var max_hp := 100
@export var sprite_faces_right := true

signal died

var hp: int
var facing := 1
var air_height := 0.0
var air_velocity := 0.0
var invulnerable := false
var is_dead := false
var walk_min_x := -100000.0
var walk_max_x := 100000.0
var walk_min_y := -100000.0
var walk_max_y := 100000.0

@onready var sprite: AnimatedSprite2D = $Visuals/Sprite
@onready var shadow: Sprite2D = $Visuals/Shadow
@onready var state_machine: FighterStateMachine = $StateMachine
@onready var hitbox: Hitbox = $HitboxPivot/Hitbox
@onready var hitbox_pivot: Node2D = $HitboxPivot

var _sprite_base_y: float
var _chain_hits := 0
var _last_hit_ms := 0


func _ready() -> void:
	hp = max_hp
	_sprite_base_y = sprite.position.y
	hitbox.source = self
	set_facing(facing)
	state_machine.setup(self)


func set_facing(dir: int) -> void:
	if dir == 0:
		return
	facing = signi(dir)
	# Character packs do not all share a source-facing direction. Keep combat
	# facing in world space while flipping the art relative to its authored pose.
	sprite.flip_h = (facing > 0) != sprite_faces_right
	hitbox_pivot.scale.x = facing


func play(anim: StringName) -> void:
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)


## Moves along the ground plane and clamps to the stage's walkable bounds.
func apply_movement(_delta: float) -> void:
	move_and_slide()
	position.x = clampf(position.x, walk_min_x, walk_max_x)
	position.y = clampf(position.y, walk_min_y, walk_max_y)


func is_airborne() -> bool:
	return air_height > 0.0 or air_velocity > 0.0


func start_jump() -> void:
	air_velocity = jump_velocity


## Entry point for all incoming damage. Routes to Hurt/Knockdown/Death states.
func take_hit(damage: int, knockdown_hit: bool, attacker: Fighter) -> void:
	if is_dead or invulnerable:
		return
	hp = maxi(hp - damage, 0)
	var dir := attacker.global_position.x - global_position.x
	if dir != 0.0:
		set_facing(int(signf(dir)))
	# Anti-stunlock: a third consecutive hit inside 0.7s becomes a knockdown,
	# which grants invulnerability and separation.
	var now := Time.get_ticks_msec()
	_chain_hits = _chain_hits + 1 if now - _last_hit_ms < 700 else 1
	_last_hit_ms = now
	if _chain_hits >= 3:
		_chain_hits = 0
		knockdown_hit = true
	EventBus.fighter_damaged.emit(self)
	if hp <= 0:
		state_machine.transition("Death")
	elif knockdown_hit:
		state_machine.transition("Knockdown")
	else:
		state_machine.transition("Hurt")


## Post-knockdown hook; Player overrides to add i-frames.
func end_knockdown() -> void:
	invulnerable = false


func start_iframes(duration: float) -> void:
	invulnerable = true
	var tween := create_tween()
	var blinks := maxi(int(duration / 0.1), 2)
	for i in blinks:
		tween.tween_property(sprite, "modulate:a", 0.35 if i % 2 == 0 else 1.0, 0.1)
	tween.tween_callback(func() -> void:
		sprite.modulate.a = 1.0
		invulnerable = false)


## Called by the Death state once the body has faded out.
func finish_death() -> void:
	died.emit()
	queue_free()


## Advances the vertical jump simulation. Returns true on the landing frame.
func update_air(delta: float) -> bool:
	air_velocity -= gravity * delta
	air_height += air_velocity * delta
	if air_height <= 0.0:
		air_height = 0.0
		air_velocity = 0.0
		sprite.position.y = _sprite_base_y
		return true
	sprite.position.y = _sprite_base_y - air_height
	return false
