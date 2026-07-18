class_name HarbourStage
extends Stage
## Stage 2's processing-floor arena, assembled from the user-provided industrial
## sheet. A doorless room core repeats into one tunnel, with the supplied green
## rectangles animated across every open channel around the platform.

const STAGE_WIDTH := 5120.0
const ROOM_TOP := -40.0
const ROOM_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_2/industrial_room.png")
const ACID_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_2/acid_pool_frames.png")
const ACID_FRAME_COUNT := 15
const ACID_FRAME_SIZE := Vector2(862, 33)
const ACID_FRAME_TIME := 0.11
const ACID_REAR_TOP := 183.0
const ACID_REAR_BOTTOM := 217.0
const ACID_LOWER_TOP := 276.0
const ACID_LOWER_BOTTOM := 480.0
const WALL_SIGN_SEED := 2026071702
const WALL_SIGN_SAFE_X: Array[float] = [137.0, 382.0, 624.0]
const WALL_SIGN_TEXTURES: Array[Texture2D] = [
	preload("res://assets/backgrounds/stage_2/wall_signs/tim_hortons_red_sign.png"),
	preload("res://assets/backgrounds/stage_2/wall_signs/tim_hortons_wordmark.png"),
	preload("res://assets/backgrounds/stage_2/wall_signs/tim_hortons_oval.png"),
	preload("res://assets/backgrounds/stage_2/wall_signs/pakistan_flag.png"),
	preload("res://assets/backgrounds/stage_2/wall_signs/brampton_exit.png"),
]
const CURRY_TEXTURE: Texture2D = preload("res://assets/backgrounds/stage_2/wall_signs/curry_powder.png")
const CURRY_SEED := 2026071731
const CURRY_COUNT := 12
const CURRY_MIN_Y := 286.0
const CURRY_MAX_Y := 346.0

var _acid_frame := 0
var _acid_elapsed := 0.0
var _wall_signs: Array[Dictionary] = []
var _floating_curry: Array[Dictionary] = []


func _ready() -> void:
	super()
	# Direct F6/debug launches bypass MainFlow's campaign music routing.
	AudioManager.play_music(&"stage_2")
	_build_wall_signs()
	_build_floating_curry()
	queue_redraw()


func _process(delta: float) -> void:
	_acid_elapsed += delta
	var advanced := false
	while _acid_elapsed >= ACID_FRAME_TIME:
		_acid_elapsed -= ACID_FRAME_TIME
		_acid_frame = (_acid_frame + 1) % ACID_FRAME_COUNT
		advanced = true
	if advanced:
		queue_redraw()


func _draw() -> void:
	# The keyed grates and drainage openings reveal this stagnant green-black void.
	draw_rect(Rect2(0, 0, STAGE_WIDTH, 480), Color(0.045, 0.075, 0.018, 1))
	_draw_acid_band(ACID_REAR_TOP, ACID_REAR_BOTTOM)
	_draw_acid_band(ACID_LOWER_TOP, ACID_LOWER_BOTTOM)

	# Only the doorless core of the original room is retained. Repeating it at native
	# resolution creates one continuous tunnel without grey doors at tile boundaries.
	var tile_width := float(ROOM_TEXTURE.get_width())
	var tile_x := 0.0
	while tile_x < STAGE_WIDTH:
		draw_texture(ROOM_TEXTURE, Vector2(tile_x, ROOM_TOP))
		tile_x += tile_width
	for curry: Dictionary in _floating_curry:
		_draw_floating_curry(curry)
	_draw_wall_signs()


func _draw_acid_band(top: float, bottom: float) -> void:
	var source := Rect2(0, float(_acid_frame) * ACID_FRAME_SIZE.y, ACID_FRAME_SIZE.x, ACID_FRAME_SIZE.y)
	var acid_x := 0.0
	while acid_x < STAGE_WIDTH:
		var destination := Rect2(acid_x, top, ACID_FRAME_SIZE.x, bottom - top)
		draw_texture_rect_region(ACID_TEXTURE, destination, source)
		acid_x += ACID_FRAME_SIZE.x


