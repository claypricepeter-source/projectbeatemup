class_name RagnarosLiquidProjectile
extends Node2D
## Milky aimed shot. Passing its target point counts as a successful lane dodge.

signal resolved(dodged: bool)

const SPEED := 360.0
const DAMAGE := 8
const PASS_DISTANCE := 92.0
const HIT_X := 15.0
const DEPTH_BAND := 12.0
const VISUAL_Y := -62.0

var source_fighter: Fighter
var _direction := Vector2.RIGHT
var _travelled := 0.0
var _max_distance := 600.0
var _pulse := 0.0
var _finished := false


func setup(new_source: Fighter, target: Fighter) -> void:
	source_fighter = new_source
	var target_point := target.global_position
	var offset := target_point - global_position
	_direction = offset.normalized() if offset.length_squared() > 0.01 else Vector2(float(new_source.facing), 0.0)
	_max_distance = clampf(offset.length() + PASS_DISTANCE, 240.0, 760.0)


func _physics_process(delta: float) -> void:
	var step := SPEED * delta
	global_position += _direction * step
	_travelled += step
	_pulse += delta
	queue_redraw()
	if _try_hit_player():
		return
	if _travelled >= _max_distance:
		_finish(true)


func _draw() -> void:
	var swell := sin(_pulse * 18.0) * 0.8
	draw_set_transform(Vector2(0.0, VISUAL_Y), _direction.angle())
	var tail := PackedVector2Array([
		Vector2(-3.0, -7.0), Vector2(-20.0, -6.0), Vector2(-38.0, -4.0),
		Vector2(-62.0, -1.0), Vector2(-72.0, 1.0), Vector2(-43.0, 4.0),
		Vector2(-20.0, 6.0), Vector2(-3.0, 7.0)])
	draw_colored_polygon(tail, Color(1.0, 0.99, 0.91, 0.82))
	draw_circle(Vector2.ZERO, 9.0 + swell, Color(1.0, 0.98, 0.88, 0.98))
	draw_circle(Vector2(-8.0, 0.0), 6.5, Color(0.96, 0.96, 0.86, 0.92))
	draw_circle(Vector2(-28.0, -2.0), 4.0, Color(1.0, 1.0, 0.94, 0.82))
	draw_circle(Vector2(-48.0, 3.0), 2.8, Color(1.0, 1.0, 0.96, 0.74))
	draw_circle(Vector2(-67.0, -3.0), 2.1, Color(1.0, 1.0, 0.96, 0.62))
	draw_arc(Vector2.ZERO, 9.0 + swell, 0.0, TAU, 16, Color(0.7, 0.74, 0.62, 0.9), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0)


func _try_hit_player() -> bool:
	if _finished or not is_instance_valid(source_fighter):
		return false
	for node in get_tree().get_nodes_in_group("players"):
		var target := node as Fighter
		if target == null or target.is_dead:
			continue
		if absf(global_position.x - target.global_position.x) > HIT_X:
			continue
		if absf(global_position.y - target.global_position.y) > DEPTH_BAND:
			continue
		if target.take_hit(DAMAGE, false, source_fighter):
			source_fighter.on_attack_connected(target, target.hp <= 0)
			ImpactManager.connected_hit(target, false)
		_finish(false)
		return true
	return false


func cancel() -> void:
	if _finished:
		return
	_finished = true
	queue_free()


func _finish(dodged: bool) -> void:
	if _finished:
		return
	_finished = true
	resolved.emit(dodged)
	queue_free()
