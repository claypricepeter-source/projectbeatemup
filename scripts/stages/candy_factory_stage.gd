class_name CandyFactoryStage
extends Stage
## Stage 3: A nightmarish candy factory. 
## Programmatically draws hot pink boiling sugar sludge channels, candy-cane pillars,
## and repeats the custom candy factory background.

const STAGE_WIDTH := 5120.0
const BG_TEXTURE: Texture2D = preload("res://assets/backgrounds/candy_factory/candy_factory_bg.png")
const SLUDGE_TOP := 276.0
const SLUDGE_BOTTOM := 480.0
const SLUDGE_COLOR := Color(1.0, 0.2, 0.6, 0.85) # Hot pink sugar sludge!
const PILLAR_WIDTH := 40.0
const PILLAR_SPACING := 384.0

var _bubble_timer := 0.0
var _bubbles: Array[Dictionary] = []


func _ready() -> void:
	super()
	AudioManager.play_music(&"stage_3")
	# Initialize some bubbles
	for i in 15:
		_bubbles.append({
			"pos": Vector2(randf_range(0.0, STAGE_WIDTH), randf_range(SLUDGE_TOP + 10.0, SLUDGE_BOTTOM - 10.0)),
			"size": randf_range(4.0, 12.0),
			"life": randf_range(0.0, 1.0)
		})
	queue_redraw()


func _process(delta: float) -> void:
	# Animate bubbles
	for b in _bubbles:
		b["life"] += delta * 0.8
		b["pos"].y -= delta * 15.0 # rise up
		if b["life"] >= 1.0 or b["pos"].y < SLUDGE_TOP:
			b["life"] = 0.0
			b["pos"] = Vector2(randf_range(0.0, STAGE_WIDTH), randf_range(SLUDGE_TOP + 10.0, SLUDGE_BOTTOM - 10.0))
			b["size"] = randf_range(4.0, 12.0)
	queue_redraw()


func _draw() -> void:
	# 1. Draw solid dark background color first
	draw_rect(Rect2(0, 0, STAGE_WIDTH, 480), Color(0.05, 0.02, 0.04, 1))

	# 2. Draw repeated candy factory background
	var bg_w := float(BG_TEXTURE.get_width())
	var bg_h := float(BG_TEXTURE.get_height())
	var tile_x := 0.0
	while tile_x < STAGE_WIDTH:
		draw_texture(BG_TEXTURE, Vector2(tile_x, 0))
		tile_x += bg_w

	# 3. Draw programmatic candy-cane pillars
	var pillar_x := 100.0
	while pillar_x < STAGE_WIDTH:
		# Draw grey base column
		draw_rect(Rect2(pillar_x, 0, PILLAR_WIDTH, SLUDGE_TOP), Color(0.2, 0.2, 0.22, 1))
		# Draw candy cane stripes (red and white diagonal lines)
		for sy in range(0, int(SLUDGE_TOP), 30):
			draw_line(Vector2(pillar_x, float(sy)), Vector2(pillar_x + PILLAR_WIDTH, float(sy + 20)), Color(0.8, 0.1, 0.2, 1), 6.0)
			draw_line(Vector2(pillar_x, float(sy + 15)), Vector2(pillar_x + PILLAR_WIDTH, float(sy + 35)), Color(0.95, 0.95, 0.95, 1), 6.0)
		pillar_x += PILLAR_SPACING

	# 4. Draw boiling sugar sludge channel at the bottom
	draw_rect(Rect2(0, SLUDGE_TOP, STAGE_WIDTH, SLUDGE_BOTTOM - SLUDGE_TOP), SLUDGE_COLOR)
	
	# Draw bubbles in sludge
	for b in _bubbles:
		var alpha: float = 1.0 - b["life"]
		var current_size: float = b["size"] * (0.5 + 0.5 * b["life"])
		draw_circle(b["pos"], current_size, Color(1.0, 0.5, 0.8, alpha * 0.7))
		draw_circle(b["pos"], current_size * 0.8, Color(1.0, 0.8, 0.95, alpha * 0.5))