func _build_wall_signs() -> void:
	_wall_signs.clear()
	var random := RandomNumberGenerator.new()
	random.seed = WALL_SIGN_SEED
	var tile_width := float(ROOM_TEXTURE.get_width())
	var tile_x := 0.0
	var sign_number := 0
	while tile_x < STAGE_WIDTH - tile_width:
		var available_slots := [0, 1, 2]
		if tile_x < 1.0:
			available_slots.remove_at(0)
		var signs_in_tile := 2 if random.randf() < 0.58 else 1
		for _slot_number in signs_in_tile:
			var available_index := random.randi_range(0, available_slots.size() - 1)
			var slot_index := int(available_slots[available_index])
			available_slots.remove_at(available_index)
			var texture_index := sign_number if sign_number < WALL_SIGN_TEXTURES.size() else random.randi_range(0, WALL_SIGN_TEXTURES.size() - 1)
			_append_wall_sign(random, texture_index, tile_x + WALL_SIGN_SAFE_X[slot_index])
			sign_number += 1
		tile_x += tile_width


func _append_wall_sign(random: RandomNumberGenerator, texture_index: int, wall_x: float) -> void:
	var texture := WALL_SIGN_TEXTURES[texture_index]
	var scale_options := [0.28, 0.32, 0.36]
	var sign_scale: float = scale_options[random.randi_range(0, scale_options.size() - 1)]
	var sign_size := Vector2(
		roundf(float(texture.get_width()) * sign_scale),
		roundf(float(texture.get_height()) * sign_scale))
	var minimum_y := 52.0 + sign_size.y * 0.5
	var maximum_y := 172.0 - sign_size.y * 0.5
	var center_y := random.randf_range(minimum_y, maximum_y)
	_wall_signs.append({
		"texture": texture,
		"center": Vector2(wall_x + random.randf_range(-5.0, 5.0), center_y),
		"size": sign_size,
		"rotation": random.randf_range(-0.02, 0.02),
	})


func _draw_wall_signs() -> void:
	for wall_sign: Dictionary in _wall_signs:
		var texture := wall_sign["texture"] as Texture2D
		var center: Vector2 = wall_sign["center"]
		var sign_size: Vector2 = wall_sign["size"]
		draw_set_transform(center, float(wall_sign["rotation"]))
		draw_texture_rect(texture, Rect2(-sign_size * 0.5, sign_size), false, Color(1, 1, 1, 0.92))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _build_floating_curry() -> void:
	_floating_curry.clear()
	var random := RandomNumberGenerator.new()
	random.seed = CURRY_SEED
	var section_width := STAGE_WIDTH / float(CURRY_COUNT)
	for index in CURRY_COUNT:
		_floating_curry.append({
			"x": section_width * (float(index) + 0.5) + random.randf_range(-90.0, 90.0),
			"y": random.randf_range(CURRY_MIN_Y, CURRY_MAX_Y),
			"scale": random.randf_range(0.82, 1.05),
		})


func _draw_floating_curry(curry: Dictionary) -> void:
	var source_size := CURRY_TEXTURE.get_size()
	var source_half_height := floorf(source_size.y * 0.5)
	var prop_scale := float(curry["scale"])
	var draw_size := Vector2(roundf(source_size.x * prop_scale), roundf(source_size.y * prop_scale))
	var draw_half_height := floorf(draw_size.y * 0.5)
	var left := float(curry["x"]) - draw_size.x * 0.5
	var surface_y := float(curry["y"])
	var top_source := Rect2(0, 0, source_size.x, source_half_height)
	var lower_source := Rect2(0, source_half_height, source_size.x, source_size.y - source_half_height)
	draw_texture_rect_region(CURRY_TEXTURE, Rect2(left, surface_y - draw_half_height, draw_size.x, draw_half_height), top_source)
	draw_texture_rect_region(CURRY_TEXTURE, Rect2(left, surface_y, draw_size.x, draw_size.y - draw_half_height), lower_source, Color(0.48, 0.68, 0.24, 0.58))
	draw_line(Vector2(left - 5.0, surface_y), Vector2(left + draw_size.x + 5.0, surface_y), Color(0.62, 0.78, 0.1, 0.9), 2.0)
