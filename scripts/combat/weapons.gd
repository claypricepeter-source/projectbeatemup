class_name Weapons
extends RefCounted
## SoR2 weapon table (AGENTS.md §4.2). Damage values follow the SoR2 move FAQ:
## knife 16, pipe 24. A weapon disappears after it has been dropped three
## times; a thrown weapon deals 8 to whoever it hits.

const KNIFE := &"knife"
const PIPE := &"pipe"
const MAX_DROPS := 3
const THROWN_DAMAGE := 8

const DATA := {
	&"knife": {
		"name": "KNIFE",
		"damage": 16,
		"knockdown": false,
		"anim": &"light_punch",
		"duration": 0.26,
		"hit_at": 0.07,
		"hit_len": 0.08,
		"color": Color(0.85, 0.9, 0.95),
		"length": 16.0,
	},
	&"pipe": {
		"name": "PIPE",
		"damage": 24,
		"knockdown": true,
		"anim": &"strong_punch",
		"duration": 0.44,
		"hit_at": 0.16,
		"hit_len": 0.1,
		"color": Color(0.55, 0.58, 0.62),
		"length": 34.0,
	},
}


static func info(kind: StringName) -> Dictionary:
	return DATA.get(kind, {})


## Draws a weapon lying along +X from the origin (used by pickups, the held
## weapon and thrown weapons so all three always match).
static func draw_weapon(canvas: CanvasItem, kind: StringName, angle: float) -> void:
	var data := info(kind)
	if data.is_empty():
		return
	var length: float = data["length"]
	var dir := Vector2.RIGHT.rotated(angle)
	var normal := dir.orthogonal()
	var color: Color = data["color"]
	var outline := Color(0.05, 0.05, 0.07)
	if kind == KNIFE:
		var handle_end := dir * 6.0
		canvas.draw_line(Vector2.ZERO, handle_end, outline, 5.0)
		canvas.draw_line(Vector2.ZERO, handle_end, Color(0.35, 0.2, 0.1), 3.0)
		var blade := PackedVector2Array([
			handle_end + normal * 2.5, handle_end + dir * length, handle_end - normal * 2.0,
		])
		canvas.draw_colored_polygon(blade, color)
		canvas.draw_polyline(blade + PackedVector2Array([blade[0]]), outline, 1.0)
	else:
		canvas.draw_line(Vector2.ZERO, dir * length, outline, 6.0)
		canvas.draw_line(Vector2.ZERO, dir * length, color, 4.0)
		canvas.draw_line(dir * 2.0, dir * (length - 2.0), color.lightened(0.4), 1.0)
