extends MoveSequenceState
## SoR2 "hold ATTACK and release": low sidekick then high sidekick
## (16 + 20, knockdown on the second; the second kick never fails).


func build_steps() -> Array[Dictionary]:
	return [
		{"anim": &"light_kick", "duration": 0.28, "hit_at": 0.1, "hit_len": 0.1, "damage": 16},
		{"anim": &"strong_kick", "duration": 0.36, "hit_at": 0.12, "hit_len": 0.1, "damage": 20, "knockdown": true},
	]
