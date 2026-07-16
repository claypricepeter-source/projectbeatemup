class_name Thug
extends Enemy
## Heavy enemy: the first ordinary hit in a combo deals damage but does not
## interrupt his current action. The third quick hit still forces knockdown.

var _thug_combo_hits := 0
var _thug_last_hit_ms := 0


func take_hit(damage: int, knockdown_hit: bool, attacker: Fighter) -> bool:
	if is_dead or invulnerable:
		return false
	hp = maxi(hp - damage, 0)
	var direction := attacker.global_position.x - global_position.x
	if direction != 0.0:
		set_facing(int(signf(direction)))
	var now := Time.get_ticks_msec()
	_thug_combo_hits = _thug_combo_hits + 1 if now - _thug_last_hit_ms < 700 else 1
	_thug_last_hit_ms = now
	var armored_hit := _thug_combo_hits == 1 and not knockdown_hit
	if _thug_combo_hits >= 3:
		_thug_combo_hits = 0
		knockdown_hit = true
		armored_hit = false
	EventBus.fighter_damaged.emit(self)
	if hp <= 0:
		state_machine.transition("Death")
	elif knockdown_hit:
		state_machine.transition("Knockdown")
	elif not armored_hit:
		state_machine.transition("Hurt")
	return true
