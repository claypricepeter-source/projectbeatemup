extends Node
## Global signal hub (autoload "EventBus"). Cross-system events only —
## direct parent/child communication should use normal signals.

# Note: parameters are intentionally untyped — typing them with Fighter would
# create a circular dependency (EventBus -> Fighter -> EventBus) that breaks
# editor-side script compilation.
signal fighter_damaged(fighter)
signal enemy_died(points)
signal player_died
signal wave_cleared
signal stage_cleared
signal boss_health_changed(ratio)
signal pickup_collected(kind)
signal score_changed(score)
signal lives_changed(lives, continues)
