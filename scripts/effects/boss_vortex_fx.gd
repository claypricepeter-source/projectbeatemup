class_name BossVortexFX
extends Node2D
## Constant pixel-art embers orbiting the boss's lower flame cyclone.

const COLORS := [
	Color(1.0, 0.26, 0.02, 0.92),
	Color(1.0, 0.56, 0.03, 0.96),
	Color(1.0, 0.84, 0.16, 0.94),
]

var elapsed := 0.0


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	for ring in 3:
		var radius_x := 34.0 + ring * 12.0
		var radius_y := 7.0 + ring * 3.0
		var speed := 2.5 + ring * 0.65
		for spark in 8:
			var angle := elapsed * speed + float(spark) * TAU / 8.0 + ring * 0.7
			var spark_position := Vector2(cos(angle) * radius_x, sin(angle) * radius_y - ring * 3.0)
			var pixel_size := 3.0 + float((spark + ring) % 2) * 2.0
			draw_rect(
				Rect2(spark_position - Vector2(pixel_size, pixel_size) * 0.5, Vector2(pixel_size, pixel_size)),
				COLORS[(spark + ring) % COLORS.size()])
	for flame in 5:
		var phase := fmod(elapsed * 2.1 + flame * 0.19, 1.0)
		var x := -34.0 + flame * 17.0 + sin(elapsed * 5.0 + flame) * 4.0
		var y := -8.0 - phase * 22.0
		var size := 5.0 if phase < 0.55 else 3.0
		draw_rect(Rect2(Vector2(x, y), Vector2(size, size * 2.0)), COLORS[flame % COLORS.size()])
