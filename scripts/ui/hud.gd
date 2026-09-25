extends CanvasLayer
## Streets of Rage 2 style HUD, drawn in code (AGENTS.md §4.4):
##   top-left  — portrait, name, score, lives and the yellow life bar
##   below it  — portrait, name and layered life bar of the last enemy hit
##               (the boss stays there while no other enemy has been hit)
##   top-centre — the 99 round timer
##   right     — flashing GO → arrow after each wave
## Bars are 104 HP wide; tougher enemies stack extra coloured layers, and a red
## ghost segment drains after each hit, as in SoR2.

const BAR_HP := 104.0
const BAR_SIZE := Vector2(156.0, 9.0)
const ENEMY_SHOW_TIME := 2.5
const GHOST_DRAIN_PER_SEC := 60.0
const LAYER_COLORS: Array[Color] = [
	Color(1.0, 0.86, 0.16), Color(1.0, 0.55, 0.12), Color(0.35, 0.9, 0.35),
	Color(0.3, 0.6, 1.0), Color(0.8, 0.4, 1.0), Color(1.0, 0.35, 0.55),
]
const TEXT_COLOR := Color(1.0, 0.95, 0.75)
const NAME_COLOR := Color(1.0, 0.86, 0.3)
const OUTLINE := Color(0.03, 0.02, 0.06)

var _canvas: Control
var _font: Font
var _player: Fighter
var _enemy: Fighter
var _enemy_time := 0.0
var _player_ghost := 0.0
var _enemy_ghost := 0.0
var _score := 0
var _lives := 3
var _time := RoundTimer.START_TIME
var _go_time := 0.0
var _banner := ""
var _banner_time := 0.0
var _portraits := {}


func _ready() -> void:
	_font = ThemeDB.fallback_font
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)
	EventBus.fighter_damaged.connect(_on_fighter_damaged)
	EventBus.wave_cleared.connect(_on_wave_cleared)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.lives_changed.connect(_on_lives_changed)
	EventBus.timer_changed.connect(_on_timer_changed)
	EventBus.time_over.connect(_on_time_over)
	EventBus.extra_life.connect(_on_extra_life)
	_score = GameState.score
	_lives = GameState.lives
	_find_player.call_deferred()


func _find_player() -> void:
	# Skip the previous stage's player while it is still queued for deletion.
	for node in get_tree().get_nodes_in_group("players"):
		var candidate := node as Fighter
		if candidate and not candidate.is_queued_for_deletion() and _belongs_to_stage(candidate):
			_player = candidate
			_player_ghost = _player.hp
			return


func _belongs_to_stage(fighter: Fighter) -> bool:
	var stage_root := get_parent()
	return stage_root == null or stage_root.is_ancestor_of(fighter)


func _process(delta: float) -> void:
	_enemy_time = maxf(_enemy_time - delta, 0.0)
	_go_time = maxf(_go_time - delta, 0.0)
	_banner_time = maxf(_banner_time - delta, 0.0)
	if not is_instance_valid(_player):
		_player = null
		_find_player()
	if _player:
		_player_ghost = _drain(_player_ghost, _player.hp, delta)
	var shown := _shown_enemy()
	if shown:
		_enemy_ghost = _drain(_enemy_ghost, shown.hp, delta)
	_canvas.queue_redraw()


func _drain(ghost: float, hp: int, delta: float) -> float:
	if ghost < hp:
		return float(hp)
	return maxf(ghost - GHOST_DRAIN_PER_SEC * delta, float(hp))


func _on_fighter_damaged(fighter) -> void:
	var f := fighter as Fighter
	if f == null or f.is_in_group("players"):
		return
	if f != _enemy:
		_enemy_ghost = f.hp
	_enemy = f
	_enemy_time = ENEMY_SHOW_TIME


func _on_score_changed(score) -> void:
	_score = int(score)


func _on_lives_changed(lives, _continues) -> void:
	_lives = int(lives)


