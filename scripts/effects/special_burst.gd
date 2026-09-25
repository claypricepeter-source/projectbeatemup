class_name SpecialBurst
extends Node2D
## Expanding flame ring for the SoR2 defensive special (drawn, no art needed).

const DURATION := 0.4

var _age := 0.0


static func spawn(at: Fighter) -> void:
	var burst := SpecialBurst.new()
	burst.position = Vector2(0.0, -54.0)
	at.get_node("Visuals").add_child(burst)


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / DURATION
	var radius := lerpf(16.0, 76.0, t)
	var alpha := 1.0 - t
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.55, 0.1, alpha), 6.0)
	draw_arc(Vector2.ZERO, radius * 0.8, 0.0, TAU, 40, Color(1.0, 0.9, 0.4, alpha * 0.8), 3.0)
