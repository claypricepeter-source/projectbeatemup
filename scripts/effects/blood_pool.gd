class_name BloodPool
extends Node2D
## Stepped SNES-style brown pool that slowly spreads and bubbles beneath Sean.

const OUTER_COLOR := Color(0.22, 0.09, 0.02, 0.96)
const INNER_COLOR := Color(0.43, 0.22, 0.055, 0.9)
const SHINE_COLOR := Color(0.61, 0.34, 0.09, 0.88)
const BUBBLE_COLOR := Color(0.73, 0.45, 0.13, 0.98)
const BURST_COLOR := Color(0.86, 0.6, 0.2, 0.94)
const EXPAND_SECONDS := 5.0
const PIXEL := 4
const EXPAND_STEPS := 32.0
const BUBBLES := [
	{"position": Vector2(-72, -5), "start": 0.28, "period": 0.72},
	{"position": Vector2(-43, 8), "start": 0.76, "period": 0.84},
	{"position": Vector2(-12, -9), "start": 1.12, "period": 0.68},
	{"position": Vector2(18, 7), "start": 0.52, "period": 0.77},
	{"position": Vector2(49, -6), "start": 1.36, "period": 0.71},
	{"position": Vector2(76, 5), "start": 1.72, "period": 0.81},
]

var _expand_tween: Tween
var _elapsed := 0.0
var _progress := 0.0
var _animating := false


func _ready() -> void:
	reset_pool()


func _draw() -> void:
	var stepped := maxf(floorf(_progress * EXPAND_STEPS) / EXPAND_STEPS, 0.035)
	_draw_pixel_ellipse(Vector2(108.0, 26.0) * stepped, OUTER_COLOR)
	_draw_pixel_ellipse(Vector2(72.0, 14.0) * stepped, INNER_COLOR)
	_draw_surface_pixels(stepped)
	if _animating or _progress >= 1.0:
		_draw_bubbles(stepped)


func _process(delta: float) -> void:
	_elapsed += delta
	_progress = clampf(_elapsed / EXPAND_SECONDS, 0.0, 1.0)
	if _elapsed >= EXPAND_SECONDS:
		_elapsed = EXPAND_SECONDS
		_progress = 1.0
		_animating = false
	queue_redraw()


func expand() -> void:
	if _expand_tween and _expand_tween.is_valid():
		_expand_tween.kill()
	visible = true
	modulate.a = 0.0
	scale = Vector2.ONE
	_elapsed = 0.0
	_progress = 0.0
	_animating = true
	set_process(true)
	queue_redraw()
	_expand_tween = create_tween()
	_expand_tween.tween_property(self, "modulate:a", 1.0, 0.24)


func reset_pool() -> void:
	if _expand_tween and _expand_tween.is_valid():
		_expand_tween.kill()
	visible = false
	modulate = Color.WHITE
	scale = Vector2.ONE
	_elapsed = 0.0
	_progress = 0.0
	_animating = false
	set_process(false)
	queue_redraw()


func _draw_pixel_ellipse(radius: Vector2, color: Color) -> void:
	var radius_y := maxi(int(radius.y), PIXEL)
	var radius_x := maxi(int(radius.x), PIXEL)
	for y in range(-radius_y, radius_y + 1, PIXEL):
		var normalized_y := float(y) / float(radius_y)
		var half_width := int(sqrt(maxf(0.0, 1.0 - normalized_y * normalized_y)) * radius_x)
		half_width = maxi(int(floor(float(half_width) / float(PIXEL))) * PIXEL, PIXEL)
		draw_rect(Rect2(-half_width, y, half_width * 2 + PIXEL, PIXEL), color)


func _draw_surface_pixels(progress: float) -> void:
	var width := 100.0 * progress
	if width < 18.0:
		return
	for mark in [Vector2(-0.68, -5), Vector2(-0.32, 6), Vector2(0.05, -7), Vector2(0.42, 4), Vector2(0.71, -3)]:
		var mark_position := Vector2(mark.x * width, mark.y)
		draw_rect(Rect2(mark_position, Vector2(8, PIXEL)), SHINE_COLOR)


func _draw_bubbles(progress: float) -> void:
	for bubble: Dictionary in BUBBLES:
		var center: Vector2 = bubble["position"]
		if absf(center.x) > 103.0 * progress:
			continue
		var start := float(bubble["start"])
		if _elapsed < start:
			continue
		var period := float(bubble["period"])
		var phase := fmod(_elapsed - start, period) / period
		if phase < 0.68:
			var size := PIXEL if phase < 0.28 else PIXEL * 2
			draw_rect(Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size)), BUBBLE_COLOR)
			if size > PIXEL:
				draw_rect(Rect2(center - Vector2(2, 2), Vector2(4, 4)), OUTER_COLOR)
		else:
			var burst_step := 4 if phase < 0.84 else 8
			for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				var pixel_position := Vector2(center.x + direction.x * float(burst_step) - 2.0, center.y + direction.y * float(burst_step) - 2.0)
				draw_rect(Rect2(pixel_position, Vector2(4, 4)), BURST_COLOR)
