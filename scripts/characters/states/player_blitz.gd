extends MoveSequenceState
## SoR2 blitz (Forward, Forward, ATTACK): a dashing Grand Upper that closes
## distance — 24, 4, then 20 + knockdown.


func build_steps() -> Array[Dictionary]:
	return [
		{"anim": &"run", "duration": 0.12, "advance": 330.0},
		{"anim": &"power_forearm", "duration": 0.16, "hit_at": 0.0, "hit_len": 0.12, "damage": 24, "advance": 240.0},
		{"anim": &"burning_uppercut", "duration": 0.12, "hit_at": 0.0, "hit_len": 0.08, "damage": 4, "advance": 90.0},
		{"anim": &"burning_uppercut", "duration": 0.3, "hit_at": 0.02, "hit_len": 0.1, "damage": 20, "knockdown": true, "advance": 30.0},
	]
