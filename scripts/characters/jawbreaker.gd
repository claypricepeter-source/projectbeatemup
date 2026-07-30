class_name Jawbreaker
extends SlickRick
## Stage 3 boss: candy-factory guardian using Slick Rick's complete boss FSM
## with a distinct pink palette and data resource.


func _ready() -> void:
	super()
	sprite.self_modulate = Color(1.2, 0.4, 0.8, 1.0)
