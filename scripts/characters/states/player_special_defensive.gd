extends MoveSequenceState
## SoR2 defensive special (SPECIAL, no direction): a fully invulnerable spin
## that hits both sides for 16 + knockdown. Costs 8 HP only if it hits.

var _paid := false


func build_steps() -> Array[Dictionary]:
	return [
		{"anim": &"crouch_block", "duration": 0.55, "hit_at": 0.1, "hit_len": 0.32, "damage": 16, "knockdown": true, "reach": "both"},
	]


func on_move_started() -> void:
	_paid = false
	fighter.invulnerable = true
	fighter.sprite.self_modulate = Color(1.6, 1.1, 0.6)
	AudioManager.play_sfx(&"knockdown", -6.0)
	SpecialBurst.spawn(fighter)


func on_hits_landed(_count: int) -> void:
	if not _paid:
		_paid = true
		(fighter as Player).pay_special_cost()


func physics_update(delta: float) -> void:
	super(delta)
	# Also pay as soon as the first target is hit, like SoR2.
	if not _paid and fighter.hitbox.hits_this_swing > 0:
		on_hits_landed(1)


func exit() -> void:
	super()
	fighter.invulnerable = false
	fighter.sprite.self_modulate = Color.WHITE