func _on_timer_changed(seconds) -> void:
	_time = int(seconds)


func _on_time_over() -> void:
	_show_banner("TIME OVER", 2.0)


func _on_extra_life() -> void:
	_show_banner("1 UP", 1.4)


func _on_wave_cleared() -> void:
	_go_time = 3.6


func _show_banner(text: String, seconds: float) -> void:
	_banner = text
	_banner_time = seconds


func _shown_enemy() -> Fighter:
	if _enemy_time > 0.0 and is_instance_valid(_enemy) and not _enemy.is_queued_for_deletion():
		return _enemy
	for node in get_tree().get_nodes_in_group("bosses"):
		var boss := node as Fighter
		if boss and not boss.is_dead and not boss.is_queued_for_deletion():
			if boss != _enemy:
				_enemy = boss
				_enemy_ghost = boss.hp
			return boss
	return null


# --- Drawing -----------------------------------------------------------------

func _on_draw() -> void:
	_draw_player_block()
	var shown := _shown_enemy()
	if shown:
		_draw_enemy_block(shown)
	_draw_timer()
	if _go_time > 0.0 and int(_go_time * 4.0) % 2 == 0:
		_draw_go()
	if _banner_time > 0.0:
		var width := _canvas.size.x
		_text(Vector2(0.0, 150.0), _banner, 34, NAME_COLOR, HORIZONTAL_ALIGNMENT_CENTER, width)


func _draw_player_block() -> void:
	var origin := Vector2(10.0, 8.0)
	_draw_portrait(_player if is_instance_valid(_player) else null, Rect2(origin, Vector2(30.0, 30.0)))
	_text(origin + Vector2(36.0, 0.0), "%d" % _score, 13, TEXT_COLOR)
	_text(origin + Vector2(36.0, 12.0), "SEAN", 12, NAME_COLOR)
	var name_width := _font.get_string_size("SEAN", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12).x
	_text(origin + Vector2(36.0 + name_width + 10.0, 12.0), "=%d" % _lives, 12, TEXT_COLOR)
	var hp := _player.hp if is_instance_valid(_player) else 0
	var max_hp := _player.max_hp if is_instance_valid(_player) else int(BAR_HP)
	_draw_bar(origin + Vector2(36.0, 27.0), hp, _player_ghost, max_hp)


func _draw_enemy_block(enemy: Fighter) -> void:
	var origin := Vector2(10.0, 46.0)
	_draw_portrait(enemy, Rect2(origin, Vector2(30.0, 30.0)))
	var enemy_name := "ENEMY"
	var as_enemy := enemy as Enemy
	if as_enemy and as_enemy.stats:
		enemy_name = as_enemy.stats.display_name
	_text(origin + Vector2(36.0, 4.0), enemy_name, 12, NAME_COLOR)
	_draw_bar(origin + Vector2(36.0, 19.0), enemy.hp, _enemy_ghost, enemy.max_hp)


## One bar = 104 HP. Extra health shows as stacked colour layers.
func _draw_bar(pos: Vector2, hp: int, ghost: float, max_hp: int) -> void:
	var frame := Rect2(pos - Vector2(1.0, 1.0), BAR_SIZE + Vector2(2.0, 2.0))
	_canvas.draw_rect(frame, OUTLINE)
	_canvas.draw_rect(Rect2(pos, BAR_SIZE), Color(0.25, 0.05, 0.05))
	# Players always fill exactly one bar; enemies are measured in 104 HP layers.
	var per_layer := float(max_hp) if max_hp <= BAR_HP else BAR_HP
	var layers := int(ceilf(maxf(float(hp), 0.0) / per_layer))
	var remainder := float(hp) - float(maxi(layers - 1, 0)) * per_layer
	if layers >= 2:
		var under := LAYER_COLORS[(layers - 2) % LAYER_COLORS.size()]
		_canvas.draw_rect(Rect2(pos, BAR_SIZE), under)
	var ghost_in_layer := clampf(ghost - float(maxi(layers - 1, 0)) * per_layer, 0.0, per_layer)
	if ghost_in_layer > remainder:
		_canvas.draw_rect(Rect2(pos, Vector2(BAR_SIZE.x * ghost_in_layer / per_layer, BAR_SIZE.y)), Color(0.95, 0.15, 0.1))
	if layers >= 1:
		var top := LAYER_COLORS[(layers - 1) % LAYER_COLORS.size()]
		var width := BAR_SIZE.x * clampf(remainder / per_layer, 0.0, 1.0)
		_canvas.draw_rect(Rect2(pos, Vector2(width, BAR_SIZE.y)), top)
		_canvas.draw_rect(Rect2(pos, Vector2(width, 2.0)), top.lightened(0.45))
	if layers >= 2:
		_text(pos + Vector2(BAR_SIZE.x + 5.0, -4.0), "x%d" % layers, 10, TEXT_COLOR)


