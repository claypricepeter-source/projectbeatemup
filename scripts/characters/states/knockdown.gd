extends FighterState
## Shared knockdown: knocked back and airborne, lies on the ground (rotated
## sprite — the free pack has no dedicated knockdown frames), gets up, and
## returns to Idle. Invulnerable throughout; Player adds i-frames after.

const KNOCKBACK_X := 120.0
const POP_VELOCITY := 140.0
const DOWN_TIME := 0.7
const GETUP_TIME := 0.35

enum Phase { AIRBORNE, DOWN, GETUP }

var _phase := Phase.AIRBORNE
var _timer := 0.0


func enter() -> void:
	fighter.hitbox.deactivate()
	fighter.invulnerable = true
	fighter.play(&"hurt")
	fighter.velocity = Vector2(-fighter.facing * KNOCKBACK_X, 0)
	fighter.air_velocity = POP_VELOCITY
	_phase = Phase.AIRBORNE


func exit() -> void:
	fighter.sprite.rotation = 0.0


func physics_update(delta: float) -> void:
	match _phase:
		Phase.AIRBORNE:
			var landed := fighter.update_air(delta)
			fighter.apply_movement(delta)
			if landed:
				_phase = Phase.DOWN
				_timer = DOWN_TIME
				fighter.velocity = Vector2.ZERO
				if fighter.sprite.sprite_frames.has_animation(&"knockdown"):
					fighter.play(&"knockdown")
				else:
					fighter.sprite.rotation_degrees = -90.0 * fighter.facing
		Phase.DOWN:
			_timer -= delta
			if _timer <= 0.0:
				_phase = Phase.GETUP
				_timer = GETUP_TIME
				fighter.sprite.rotation = 0.0
				fighter.play(&"getup" if fighter.sprite.sprite_frames.has_animation(&"getup") else &"idle")
		Phase.GETUP:
			_timer -= delta
			if _timer <= 0.0:
				fighter.end_knockdown()
				machine.transition("Idle")
