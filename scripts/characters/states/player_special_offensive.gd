extends MoveSequenceState
## SoR2 offensive special (toward + SPECIAL): an advancing eight-hit flurry
## (6+8+8+10+6+8+8+20, knockdown on the last). Not invulnerable; always costs
## 8 HP once the animation completes.


func build_steps() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var damages := [6, 8, 8, 10, 6, 8, 8]
	for i in damages.size():
		result.append({
			"anim": &"light_punch" if i % 2 == 0 else &"strong_punch",
			"duration": 0.1, "hit_at": 0.02, "hit_len": 0.06,
			"damage": damages[i], "advance": 70.0,
		})
	result.append({"anim": &"burning_uppercut", "duration": 0.36, "hit_at": 0.04, "hit_len": 0.12,
		"damage": 20, "knockdown": true, "advance": 40.0})
	return result


func on_move_started() -> void:
	fighter.sprite.self_modulate = Color(1.5, 1.0, 0.7)


func on_move_finished() -> void:
	(fighter as Player).pay_special_cost()


func exit() -> void:
	super()
	fighter.sprite.self_modulate = Color.WHITE
