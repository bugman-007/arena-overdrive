class_name Hud
extends CanvasLayer
## Heads-up display plus the game-over overlay.

signal restart_requested

var _score: Label
var _health: Label
var _wave: Label
var _combo: Label
var _best: Label
var _banner: Label
var _game_over: Panel
var _final: Label
var _banner_time: float = 0.0


func _ready() -> void:
	_score = _make_label(Vector2(24, 16), 26)
	_health = _make_label(Vector2(24, 50), 22)
	_wave = _make_label(Vector2(1080, 16), 26)
	_combo = _make_label(Vector2(1080, 50), 22)
	_best = _make_label(Vector2(560, 16), 20)
	_banner = _make_label(Vector2(0, 300), 48)
	_banner.size = Vector2(1280, 60)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over = Panel.new()
	_game_over.position = Vector2(390, 200)
	_game_over.size = Vector2(500, 300)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.92)
	style.border_color = Color(0.35, 0.85, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	_game_over.add_theme_stylebox_override("panel", style)
	add_child(_game_over)
	_final = Label.new()
	_final.size = Vector2(500, 300)
	_final.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_final.add_theme_font_size_override("font_size", 26)
	_game_over.add_child(_final)
	_game_over.hide()


func _make_label(pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	add_child(l)
	return l


func set_score(v: int) -> void: _score.text = "SCORE  %d" % v
func set_wave(v: int) -> void: _wave.text = "WAVE  %d" % v
func set_best(v: int) -> void: _best.text = "BEST  %d" % v
func set_combo(m: int) -> void: _combo.text = ("COMBO  x%d" % m) if m > 1 else ""


func set_health(current: int, maximum: int) -> void:
	_health.text = "HP  " + "♥ ".repeat(current) + "· ".repeat(maximum - current)


func show_banner(text: String, seconds: float = 1.5) -> void:
	_banner.text = text
	_banner_time = seconds


func show_game_over(score: int, best: int, new_record: bool, wave: int) -> void:
	var record := "\nNEW HIGH SCORE!" if new_record else ""
	_final.text = "GAME OVER\n\nScore: %d\nWave reached: %d\nBest: %d%s\n\nPress R or Enter to restart" % [score, wave, best, record]
	_game_over.show()


func hide_game_over() -> void:
	_game_over.hide()


func _process(delta: float) -> void:
	if _banner_time > 0.0:
		_banner_time -= delta
		_banner.modulate.a = clampf(_banner_time, 0.0, 1.0)
		if _banner_time <= 0.0:
			_banner.text = ""
	if _game_over.visible and Input.is_action_just_pressed("restart"):
		restart_requested.emit()
