class_name ReactionGame
extends BaseMinigame
## Reaktion: Tippe so schnell wie möglich, sobald der Bildschirm grün wird.
## Jede Runde: zufällige Wartezeit, dann grün. Schnellste Reaktionszeit gewinnt.

const ROUNDS := 3
var rounds_done := 0
var waiting := false
var green := false
var signal_time := 0.0
var best_time := 9999.0  # ms


func _init() -> void:
	name = "Reaktion"


func _build() -> void:
	_next_round()


func _next_round() -> void:
	waiting = true
	green = false
	queue_redraw()
	var wait: float = randf_range(1.0, 3.0)
	await get_tree().create_timer(wait).timeout
	if not _running:
		return
	green = true
	waiting = false
	signal_time = Time.get_ticks_msec()
	queue_redraw()


func on_tap(player: PlayerData) -> void:
	if green:
		var elapsed: int = Time.get_ticks_msec() - signal_time
		if elapsed < best_time:
			best_time = elapsed
		rounds_done += 1
		green = false
		queue_redraw()
		if rounds_done >= ROUNDS:
			_running = false
			var sorted := players.duplicate()
			sorted.sort_custom(func(a, b): return true)
			finished.emit([players[0]])
		else:
			_next_round()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 390, 844), Color("#1a1a2e"))
	var col := Color("#e74c3c")
	var msg := "Warte auf Grün…"
	if green:
		col = Color("#2ecc71")
		msg = "JETZT TIPPEN!"
	# Großes Signal-Feld
	draw_rect(Rect2(20, 200, 350, 400), col)
	draw_string(ThemeDB.fallback_font, Vector2(30, 260), msg, HORIZONTAL_ALIGNMENT_LEFT, 300, 40, Color.WHITE)
	if rounds_done > 0:
		draw_string(ThemeDB.fallback_font, Vector2(16, 60), "⚡ %d ms (beste)" % int(best_time), HORIZONTAL_ALIGNMENT_LEFT, 300, 28, Color.WHITE)


func get_score(pid: int) -> int:
	# Weniger ist besser — wir nutzen negatives best_time als Score
	return -int(best_time)
