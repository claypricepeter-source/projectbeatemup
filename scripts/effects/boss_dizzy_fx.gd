extends Node2D
## Three orbiting stars make the earned boss vulnerability readable at a glance.

var _elapsed := 0.0


func _ready() -> void:
	set_process(false)
	visible = false


func set_active(enabled: bool) -> void:
	visible = enabled
	set_process(enabled)
	_elapsed = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	for index in 3:
		var angle := _elapsed * 3.6 + TAU * float(index) / 3.0
		var center := Vector2(cos(angle) * 34.0, sin(angle) * 9.0)
		_draw_star(center, 8.0, Color(1.0, 0.84, 0.18, 1.0))


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 10:
		var point_radius := radius if index % 2 == 0 else radius * 0.42
		var angle := -PI * 0.5 + TAU * float(index) / 10.0
		points.append(center + Vector2(cos(angle), sin(angle)) * point_radius)
	draw_colored_polygon(points, color)
	draw_polyline(points, Color(0.48, 0.2, 0.03, 1.0), 1.0, true)
