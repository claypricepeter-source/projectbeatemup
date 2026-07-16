class_name FinaleStage
extends Stage
## Two-part finale: autumn Harrison Park and the floodlit Mill Dam.

const STAGE_WIDTH := 5120.0
const DAM_START := 3320.0


func _ready() -> void:
	super()
	queue_redraw()


func _draw() -> void:
	# Sydenham River behind the park path.
	draw_rect(Rect2(0, 118, DAM_START, 88), Color(0.055, 0.25, 0.32, 1))
	draw_rect(Rect2(0, 164, DAM_START, 42), Color(0.03, 0.16, 0.22, 1))
	for x in range(0, int(DAM_START), 52):
		var offset := 5.0 if int(x / 52) % 2 == 0 else 0.0
		draw_line(Vector2(float(x), 142 + offset), Vector2(float(x + 30), 142 + offset), Color(0.35, 0.62, 0.6, 0.62), 2.0)

	# Park lawn and late-autumn walking path.
	draw_rect(Rect2(0, 190, DAM_START, 290), Color(0.12, 0.22, 0.16, 1))
	draw_rect(Rect2(0, 202, DAM_START, 92), Color(0.27, 0.27, 0.23, 1))
	draw_rect(Rect2(0, 218, DAM_START, 60), Color(0.36, 0.32, 0.25, 1))
	for x in range(0, int(DAM_START), 84):
		draw_line(Vector2(float(x), 222), Vector2(float(x + 34), 222), Color(0.48, 0.42, 0.31, 0.55), 2.0)
		draw_circle(Vector2(float(x + 20), 314 + float(int(x / 84) % 3) * 18), 4.0, Color(0.58, 0.23, 0.08, 0.78))

	for tree_x in [130.0, 430.0, 820.0, 1180.0, 1560.0, 1940.0, 2360.0]:
		_draw_tree(tree_x, 198.0)

	# Footbridge chokepoint: the fight clamps feet to the visible deck.
	draw_rect(Rect2(2540, 214, 800, 54), Color(0.24, 0.18, 0.12, 1))
	draw_rect(Rect2(2540, 226, 800, 30), Color(0.5, 0.35, 0.18, 1))
	for plank_x in range(2550, 3340, 26):
		draw_line(Vector2(float(plank_x), 228), Vector2(float(plank_x), 254), Color(0.22, 0.13, 0.07, 1), 2.0)
	draw_line(Vector2(2540, 216), Vector2(3340, 216), Color(0.72, 0.54, 0.28, 1), 5.0)
	draw_line(Vector2(2540, 266), Vector2(3340, 266), Color(0.72, 0.54, 0.28, 1), 5.0)
	for post_x in range(2560, 3340, 80):
		draw_line(Vector2(float(post_x), 206), Vector2(float(post_x), 274), Color(0.32, 0.2, 0.1, 1), 5.0)

	# Mill Dam concrete apron and wet visual edge.
	draw_rect(Rect2(DAM_START, 110, STAGE_WIDTH - DAM_START, 370), Color(0.21, 0.25, 0.27, 1))
	draw_rect(Rect2(DAM_START, 196, STAGE_WIDTH - DAM_START, 284), Color(0.29, 0.32, 0.33, 1))
	for x in range(int(DAM_START), int(STAGE_WIDTH), 96):
		draw_line(Vector2(float(x), 196), Vector2(float(x), 480), Color(0.16, 0.19, 0.2, 0.78), 3.0)
	for y in range(226, 480, 42):
		draw_line(Vector2(DAM_START, float(y)), Vector2(STAGE_WIDTH, float(y)), Color(0.38, 0.4, 0.4, 0.5), 2.0)
	draw_rect(Rect2(DAM_START, 272, STAGE_WIDTH - DAM_START, 16), Color(0.08, 0.34, 0.42, 0.82))
	draw_line(Vector2(DAM_START, 272), Vector2(STAGE_WIDTH, 272), Color(0.46, 0.78, 0.82, 0.8), 2.0)

	# Dam wall, spillways and rushing water.
	draw_rect(Rect2(3420, 48, 760, 148), Color(0.25, 0.29, 0.3, 1))
	for spill_x in [3480.0, 3670.0, 3860.0, 4050.0]:
		draw_rect(Rect2(spill_x, 82, 112, 114), Color(0.04, 0.2, 0.28, 1))
		draw_polygon(PackedVector2Array([
			Vector2(spill_x + 8, 90), Vector2(spill_x + 104, 90),
			Vector2(spill_x + 90, 196), Vector2(spill_x + 20, 196)
		]), PackedColorArray([Color(0.5, 0.8, 0.86, 0.85)]))
		for streak in range(0, 4):
			var sx: float = spill_x + 18.0 + float(streak) * 24.0
			draw_line(Vector2(sx, 100), Vector2(sx - 6, 188), Color(0.84, 0.96, 0.96, 0.75), 3.0)

	# Fish ladder beside Victor's arena.
	draw_rect(Rect2(4390, 92, 310, 104), Color(0.1, 0.18, 0.2, 1))
	for step_x in range(4410, 4690, 44):
		draw_rect(Rect2(float(step_x), 102, 28, 84), Color(0.16, 0.42, 0.48, 1))
		draw_line(Vector2(float(step_x), 114), Vector2(float(step_x + 28), 114), Color(0.72, 0.9, 0.88, 0.7), 2.0)

	for lamp_x in [3370.0, 4230.0, 4760.0, 5060.0]:
		_draw_floodlight(lamp_x)

	# Final arena warning stripe.
	for x in range(4600, 5120, 40):
		var stripe := Color(0.92, 0.64, 0.08, 1) if int(x / 40) % 2 == 0 else Color(0.08, 0.1, 0.11, 1)
		draw_rect(Rect2(float(x), 194, 40, 8), stripe)


func _draw_tree(x: float, ground_y: float) -> void:
	draw_rect(Rect2(x - 8, ground_y - 84, 16, 84), Color(0.25, 0.13, 0.07, 1))
	draw_line(Vector2(x, ground_y - 58), Vector2(x - 32, ground_y - 94), Color(0.25, 0.13, 0.07, 1), 7.0)
	draw_line(Vector2(x, ground_y - 48), Vector2(x + 34, ground_y - 88), Color(0.25, 0.13, 0.07, 1), 7.0)
	draw_circle(Vector2(x - 30, ground_y - 104), 30.0, Color(0.65, 0.18, 0.06, 1))
	draw_circle(Vector2(x + 6, ground_y - 120), 36.0, Color(0.82, 0.34, 0.06, 1))
	draw_circle(Vector2(x + 40, ground_y - 96), 28.0, Color(0.72, 0.52, 0.08, 1))


func _draw_floodlight(x: float) -> void:
	draw_rect(Rect2(x - 4, 80, 8, 116), Color(0.12, 0.14, 0.15, 1))
	draw_rect(Rect2(x - 20, 72, 40, 16), Color(0.22, 0.24, 0.24, 1))
	draw_polygon(PackedVector2Array([
		Vector2(x - 17, 88), Vector2(x + 17, 88), Vector2(x + 54, 194), Vector2(x - 54, 194)
	]), PackedColorArray([Color(1.0, 0.82, 0.42, 0.09)]))
