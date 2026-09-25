extends MoveSequenceState
## SoR2 back attack: hold ATTACK, press JUMP. Elbow (8) then backfist
## (12 + knockdown) behind the player. While armed, the same input throws the
## weapon forward instead (8 damage to whoever it hits).

var _throwing := false


func build_steps() -> Array[Dictionary]:
	var player := fighter as Player
	_throwing = player.weapon != &""
	if _throwing:
		return [{"anim": &"strong_punch", "duration": 0.3}]
	return [
		{"anim": &"light_punch", "duration": 0.2, "hit_at": 0.06, "hit_len": 0.08, "damage": 8, "reach": "back"},
		{"anim": &"spinning_backfist", "duration": 0.32, "hit_at": 0.1, "hit_len": 0.1, "damage": 12, "knockdown": true, "reach": "back"},
	]


func on_step_started(_step: Dictionary) -> void:
	if _throwing:
		(fighter as Player).throw_weapon()
