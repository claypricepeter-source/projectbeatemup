extends FighterState
## Shared death: knocked back and down like a knockdown, then fades out and
## calls Fighter.finish_death() (overridden per side).

const KNOCKBACK_X := 140.0
const POP_VELOCITY := 160.0
const LIE_TIME := 0.4
const FADE_TIME := 0.5

enum Phase { AIRBORNE, DOWN, FADING }

var _phase := Phase.AIRBORNE
var _timer := 0.0


func enter() -> void:
	fighter.is_dead = true
	fighter.invulnerable = true
	fighter.hitbox.deactivate()
	fighter.play(&"death" if fighter.sprite.sprite_frames.has_animation(&"death") else &"hurt")
	fighter.velocity = Vector2(-fighter.facing * KNOCKBACK_X, 0)
	fighter.air_velocity = POP_VELOCITY
	_phase = Phase.AIRBORNE


func physics_update(delta: float) -> void:
	match _phase:
		Phase.AIRBORNE:
			var landed := fighter.update_air(delta)
			fighter.apply_movement(delta)
			if landed:
				_phase = Phase.DOWN
				_timer = LIE_TIME
				fighter.velocity = Vector2.ZERO
				if fighter.sprite.sprite_frames.has_animation(&"death"):
					fighter.sprite.frame = fighter.sprite.sprite_frames.get_frame_count(&"death") - 1
				else:
					fighter.sprite.rotation_degrees = -90.0 * fighter.facing
		Phase.DOWN:
			_timer -= delta
			if _timer <= 0.0:
				_phase = Phase.FADING
				var tween := fighter.create_tween()
				tween.tween_property(fighter, "modulate:a", 0.0, FADE_TIME)
				tween.tween_callback(fighter.finish_death)
		Phase.FADING:
			pass
