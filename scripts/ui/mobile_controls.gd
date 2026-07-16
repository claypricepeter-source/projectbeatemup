class_name MobileControls
extends Node2D
## Responsive, asset-free multi-touch controls for the Web/mobile build. The
## overlay drives the canonical InputMap actions, so gameplay code stays shared
## with keyboard and gamepad controls.

const MOVE_LEFT := &"move_left_p1"
const MOVE_RIGHT := &"move_right_p1"
const MOVE_UP := &"move_up_p1"
const MOVE_DOWN := &"move_down_p1"
const ATTACK := &"attack_p1"
const JUMP := &"jump_p1"
const PAUSE := &"pause"
const BASE_SIZE := Vector2(640.0, 360.0)

@export var force_visible := false:
	set(value):
		force_visible = value
		_refresh_visibility()

var _touch_seen := false
var _move_touch := -1
var _move_vector := Vector2.ZERO
var _move_action_states := {
	MOVE_LEFT: false,
	MOVE_RIGHT: false,
	MOVE_UP: false,
	MOVE_DOWN: false,
}
var _action_touches: Dictionary = {}
var _last_mode := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_refresh_visibility()
	queue_redraw()


func _process(_delta: float) -> void:
	var mode := _controls_mode()
	if mode == _last_mode:
		return
	_last_mode = mode
	_release_all()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_touch_seen = true
		_refresh_visibility()
		if touch.pressed:
			_handle_touch_pressed(touch.index, touch.position)
		else:
			_handle_touch_released(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_touch_seen = true
		_refresh_visibility()
		if drag.index == _move_touch:
			_update_movement(drag.position)
			get_viewport().set_input_as_handled()


func _draw() -> void:
	if not visible:
		return
	var mode := _controls_mode()
	if mode == "hidden":
		return
	var scale_factor := _control_scale()
	if mode == "gameplay":
		var stick_center := _stick_center()
		var stick_radius := 52.0 * scale_factor
		var knob_position := stick_center + _move_vector * stick_radius * 0.56
		_draw_button(stick_center, stick_radius, Color(0.02, 0.08, 0.13, 0.5), Color(0.42, 0.86, 1.0, 0.78))
		draw_line(stick_center + Vector2(-25.0, 0.0) * scale_factor, stick_center + Vector2(25.0, 0.0) * scale_factor, Color(0.72, 0.94, 1.0, 0.62), 3.0 * scale_factor)
		draw_line(stick_center + Vector2(0.0, -25.0) * scale_factor, stick_center + Vector2(0.0, 25.0) * scale_factor, Color(0.72, 0.94, 1.0, 0.62), 3.0 * scale_factor)
		_draw_button(knob_position, 22.0 * scale_factor, Color(0.1, 0.35, 0.48, 0.72), Color(0.78, 0.96, 1.0, 0.9))
		_draw_labeled_button(_attack_center(), 42.0 * scale_factor, "ATTACK", 12, Color(0.48, 0.12, 0.08, 0.62), Color(1.0, 0.66, 0.25, 0.95))
		_draw_labeled_button(_jump_center(), 32.0 * scale_factor, "JUMP", 11, Color(0.06, 0.28, 0.18, 0.62), Color(0.48, 1.0, 0.68, 0.95))
		_draw_labeled_button(_pause_center(), 20.0 * scale_factor, "II", 13, Color(0.03, 0.07, 0.12, 0.68), Color(0.84, 0.94, 1.0, 0.9))
	else:
		_draw_labeled_button(_attack_center(), 42.0 * scale_factor, "NEXT", 12, Color(0.48, 0.12, 0.08, 0.68), Color(1.0, 0.66, 0.25, 0.95))


func _draw_button(center: Vector2, radius: float, fill: Color, outline: Color) -> void:
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 48, outline, maxf(2.0, radius * 0.065), true)


func _draw_labeled_button(center: Vector2, radius: float, label: String, font_size: int, fill: Color, outline: Color) -> void:
	_draw_button(center, radius, fill, outline)
	var scaled_font_size := maxi(roundi(float(font_size) * _control_scale()), 9)
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, scaled_font_size)
	draw_string(font, center - text_size * 0.5 + Vector2(0.0, text_size.y * 0.78), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, scaled_font_size, Color(1.0, 0.97, 0.84, 0.96))


