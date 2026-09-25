class_name Fighter
extends CharacterBody2D
## Base class for all beat-em-up combatants (player and enemies).
##
## Movement happens on a pseudo-3D ground plane: the node's position is the
## fighter's feet on the ground (X = along the street, Y = depth). Jumping is
## purely visual — the sprite is offset upward by [member air_height] while the
## node (and its shadow) stays on the ground plane. See AGENTS.md §7.3.
##
## Streets of Rage 2 grappling (AGENTS.md §4.2): every fighter can be held
## ([code]Grabbed[/code]) and thrown ([code]Thrown[/code]). Those two shared
## states are installed at runtime so every enemy/boss scene receives them.

const GRABBED_STATE_SCRIPT := preload("res://scripts/characters/states/grabbed.gd")
const THROWN_STATE_SCRIPT := preload("res://scripts/characters/states/thrown.gd")
## States from which walking into this fighter starts a grab.
const GRABBABLE_STATES: Array[StringName] = [
	&"Idle", &"Move", &"Approach", &"Recover", &"Hurt", &"Taunt", &"Dizzy",
]

@export var move_speed := Vector2(120.0, 80.0)
@export var jump_velocity := 230.0
@export var gravity := 700.0
@export var max_hp := 100
@export var sprite_faces_right := true
@export var death_lie_time := 0.4
@export var death_fade_time := 0.5
## Seconds a normal (non-knockdown) hit freezes this fighter.
@export var hitstun_time := 0.4
## Upgrades the third quick hit to a knockdown. SoR2 only protects the player
## this way; enemies must be comboed with the full five-hit string.
@export var anti_stunlock := false
@export var can_be_grabbed_at_all := true
## How long a grabbed fighter struggles before breaking loose.
@export var grab_escape_time := 1.6

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

## Grapple bookkeeping. [member held_by] is set while in the Grabbed state.
var held_by: Fighter
## Knockdown tuning consumed (and reset) by the next Knockdown entry.
var knockdown_pop_scale := 1.0
var knockdown_push_scale := 1.0
## Thrown-state parameters, set by [method start_thrown].
var thrown_by: Fighter
var thrown_damage := 0
var thrown_direction := 1
var thrown_is_slam := false

@onready var sprite: AnimatedSprite2D = $Visuals/Sprite
@onready var shadow: Sprite2D = $Visuals/Shadow
@onready var state_machine: FighterStateMachine = $StateMachine
@onready var hitbox: Hitbox = $HitboxPivot/Hitbox
@onready var hitbox_pivot: Node2D = $HitboxPivot

var _sprite_base_y: float
var _chain_hits := 0
var _last_hit_ms := 0
var _flash_tween: Tween


func _ready() -> void:
	hp = max_hp
	_sprite_base_y = sprite.position.y
	hitbox.source = self
	_install_shared_state(&"Grabbed", GRABBED_STATE_SCRIPT)
	_install_shared_state(&"Thrown", THROWN_STATE_SCRIPT)
	set_facing(facing)
	state_machine.setup(self)


func _install_shared_state(state_name: StringName, script: GDScript) -> void:
	if state_machine.has_node(NodePath(state_name)):
		return
	var state := Node.new()
	state.name = state_name
	state.set_script(script)
	state_machine.add_child(state)


func set_facing(dir: int) -> void:
	if dir == 0:
		return
	facing = signi(dir)
	# Character packs do not all share a source-facing direction. Keep combat
	# facing in world space while flipping the art relative to its authored pose.
	sprite.flip_h = (facing > 0) != sprite_faces_right
	hitbox_pivot.scale.x = facing


## Turns only the art (and the hitbox) around, keeping logical facing. Used by
## backward attacks; restore with [code]set_facing(facing)[/code].
func face_art_backwards() -> void:
	sprite.flip_h = (facing < 0) != sprite_faces_right
	hitbox_pivot.scale.x = -facing


func play(anim: StringName) -> void:
	sprite.speed_scale = 1.0
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)