func _draw_portrait(fighter: Fighter, rect: Rect2) -> void:
	# Callers pass null rather than a freed reference (typed args reject those).
	_canvas.draw_rect(rect.grow(1.0), OUTLINE)
	_canvas.draw_rect(rect, Color(0.12, 0.1, 0.22))
	if not is_instance_valid(fighter):
		return
	var portrait := _portrait_for(fighter)
	if portrait:
		_canvas.draw_texture_rect(portrait, rect, false)


## Crops the head from the fighter's first idle frame (no portrait art exists).
func _portrait_for(fighter: Fighter) -> Texture2D:
	var key := fighter.sprite.sprite_frames.get_instance_id()
	if _portraits.has(key):
		return _portraits[key]
	var frames := fighter.sprite.sprite_frames
	var anim: StringName = &"idle" if frames.has_animation(&"idle") else StringName(frames.get_animation_names()[0])
	var tex := frames.get_frame_texture(anim, 0)
	var result: Texture2D = null
	if tex:
		var image := tex.get_image()
		if image:
			var used := image.get_used_rect()
			if used.size.x > 0:
				# Head-and-shoulders square from the top of the visible pixels.
				var side := maxi(maxi(used.size.x * 3 / 5, used.size.y * 3 / 10), 8)
				var cx := used.position.x + used.size.x / 2
				var region := Rect2i(cx - side / 2, used.position.y, side, side)
				region = region.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
				var cropped := image.get_region(region)
				if not fighter.sprite_faces_right:
					cropped.flip_x()
				result = ImageTexture.create_from_image(cropped)
	_portraits[key] = result
	return result


func _draw_timer() -> void:
	var width := _canvas.size.x
	var color := Color(1.0, 0.3, 0.2) if _time <= 10 else NAME_COLOR
	_text(Vector2(0.0, 2.0), "%02d" % _time, 30, color, HORIZONTAL_ALIGNMENT_CENTER, width)


func _draw_go() -> void:
	var pos := Vector2(_canvas.size.x - 108.0, 140.0)
	_text(pos, "GO", 30, NAME_COLOR)
	var tip := pos + Vector2(96.0, 22.0)
	var arrow := PackedVector2Array([
		pos + Vector2(50.0, 14.0), pos + Vector2(74.0, 14.0), pos + Vector2(74.0, 4.0),
		tip, pos + Vector2(74.0, 40.0), pos + Vector2(74.0, 30.0), pos + Vector2(50.0, 30.0),
	])
	_canvas.draw_colored_polygon(arrow, NAME_COLOR)
	_canvas.draw_polyline(arrow + PackedVector2Array([arrow[0]]), OUTLINE, 2.0)


func _text(pos: Vector2, text: String, size: int, color: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	var baseline := pos + Vector2(0.0, _font.get_ascent(size))
	_canvas.draw_string_outline(_font, baseline, text, align, width, size, 4, OUTLINE)
	_canvas.draw_string(_font, baseline, text, align, width, size, color)