func _handle_touch_pressed(index: int, touch_position: Vector2) -> void:
	var scale_factor := _control_scale()
	var mode := _controls_mode()
	if mode == "hidden":
		return
	if mode == "confirm":
		if touch_position.distance_to(_attack_center()) <= 52.0 * scale_factor:
			_press_action(index, ATTACK)
		return
	if touch_position.distance_to(_pause_center()) <= 27.0 * scale_factor:
		_press_action(index, PAUSE)
		return
	if touch_position.distance_to(_attack_center()) <= 52.0 * scale_factor:
		_press_action(index, ATTACK)
		return
	if touch_position.distance_to(_jump_center()) <= 42.0 * scale_factor:
		_press_action(index, JUMP)
		return
	var viewport_size := get_viewport_rect().size
	if touch_position.x <= viewport_size.x * 0.43 and touch_position.y >= viewport_size.y * 0.38:
		if _move_touch >= 0 and _move_touch != index:
			return
		_move_touch = index
		_update_movement(touch_position)
		get_viewport().set_input_as_handled()


func _handle_touch_released(index: int) -> void:
	var handled := false
	if index == _move_touch:
		_move_touch = -1
		_set_move_vector(Vector2.ZERO)
		handled = true
	if _action_touches.has(index):
		var action := _action_touches[index] as StringName
		_action_touches.erase(index)
		if not _action_is_held(action):
			Input.action_release(action)
		handled = true
	if handled:
		get_viewport().set_input_as_handled()


func _press_action(index: int, action: StringName) -> void:
	_action_touches[index] = action
	Input.action_press(action)
	get_viewport().set_input_as_handled()


func _action_is_held(action: StringName) -> bool:
	for held_action in _action_touches.values():
		if held_action == action:
			return true
	return false


func _update_movement(touch_position: Vector2) -> void:
	var relative := touch_position - _stick_center()
	var radius := 58.0 * _control_scale()
	var direction := relative / radius
	if direction.length() > 1.0:
		direction = direction.normalized()
	if direction.length() < 0.18:
		direction = Vector2.ZERO
	_set_move_vector(direction)


func _set_move_vector(direction: Vector2) -> void:
	_move_vector = direction
	_set_action(MOVE_LEFT, direction.x < -0.24)
	_set_action(MOVE_RIGHT, direction.x > 0.24)
	_set_action(MOVE_UP, direction.y < -0.24)
	_set_action(MOVE_DOWN, direction.y > 0.24)
	queue_redraw()


func _set_action(action: StringName, pressed: bool) -> void:
	if bool(_move_action_states.get(action, false)) == pressed:
		return
	_move_action_states[action] = pressed
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _release_all() -> void:
	_move_touch = -1
	_set_move_vector(Vector2.ZERO)
	for action in _action_touches.values():
		Input.action_release(action as StringName)
	_action_touches.clear()


func _refresh_visibility() -> void:
	visible = force_visible or _touch_seen or DisplayServer.is_touchscreen_available()
	queue_redraw()


func _controls_mode() -> String:
	var current_scene := get_tree().current_scene
	if current_scene == null or not current_scene.has_method("get_flow_state_name"):
		return "gameplay"
	var state := String(current_scene.call("get_flow_state_name"))
	if state == "PLAYING":
		return "gameplay"
	if state in ["INTRO", "CONTINUE", "STAGE_CLEAR", "ENDING", "GAME_OVER"]:
		return "confirm"
	return "hidden"


func _on_viewport_size_changed() -> void:
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_all()


func _exit_tree() -> void:
	_release_all()


func _control_scale() -> float:
	var viewport_size := get_viewport_rect().size
	return clampf(minf(viewport_size.x / BASE_SIZE.x, viewport_size.y / BASE_SIZE.y), 0.7, 1.6)


func _stick_center() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var scale_factor := _control_scale()
	return Vector2(82.0 * scale_factor, viewport_size.y - 72.0 * scale_factor)


func _attack_center() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var scale_factor := _control_scale()
	return Vector2(viewport_size.x - 78.0 * scale_factor, viewport_size.y - 68.0 * scale_factor)


func _jump_center() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var scale_factor := _control_scale()
	return Vector2(viewport_size.x - 158.0 * scale_factor, viewport_size.y - 42.0 * scale_factor)


func _pause_center() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var scale_factor := _control_scale()
	return Vector2(viewport_size.x - 30.0 * scale_factor, 30.0 * scale_factor)


func get_debug_state() -> Dictionary:
	return {
		"visible": visible,
		"mode": _controls_mode(),
		"touchscreen": DisplayServer.is_touchscreen_available(),
		"force_visible": force_visible,
		"viewport": get_viewport_rect().size,
		"stick_center": _stick_center(),
		"attack_center": _attack_center(),
		"jump_center": _jump_center(),
		"pause_center": _pause_center(),
		"move_vector": _move_vector,
		"move_touch": _move_touch,
		"action_touch_count": _action_touches.size(),
	}