## Plays [param anim] stretched or squeezed to last exactly [param duration].
func play_timed(anim: StringName, duration: float) -> void:
	play(anim)
	var resolved := sprite.animation
	if not sprite.sprite_frames.has_animation(resolved) or duration <= 0.0:
		return
	var frames := sprite.sprite_frames
	var fps := frames.get_animation_speed(resolved)
	var total := 0.0
	for i in frames.get_frame_count(resolved):
		total += frames.get_frame_duration(resolved, i)
	if fps > 0.0 and total > 0.0:
		sprite.speed_scale = (total / fps) / duration
	sprite.frame = 0
	sprite.play(resolved)


func flash_hit() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	var alpha := sprite.modulate.a
	sprite.modulate = Color(2.2, 2.2, 2.2, alpha)
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, alpha), 0.1)


## Moves along the ground plane and clamps to the stage's walkable bounds.
func apply_movement(_delta: float) -> void:
	move_and_slide()
	position.x = clampf(position.x, walk_min_x, walk_max_x)
	position.y = clampf(position.y, walk_min_y, walk_max_y)


func is_airborne() -> bool:
	return air_height > 0.0 or air_velocity > 0.0


func start_jump() -> void:
	air_velocity = jump_velocity


func current_state_name() -> StringName:
	return state_machine.current.name if state_machine.current else &""


## True when an opponent walking into this fighter may grab it (SoR2 rule: a
## fighter in a normal walking/standing/reeling frame gets held).
func can_be_grabbed() -> bool:
	if not can_be_grabbed_at_all or is_dead or invulnerable or is_airborne():
		return false
	return current_state_name() in GRABBABLE_STATES


## Called by the grabber. Returns false if the grab was refused.
func begin_grabbed(grabber: Fighter) -> bool:
	if not can_be_grabbed():
		return false
	held_by = grabber
	state_machine.transition("Grabbed")
	return true


## Releases a grabbed fighter back to normal control.
func release_from_grab(push: float = 0.0) -> void:
	held_by = null
	if current_state_name() == &"Grabbed":
		velocity = Vector2(push, 0.0)
		state_machine.transition("Idle")


## Launches this fighter as a thrown body. Damage is applied on landing; while
## airborne the body hits other fighters on its own team (SoR2 throw damage).
func start_thrown(thrower: Fighter, direction: int, damage: int, slam: bool) -> void:
	held_by = null
	thrown_by = thrower
	thrown_damage = damage
	thrown_direction = direction
	thrown_is_slam = slam
	state_machine.transition("Thrown")


## Entry point for all incoming damage. Routes to Hurt/Knockdown/Death states.
func take_hit(damage: int, knockdown_hit: bool, attacker: Fighter) -> bool:
	if is_dead or invulnerable:
		return false
	hp = maxi(hp - damage, 0)
	_face_attacker(attacker)
	if anti_stunlock:
		# A third consecutive hit inside 0.7s becomes a knockdown, which grants
		# invulnerability and separation (protects the player from lock-ups).
		var now := Time.get_ticks_msec()
		_chain_hits = _chain_hits + 1 if now - _last_hit_ms < 700 else 1
		_last_hit_ms = now
		if _chain_hits >= 3:
			_chain_hits = 0
			knockdown_hit = true
	EventBus.fighter_damaged.emit(self)
	route_hit_state(knockdown_hit)
	return true


func _face_attacker(attacker: Fighter) -> void:
	if attacker == null:
		return
	var dir := attacker.global_position.x - global_position.x
	if dir != 0.0:
		set_facing(int(signf(dir)))


## Shared hit reaction routing once damage has been applied.
func route_hit_state(knockdown_hit: bool) -> void:
	if hp <= 0:
		state_machine.transition("Death")
	elif knockdown_hit:
		state_machine.transition("Knockdown")
	else:
		state_machine.transition("Hurt")


## Attacker-side hook invoked only after an incoming hit accepts damage.
func on_attack_connected(_target: Fighter, _defeated: bool) -> void:
	pass


## State-entry hook used by the player for life-loss presentation.
func on_death_started() -> void:
	pass


## Landing hook used by the player to start the blood-pool hold.
func on_death_landed() -> void:
	pass


## Called whenever this fighter is knocked off its feet (knockdown, throw,
## death). Enemies drop carried weapons; the player drops the held weapon.
func on_knocked_off_feet() -> void:
	pass


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
