class_name HarbourStage
extends Stage
## Procedural SNES-style waterfront foreground. All shapes stay project-native
## while the parallax scene supplies dusk sky and distant grain elevators.

const STAGE_WIDTH := 5120.0


func _ready() -> void:
	super()
	queue_redraw()


func _draw() -> void:
	# Georgian Bay and shoreline.
	draw_rect(Rect2(0, 126, STAGE_WIDTH, 72), Color(0.08, 0.25, 0.36, 1))
	draw_rect(Rect2(0, 158, STAGE_WIDTH, 40), Color(0.045, 0.18, 0.29, 1))
	for x in range(0, int(STAGE_WIDTH), 48):
		var shimmer := 4.0 if int(x / 48) % 3 == 0 else 0.0
		draw_line(Vector2(float(x), 148.0 + shimmer), Vector2(float(x + 24), 148.0 + shimmer), Color(0.34, 0.58, 0.66, 0.62), 2.0)
		draw_line(Vector2(float(x + 14), 174.0 - shimmer), Vector2(float(x + 40), 174.0 - shimmer), Color(0.18, 0.42, 0.52, 0.55), 2.0)

	# Dock deck and lower service apron.
	draw_rect(Rect2(0, 190, STAGE_WIDTH, 290), Color(0.17, 0.23, 0.27, 1))
	draw_rect(Rect2(0, 190, STAGE_WIDTH, 18), Color(0.42, 0.34, 0.24, 1))
	draw_line(Vector2(0, 208), Vector2(STAGE_WIDTH, 208), Color(0.07, 0.1, 0.12, 1), 4.0)
	for x in range(0, int(STAGE_WIDTH), 64):
		draw_line(Vector2(float(x), 208), Vector2(float(x), 480), Color(0.1, 0.15, 0.18, 0.82), 2.0)
	for y in range(236, 480, 34):
		draw_line(Vector2(0, float(y)), Vector2(STAGE_WIDTH, float(y)), Color(0.25, 0.31, 0.33, 0.72), 2.0)

	# Safety stripe along the water edge.
	for x in range(0, int(STAGE_WIDTH), 48):
		var stripe_color := Color(0.9, 0.62, 0.08, 1) if int(x / 48) % 2 == 0 else Color(0.08, 0.1, 0.12, 1)
		draw_rect(Rect2(float(x), 190, 48, 8), stripe_color)

	# Container yards break each combat screen into readable landmarks.
	_draw_container(Vector2(180, 112), Vector2(196, 78), Color(0.62, 0.16, 0.12, 1))
	_draw_container(Vector2(390, 128), Vector2(180, 62), Color(0.12, 0.38, 0.5, 1))
	_draw_container(Vector2(1120, 120), Vector2(220, 70), Color(0.12, 0.42, 0.32, 1))
	_draw_container(Vector2(1360, 102), Vector2(186, 88), Color(0.68, 0.34, 0.08, 1))
	_draw_container(Vector2(2120, 122), Vector2(208, 68), Color(0.52, 0.15, 0.2, 1))
	_draw_container(Vector2(2740, 110), Vector2(214, 80), Color(0.1, 0.34, 0.53, 1))
	_draw_container(Vector2(3360, 124), Vector2(190, 66), Color(0.58, 0.26, 0.08, 1))
	_draw_container(Vector2(4140, 104), Vector2(210, 86), Color(0.08, 0.4, 0.36, 1))

	_draw_crane(780.0)
	_draw_crane(1860.0)
	_draw_crane(3720.0)
	_draw_boat(620.0)
	_draw_boat(2460.0)
	_draw_boat(4480.0)
	for lamp_x in [80.0, 940.0, 1740.0, 2580.0, 3440.0, 4300.0, 5030.0]:
		_draw_lamp(lamp_x)

	# Boss pier is cleaner and brighter, framed by bollards.
	draw_rect(Rect2(4560, 202, 560, 7), Color(0.84, 0.63, 0.16, 1))
	for bollard_x in [4580.0, 4720.0, 4860.0, 5000.0]:
		draw_rect(Rect2(bollard_x - 7, 174, 14, 26), Color(0.08, 0.1, 0.12, 1))
		draw_circle(Vector2(bollard_x, 174), 8.0, Color(0.72, 0.48, 0.08, 1))


func _draw_container(position: Vector2, size: Vector2, color: Color) -> void:
	draw_rect(Rect2(position, size), color)
	draw_rect(Rect2(position + Vector2(5, 5), size - Vector2(10, 10)), color.darkened(0.18), false, 3.0)
	for rib_x in range(int(position.x + 18), int(position.x + size.x - 8), 24):
		draw_line(Vector2(float(rib_x), position.y + 8), Vector2(float(rib_x), position.y + size.y - 8), color.lightened(0.14), 3.0)


func _draw_crane(x: float) -> void:
	var steel := Color(0.14, 0.2, 0.24, 1)
	var highlight := Color(0.68, 0.44, 0.08, 1)
	draw_rect(Rect2(x - 9, 54, 18, 136), steel)
	draw_line(Vector2(x, 62), Vector2(x + 132, 20), steel, 12.0)
	draw_line(Vector2(x + 8, 64), Vector2(x + 132, 20), highlight, 3.0)
	draw_line(Vector2(x + 110, 27), Vector2(x + 110, 126), Color(0.1, 0.12, 0.13, 1), 3.0)
	draw_rect(Rect2(x + 100, 124, 20, 10), Color(0.68, 0.42, 0.08, 1))
	draw_line(Vector2(x - 32, 190), Vector2(x, 54), steel, 7.0)
	draw_line(Vector2(x + 32, 190), Vector2(x, 54), steel, 7.0)


func _draw_boat(x: float) -> void:
	var hull := PackedVector2Array([
		Vector2(x - 72, 160), Vector2(x + 76, 160), Vector2(x + 52, 188), Vector2(x - 48, 188)
	])
	draw_polygon(hull, PackedColorArray([Color(0.18, 0.2, 0.22, 1)]))
	draw_rect(Rect2(x - 28, 136, 56, 24), Color(0.72, 0.75, 0.7, 1))
	draw_rect(Rect2(x - 20, 141, 16, 10), Color(0.08, 0.25, 0.34, 1))
	draw_rect(Rect2(x + 5, 141, 16, 10), Color(0.08, 0.25, 0.34, 1))
	draw_line(Vector2(x, 136), Vector2(x, 103), Color(0.24, 0.28, 0.29, 1), 3.0)


func _draw_lamp(x: float) -> void:
	draw_rect(Rect2(x - 3, 106, 6, 84), Color(0.18, 0.2, 0.2, 1))
	draw_rect(Rect2(x - 14, 102, 28, 9), Color(0.12, 0.14, 0.15, 1))
	draw_circle(Vector2(x, 108), 5.0, Color(1.0, 0.76, 0.28, 1))
