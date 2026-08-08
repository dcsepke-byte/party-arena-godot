class_name SimonGame
extends BaseMinigame
## Memory-Sequenz: Merke dir die leuchtende Farb-Reihenfolge und wiederhole sie.
## 4 Felder, Sequenz wird länger. 30 Sekunden, meiste Runden gewinnt.

const DURATION := 30.0
const COLORS := [Color("#e74c3c"), Color("#f1c40f"), Color("#2ecc71"), Color("#3498db")]

var sequence: Array = []      # Farb-Indizes
var shown := false
var player_input: Array = []
var rounds := 0
var current_step := 0
var active_color := -1
var _show_timer := 0.0
var _input_open := false


func _init() -> void:
	name = "Memory-Sequenz"
	timer_duration = DURATION


func _build() -> void:
	# Starte mit 2 Feldern
	sequence = [randi() % 4, randi() % 4]
	_show_sequence()


func _show_sequence() -> void:
	shown = true
	current_step = 0
	_input_open = false
	_show_timer = 0.0
	active_color = -1
	await get_tree().create_timer(0.5).timeout
	_play_next()


func _play_next() -> void:
	if current_step >= sequence.size():
		shown = false
		player_input = []
		_input_open = true
		return
	active_color = sequence[current_step]
	queue_redraw()
	await get_tree().create_timer(0.5).timeout
	active_color = -1
	queue_redraw()
	current_step += 1
	await get_tree().create_timer(0.2).timeout
	_play_next()


func _process(delta: float) -> void:
	super(delta)


func _input(event: InputEvent) -> void:
	if not _input_open:
		return
	if event is InputEventScreenTouch and event.pressed:
		# Position -> Feld
		var color_idx := _color_at(event.position)
		if color_idx >= 0:
			_on_color_pressed(color_idx)


func _color_at(pos: Vector2) -> int:
	var side := 160.0
	var ox := (get_viewport().size.x - 2 * side) / 2
	var oy := 200.0
	for i in 4:
		var x := ox + (i % 2) * side
		var y := oy + (i / 2) * side
		var r := Rect2(x, y, side, side)
		if r.has_point(pos):
			return i
	return -1


func _on_color_pressed(color_idx: int) -> void:
	if player_input.size() >= sequence.size():
		return
	player_input.append(color_idx)
	# Prüfen
	if player_input[player_input.size() - 1] != sequence[player_input.size() - 1]:
		# Falsch: Runde neu
		player_input = []
		queue_redraw()
		return
	# Runde geschafft
	if player_input.size() == sequence.size():
		rounds += 1
		sequence.append(randi() % 4)
		_show_sequence()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 390, 844), Color("#1a1a2e"))
	var side := 160.0
	var ox := (get_viewport().size.x - 2 * side) / 2
	var oy := 200.0
	for i in 4:
		var x := ox + (i % 2) * side
		var y := oy + (i / 2) * side
		var col := COLORS[i]
		if active_color == i:
			col = col.lightened(0.4)
		draw_rect(Rect2(x, y, side, side), col)
	# Punkte
	draw_string(ThemeDB.fallback_font, Vector2(16, 60), "🧠 Runden: %d" % rounds, HORIZONTAL_ALIGNMENT_LEFT, 300, 28, Color.WHITE)


func get_score(pid: int) -> int:
	return rounds
