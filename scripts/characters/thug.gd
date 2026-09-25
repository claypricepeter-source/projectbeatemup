class_name Thug
extends Enemy
## Heavy enemy (SoR2 "Big Ben" archetype): once his haymaker is committed,
## ordinary hits deal damage without interrupting it. Knockdowns, throws and
## grabs still work normally, and he can be comboed freely otherwise.


func take_hit(damage: int, knockdown_hit: bool, attacker: Fighter) -> bool:
	if is_dead or invulnerable:
		return false
	var armored := current_state_name() == &"Attack" and not knockdown_hit
	if not armored:
		return super(damage, knockdown_hit, attacker)
	hp = maxi(hp - damage, 0)
	EventBus.fighter_damaged.emit(self)
	if hp <= 0:
		state_machine.transition("Death")
	else:
		flash_hit()
	return true
