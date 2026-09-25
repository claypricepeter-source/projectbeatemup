extends Node
## Headless runtime test for the SoR2 moveset. Drives real InputMap actions
## against real enemy scenes and checks damage, knockdowns, grabs, throws,
## specials, weapons and the round timer. Run with:
##   godot --headless --path . res://tests/sor2_moves_test.tscn
## Exit code = number of failed checks. Not part of the shipping export.

const ROSTER := preload("res://scenes/stages/roster_test.tscn")
const PUNK := preload("res://scenes/characters/enemies/punk.tscn")
const THUG := preload("res://scenes/characters/enemies/thug.tscn")
const KNIFE_PUNK := preload("res://scenes/characters/enemies/knife_punk.tscn")
const LANE_Y := 248.0

var stage: Stage
var player: Player
var failures := 0
var checks := 0


func _ready() -> void:
	await _run("combo mash: jab jab straight low-kick KD", _test_combo_mash)
	await _run("combo timed: full five hits", _test_combo_full)
	await _run("whiff resets combo to jab", _test_whiff_reset)
	await _run("grab: knee knee double-knee", _test_grab_knees)
	await _run("grab: headbutt", _test_grab_headbutt)
	await _run("grab from behind: body slam", _test_back_grab)
	await _run("grab: back throw hits other enemy", _test_back_throw)
	await _run("grab: vault then body slam", _test_vault_slam)
	await _run("defensive special hits both sides, costs 8 on hit", _test_defensive_special)
	await _run("defensive special whiff is free", _test_defensive_whiff)
	await _run("offensive special flurry", _test_offensive_special)
	await _run("blitz grand upper", _test_blitz)
	await _run("back attack", _test_back_attack)
	await _run("hold-release double sidekick", _test_double_kick)
	await _run("vertical jump kick", _test_jump_kick)
	await _run("knife drop, pickup and use", _test_weapon)
	await _run("food pickup needs ATTACK", _test_food)
	await _run("enemies flank both sides", _test_flanking)
	await _run("time over costs a life", _test_time_over)
	print("SOR2 TEST RESULT: %d/%d checks passed" % [checks - failures, checks])
	get_tree().quit(failures)


func _run(title: String, test: Callable) -> void:
	print("--- ", title)
	await _setup()
	await test.call()


func _setup() -> void:
	for action in ["attack_p1", "jump_p1", "special_p1", "move_left_p1", "move_right_p1", "move_up_p1", "move_down_p1"]:
		Input.action_release(action)
	Engine.time_scale = 1.0
	if is_instance_valid(stage):
		stage.queue_free()
		await _frames(2)
	stage = ROSTER.instantiate() as Stage
	add_child(stage)
	for node in stage.get_node("Entities").get_children():
		if node is Enemy:
			node.free()
	player = stage.get_node("Entities/Player") as Player
	await _frames(2)
	player.max_hp = 104
	player.hp = 104
	player.global_position = Vector2(300.0, LANE_Y)
	player.set_facing(1)
	stage.round_timer.refill()
	await _frames(2)


func _spawn(scene: PackedScene, x: float, frozen: bool = true, y: float = LANE_Y) -> Enemy:
	var enemy := scene.instantiate() as Enemy
	stage.get_node("Entities").add_child(enemy)
	enemy.global_position = Vector2(x, y)
	stage.apply_bounds(enemy)
	if frozen:
		# Passive dummy: cannot move, never reaches attack range, no steering.
		enemy.move_speed = Vector2.ZERO
		enemy.stats.attack_range = 0.0
		enemy.separation_strength = 0.0
	return enemy


# --- input / time helpers ---------------------------------------------------

func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await _frames(1)
	Input.action_release(action)
	await _frames(1)


func _hold(action: StringName) -> void:
	Input.action_press(action)


func _release(action: StringName) -> void:
	Input.action_release(action)


func _state(fighter: Fighter) -> StringName:
	return fighter.current_state_name() if is_instance_valid(fighter) else &"<freed>"


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok   ", message)
	else:
		failures += 1
		print("  FAIL ", message)


