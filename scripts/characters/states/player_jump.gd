extends FighterState
## SoR2 jump: the arc is fixed at takeoff (straight up or diagonal). One air
## attack per jump:
##   straight up + ATTACK  → knee (10) then kick (20, KD)
##   diagonal    + ATTACK  → jumping sidekick (8, KD), active until landing
##   any jump + Down+ATTACK → knee press (12, no KD — sets up grabs)

enum AirAttack { NONE, VERTICAL, SIDEKICK, KNEE_PRESS }

var _attack := AirAttack.NONE
var _diagonal := false
var _attack_time := 0.0
var _kick_phase := 0


func enter() -> void:
	var player := fighter as Player
	var input := player.input_vector()
	_diagonal = player.input_x() != 0
	if _diagonal:
		player.set_facing(player.input_x())
	player.velocity = Vector2(input.x * player.move_speed.x * 1.15, input.y * player.move_speed.y * 0.6)
	_attack = AirAttack.NONE
	_kick_phase = 0
	fighter.start_jump()
	fighter.play(&"jump")


func exit() -> void:
	fighter.hitbox.deactivate()
	fighter.sprite.speed_scale = 1.0


func physics_update(delta: float) -> void:
	var player := fighter as Player
	if _attack == AirAttack.NONE and player.attack_just_pressed():
		_start_air_attack(player)
	elif _attack != AirAttack.NONE:
		_update_air_attack(delta)
	var landed := player.update_air(delta)
	player.apply_movement(delta)
	if landed:
		fighter.hitbox.deactivate()
		if _attack != AirAttack.NONE:
			player.finish_attack_swing()
		machine.transition("Idle" if player.input_vector() == Vector2.ZERO else "Move")


func _start_air_attack(player: Player) -> void:
	player.begin_attack_swing()
	_attack_time = 0.0
	if player.input_vector().y > 0.5:
		_attack = AirAttack.KNEE_PRESS
		player.play(&"flying_knee")
		player.hitbox.activate(12, false)
	elif _diagonal:
		_attack = AirAttack.SIDEKICK
		player.play(&"strong_kick")
		player.hitbox.activate(8, true)
	else:
		_attack = AirAttack.VERTICAL
		player.play_timed(&"flying_knee", 0.14)
		player.hitbox.activate(10, false)


func _update_air_attack(delta: float) -> void:
	_attack_time += delta
	if _attack != AirAttack.VERTICAL:
		return
	# Knee first, then the kick on the same press (SoR2 vertical kick).
	if _kick_phase == 0 and _attack_time >= 0.14:
		_kick_phase = 1
		fighter.hitbox.deactivate()
		fighter.play(&"strong_kick")
		fighter.hitbox.activate(20, true)
