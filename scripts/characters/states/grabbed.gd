extends FighterState
## Held by an opponent (SoR2 grapple). The holder positions this fighter every
## frame; if the holder does nothing for grab_escape_time, the victim breaks
## loose. Holding moves and throws are driven from the holder's Grab state.

var _escape_timer := 0.0


func enter() -> void:
	fighter.hitbox.deactivate()
	fighter.velocity = Vector2.ZERO
	fighter.play(&"hurt")
	fighter.sprite.pause()
	fighter.sprite.frame = 0
	_escape_timer = fighter.grab_escape_time


func exit() -> void:
	fighter.held_by = null
	fighter.sprite.rotation = 0.0


## Called by the holder after each holding attack to delay the escape.
func extend_hold(seconds: float) -> void:
	_escape_timer = maxf(_escape_timer, seconds)


func physics_update(delta: float) -> void:
	var holder := fighter.held_by
	if holder == null or not is_instance_valid(holder) or holder.is_dead:
		machine.transition("Idle")
		return
	_escape_timer -= delta
	if _escape_timer <= 0.0:
		holder.call("on_grab_broken")
		fighter.release_from_grab(-fighter.facing * 60.0)
		return
	# Small struggle shake sells the hold.
	fighter.sprite.rotation = sin(Time.get_ticks_msec() * 0.03) * 0.04