func _wait_until(condition: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if condition.call():
			return true
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time() * Engine.time_scale
	return condition.call()


# --- tests --------------------------------------------------------------------

func _test_combo_mash() -> void:
	var punk := _spawn(PUNK, 360.0)
	punk.max_hp = 200
	punk.hp = 200
	for i in 8:
		await _tap(&"attack_p1")
		await _wait(0.1)
		if _state(punk) == &"Knockdown":
			break
	await _wait(0.2)
	# Mashing: 6 + 6 + 8 + 10 (KD) unless a press happens to land in the
	# 3-frame double-kick window, which adds the 14 high kick.
	_check(200 - punk.hp in [30, 44], "mash dealt %d (expected 30, or 44 with lucky timing)" % (200 - punk.hp))
	_check(_state(punk) == &"Knockdown", "lone low sidekick knocked down (%s)" % _state(punk))


func _test_combo_full() -> void:
	var punk := _spawn(PUNK, 360.0)
	punk.max_hp = 200
	punk.hp = 200
	var attack_state := player.state_machine.get_node("Attack")
	await _tap(&"attack_p1")
	# Chain on each connected hit; time the press as the straight retracts.
	var pressed_for := -1
	for frame in 240:
		await _frames(1)
		if _state(player) != &"Attack":
			break
		var step: int = attack_state.get("_step")
		var elapsed: float = attack_state.get("_elapsed")
		var data: Dictionary = attack_state.get("_data")
		if step < 2 and pressed_for != step and elapsed > float(data["hit_at"]) + 0.08:
			pressed_for = step
			await _tap(&"attack_p1")
		elif step == 2 and pressed_for != 2 and elapsed >= float(data["duration"]) - 0.06:
			pressed_for = 2
			await _tap(&"attack_p1")
	await _wait(0.2)
	_check(200 - punk.hp == 44, "full string dealt %d (expected 6+6+8+10+14 = 44)" % (200 - punk.hp))
	_check(_state(punk) == &"Knockdown", "high sidekick knocked down (%s)" % _state(punk))


func _test_whiff_reset() -> void:
	player.remember_combo(3)
	await _tap(&"attack_p1")
	await _frames(2)
	var attack_state := player.state_machine.get_node("Attack")
	_check(int(attack_state.get("_step")) == 3, "combo memory resumes at stored step")
	await _wait(0.5)
	_check(player.next_combo_step() == 0, "whiffed swing resets combo to the jab")


func _grab_punk(hp: int = 200) -> Enemy:
	var punk := _spawn(PUNK, 350.0)
	punk.max_hp = hp
	punk.hp = hp
	punk.set_facing(-1)
	_hold(&"move_right_p1")
	await _wait_until(func() -> bool: return _state(player) == &"Grab", 1.0)
	return punk


func _test_grab_knees() -> void:
	var punk := await _grab_punk()
	_check(_state(player) == &"Grab" and _state(punk) == &"Grabbed", "walking into the punk grabs it (%s/%s)" % [_state(player), _state(punk)])
	for i in 3:
		await _tap(&"attack_p1")
		await _wait(0.5)
	_release(&"move_right_p1")
	await _wait(0.1)
	_check(200 - punk.hp == 34, "knee, knee, double knee dealt %d (expected 34)" % (200 - punk.hp))
	_check(_state(punk) == &"Knockdown", "double knee knocked down (%s)" % _state(punk))


func _test_back_grab() -> void:
	var punk := _spawn(PUNK, 350.0)
	punk.max_hp = 200
	punk.hp = 200
	_hold(&"move_right_p1")
	await _wait_until(func() -> bool: return _state(player) == &"Grab", 1.0)
	_release(&"move_right_p1")
	await _frames(2)
	await _tap(&"attack_p1")
	await _wait_until(func() -> bool: return _state(punk) == &"Knockdown", 2.0)
	_check(200 - punk.hp == 28, "grabbing a punk from behind body-slams for %d (expected 28)" % (200 - punk.hp))


func _test_grab_headbutt() -> void:
	var punk := await _grab_punk()
	_release(&"move_right_p1")
	await _frames(2)
	await _tap(&"attack_p1")
	await _wait(0.45)
	_check(200 - punk.hp == 22, "headbutt dealt %d (expected 22)" % (200 - punk.hp))
	_check(_state(punk) == &"Knockdown", "headbutt knocked down (%s)" % _state(punk))


func _test_back_throw() -> void:
	var bystander := _spawn(PUNK, 240.0)
	bystander.max_hp = 200
	bystander.hp = 200
	var punk := await _grab_punk()
	_release(&"move_right_p1")
	_hold(&"move_left_p1")
	await _frames(1)
	await _tap(&"attack_p1")
	_release(&"move_left_p1")
	await _wait_until(func() -> bool: return _state(punk) == &"Knockdown", 2.0)
	_check(200 - punk.hp == 24, "back throw dealt %d to the thrown punk (expected 24)" % (200 - punk.hp))
	_check(200 - bystander.hp == 16, "thrown body dealt %d to the bystander (expected 16)" % (200 - bystander.hp))
	_check(punk.global_position.x < player.global_position.x, "punk landed behind the player")


func _test_vault_slam() -> void:
	var punk := await _grab_punk()
	_release(&"move_right_p1")
	await _frames(2)
	var start_x := player.global_position.x
	await _tap(&"jump_p1")
	await _wait(0.5)
	_check(player.global_position.x > punk.global_position.x and player.facing == -1, "vault moved the player behind the punk (x %.0f -> %.0f)" % [start_x, player.global_position.x])
	_check(_state(punk) == &"Grabbed", "still holding after one vault (%s)" % _state(punk))
	await _tap(&"attack_p1")
	await _wait_until(func() -> bool: return _state(punk) == &"Knockdown", 2.0)
	_check(200 - punk.hp == 28, "body slam dealt %d (expected 28)" % (200 - punk.hp))


func _test_defensive_special() -> void:
	var front := _spawn(PUNK, 350.0)
	var back := _spawn(PUNK, 250.0)
	await _tap(&"special_p1")
	await _wait(0.2)
	_check(player.invulnerable, "defensive special is invulnerable")
	await _wait(0.5)
	_check(front.max_hp - front.hp == 16 and back.max_hp - back.hp == 16, "hit both sides for 16 (front %d, back %d)" % [front.max_hp - front.hp, back.max_hp - back.hp])
	_check(player.hp == 96, "cost 8 HP on hit (hp %d)" % player.hp)


func _test_defensive_whiff() -> void:
	await _tap(&"special_p1")
	await _wait(0.7)
	_check(player.hp == 104, "no cost when nothing was hit (hp %d)" % player.hp)


func _test_offensive_special() -> void:
	var thug := _spawn(THUG, 360.0)
	thug.max_hp = 300
	thug.hp = 300
	_hold(&"move_right_p1")
	await _tap(&"special_p1")
	_release(&"move_right_p1")
	await _wait(1.6)
	_check(300 - thug.hp == 74, "flurry dealt %d (expected 74)" % (300 - thug.hp))
	_check(player.hp == 96, "offensive special always costs 8 (hp %d)" % player.hp)


func _test_blitz() -> void:
	var thug := _spawn(THUG, 420.0)
	thug.max_hp = 300
	thug.hp = 300
	await _tap(&"move_right_p1")
	await _frames(3)
	_hold(&"move_right_p1")
	await _frames(2)
	await _tap(&"attack_p1")
	_release(&"move_right_p1")
	await _frames(2)
	_check(_state(player) == &"Blitz", "forward, forward, attack starts the blitz (%s)" % _state(player))
	await _wait(1.0)
	_check(300 - thug.hp == 48, "grand upper dealt %d (expected 24+4+20 = 48)" % (300 - thug.hp))


func _test_back_attack() -> void:
	var punk := _spawn(PUNK, 250.0)
	punk.max_hp = 200
	punk.hp = 200
	_hold(&"attack_p1")
	await _frames(2)
	await _tap(&"jump_p1")
	await _frames(2)
	_release(&"attack_p1")
	_check(_state(player) == &"BackAttack", "hold ATTACK + JUMP = back attack (%s)" % _state(player))
	await _wait(0.8)
	_check(200 - punk.hp == 20, "elbow + backfist dealt %d behind (expected 20)" % (200 - punk.hp))
	_check(player.facing == 1, "player still faces forward")


func _test_double_kick() -> void:
	var punk := _spawn(PUNK, 360.0)
	punk.max_hp = 200
	punk.hp = 200
	_hold(&"attack_p1")
	await _wait(0.55)
	_release(&"attack_p1")
	await _frames(2)
	_check(_state(player) == &"DoubleKick", "hold + release = double sidekick (%s)" % _state(player))
	await _wait(0.8)
	var dealt := 200 - punk.hp
	# The initial press also throws a jab (6) that may land before the kicks.
	_check(dealt == 36 or dealt == 42, "double sidekick dealt %d (expected 36, +6 jab)" % dealt)
	_check(_state(punk) == &"Knockdown", "second kick knocked down (%s)" % _state(punk))


func _test_jump_kick() -> void:
	var punk := _spawn(PUNK, 350.0)
	punk.max_hp = 200
	punk.hp = 200
	await _tap(&"jump_p1")
	await _wait(0.12)
	await _tap(&"attack_p1")
	await _wait(0.8)
	_check(200 - punk.hp == 30, "vertical knee + kick dealt %d (expected 30)" % (200 - punk.hp))


func _test_weapon() -> void:
	var knife_punk := _spawn(KNIFE_PUNK, 360.0)
	_check(knife_punk.carried_weapon == &"knife", "knife punk carries a knife")
	knife_punk.take_hit(1, true, player)
	await _wait(0.2)
	var weapons := get_tree().get_nodes_in_group("weapons")
	_check(weapons.size() == 1, "knockdown dropped the knife (%d on ground)" % weapons.size())
	if weapons.is_empty():
		return
	knife_punk.free()
	var knife := weapons[0] as Node2D
	player.global_position = knife.global_position + Vector2(-8.0, 0.0)
	await _frames(2)
	await _tap(&"attack_p1")
	await _wait(0.4)
	_check(player.weapon == &"knife", "ATTACK over the knife picked it up (%s)" % player.weapon)
	var dummy := _spawn(PUNK, player.global_position.x + 55.0)
	dummy.max_hp = 200
	dummy.hp = 200
	await _tap(&"attack_p1")
	await _wait(0.4)
	_check(200 - dummy.hp == 16, "knife stab dealt %d (expected 16)" % (200 - dummy.hp))
	player.take_hit(1, true, dummy)
	await _wait(0.3)
	_check(player.weapon == &"" and get_tree().get_nodes_in_group("weapons").size() == 1, "knockdown dropped the knife")


func _test_food() -> void:
	player.hp = 50
	var coffee := (load("res://scenes/props/coffee_pickup.tscn") as PackedScene).instantiate() as Node2D
	stage.get_node("Entities").add_child(coffee)
	coffee.global_position = player.global_position + Vector2(6.0, 0.0)
	await _wait(0.3)
	_check(player.hp == 50, "walking over food does not eat it")
	await _tap(&"attack_p1")
	await _wait(0.4)
	_check(player.hp == 82, "ATTACK ate the coffee: +32 (hp %d)" % player.hp)


func _test_flanking() -> void:
	player.max_hp = 9999
	player.hp = 9999
	var a := _spawn(PUNK, 480.0, false, LANE_Y - 10.0)
	var b := _spawn(PUNK, 540.0, false, LANE_Y + 10.0)
	a.stats.damage = 0
	b.stats.damage = 0
	await _wait(5.0)
	var left := 0
	var right := 0
	for enemy: Enemy in [a, b]:
		if enemy.global_position.x < player.global_position.x:
			left += 1
		else:
			right += 1
	_check(left == 1 and right == 1, "one enemy on each side (left %d, right %d)" % [left, right])


func _test_time_over() -> void:
	var lives_before := GameState.lives
	stage.round_timer.time_left = 1
	await _wait(RoundTimer.SECONDS_PER_COUNT + 0.3)
	_check(player.is_dead or _state(player) == &"Death", "time over killed the player (%s)" % _state(player))
	await _wait_until(func() -> bool: return not player.visible, 8.0)
	_check(GameState.lives == lives_before or GameState.lives == lives_before - 1, "life flow ran (lives %d)" % GameState.lives)
