extends Node
## Global signal hub (autoload "EventBus"). Cross-system events only —
## direct parent/child communication should use normal signals.

# Note: parameters are intentionally untyped — typing them with Fighter would
# create a circular dependency (EventBus -> Fighter -> EventBus) that breaks
# editor-side script compilation.
signal fighter_damaged(fighter)
signal enemy_died(points)
signal player_died
signal player_respawned
signal wave_cleared
signal stage_cleared
signal boss_health_changed(ratio)
signal pickup_collected(kind)
signal score_changed(score)
signal lives_changed(lives, continues)
signal extra_life
## SoR2 round timer (seconds shown on the HUD) and its expiry.
signal timer_changed(seconds)
signal time_over
