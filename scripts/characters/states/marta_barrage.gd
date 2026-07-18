extends FighterState
## Ragnaros braces the stinkhorn like a gun and fires five aimed liquid shots.
## Three misses mean the player dodged the pattern and force the dizzy opening.

const SHOT_COUNT := 5
const FIRST_SHOT_TIME := 0.42
const SHOT_INTERVAL := 0.62
const RESOLUTION_TIMEOUT := 5.2

var _elapsed := 0.0
var _next_shot := FIRST_SHOT_TIME
var _shots := 0
var _resolved := 0
var _dodges := 0


func enter() -> void:
	var boss := fighter as Marta
	boss.velocity = Vector2.ZERO
	boss.invulnerable = true
	boss.hyper_armor = true
	boss.last_attack_was_sweep = true
	boss.barrage_cooldown = Marta.BARRAGE_COOLDOWN
	boss.barrage_shots_fired = 0
	boss.barrage_dodges = 0
	boss.barrage_hits = 0
	boss.sprite.animation = &"attack"
	boss.sprite.pause()
	boss.sprite.frame = 0
	var target := boss.target_player()
	if target and target.global_position.x != boss.global_position.x:
		boss.set_facing(int(signf(target.global_position.x - boss.global_position.x)))
	if not boss.liquid_projectile_resolved.is_connected(_on_projectile_resolved):
		boss.liquid_projectile_resolved.connect(_on_projectile_resolved)
	_elapsed = 0.0
	_next_shot = FIRST_SHOT_TIME
	_shots = 0
	_resolved = 0
	_dodges = 0


func exit() -> void:
	var boss := fighter as Marta
	if boss.liquid_projectile_resolved.is_connected(_on_projectile_resolved):
		boss.liquid_projectile_resolved.disconnect(_on_projectile_resolved)
	boss.invulnerable = false
	boss.hyper_armor = false
	boss.clear_liquid_projectiles()


func physics_update(delta: float) -> void:
	_elapsed += delta
	var boss := fighter as Marta
	if _shots < SHOT_COUNT and _elapsed >= _next_shot:
		if boss.fire_liquid_projectile():
			_shots += 1
			boss.sprite.frame = mini((_shots - 1) * 2, 7)
		_next_shot += SHOT_INTERVAL
	if _dodges >= Marta.BARRAGE_DODGES_REQUIRED:
		machine.transition("Dizzy")
		return
	if _shots >= SHOT_COUNT and _resolved >= _shots:
		machine.transition("Recover")
		return
	if _elapsed >= RESOLUTION_TIMEOUT:
		machine.transition("Recover")
		return
	boss.apply_movement(delta)


func _on_projectile_resolved(dodged: bool) -> void:
	_resolved += 1
	if dodged:
		_dodges += 1
