extends Node
## MinigameRunner: lädt ein zufälliges Minispiel, zeigt es an, wertet aus.
## Wird vom Board-Fluss (main.gd) aufgerufen.

signal minigame_done(rewards: Dictionary)  # player_id -> Münzen

const GAMES := [
	"res://minigames/coin_dash.gd",
	"res://minigames/simon_game.gd",
	"res://minigames/ninja_slash.gd",
	"res://minigames/tower_stack.gd",
	"res://minigames/target_jagd.gd",
	"res://minigames/reaction_game.gd",
	"res://minigames/precision_stop.gd",
	"res://minigames/tap_madness.gd",
]

var current: BaseMinigame = null
var players: Array = []
var overlay: CanvasLayer
var _hud: Control
var _timer_label: Label
var _name_label: Label
var _score_labels: Dictionary = {}  # player_id -> Label


func setup(p_list: Array, ui_root: CanvasLayer) -> void:
	players = p_list
	overlay = ui_root
	# HUD bauen
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(_hud)

	_name_label = _mk_label(30, Vector2(16, 16), Vector2(1000, 50))
	_hud.add_child(_name_label)

	_timer_label = _mk_label(44, Vector2(16, 70), Vector2(1000, 60))
	_timer_label.text = ""
	_hud.add_child(_timer_label)

	# Score-Labels pro Spieler
	var y := 110
	for p in players:
		var l := _mk_label(24, Vector2(16, y), Vector2(600, 36))
		l.text = "%s: 0" % p.name
		l.add_theme_color_override("font_color", p.color)
		_score_labels[p.id] = l
		_hud.add_child(l)
		y += 40


func _mk_label(size: int, pos: Vector2, sz: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = sz
	l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Startet ein zufälliges Minispiel.
func start_random() -> void:
	var script: GDScript = load(GAMES[randi() % GAMES.size()])
	current = script.new()
	current.setup(players)
	_name_label.text = current.name
	_hud.add_child(current)
	current.finished.connect(_on_game_finished)


## Startet ein bestimmtes Minispiel (für Tests).
func start_named(idx: int) -> void:
	var script: GDScript = load(GAMES[idx])
	current = script.new()
	current.setup(players)
	_name_label.text = current.name
	_hud.add_child(current)
	current.finished.connect(_on_game_finished)


func _process(delta: float) -> void:
	if current:
		_update_hud()


func _update_hud() -> void:
	if _timer_label and current and current.timer_duration > 0.0:
		_timer_label.text = "⏱ %d" % int(ceil(current._time_left))
	for pid in _score_labels:
		_score_labels[pid].text = "%s: %d" % [_player_name(pid), current.get_score(pid)]


func _player_name(pid: int) -> String:
	for p in players:
		if p.id == pid:
			return p.name
	return "?"


func _on_game_finished(placements: Array) -> void:
	# Münzen vergeben (1.=10, 2.=6, 3.=3, 4.=1)
	var rewards := [10, 6, 3, 1]
	var reward_map := {}
	for i in placements.size():
		var p: PlayerData = placements[i]
		var r: int = rewards[i] if i < rewards.size() else 0
		p.add_coins(r)
		if i == 0:
			p.minigame_wins += 1
		reward_map[p.id] = r
	# Kurz Ergebnis anzeigen
	_timer_label.text = "🏆 %s gewinnt!" % placements[0].name
	await get_tree().create_timer(1.0).timeout
	if current:
		current.queue_free()
		current = null
	minigame_done.emit(reward_map)
