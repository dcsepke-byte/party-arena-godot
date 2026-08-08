class_name BaseMinigame
extends Node2D
## Basis für alle Minispiele. Jedes Spiel erbt hiervon, baut seine Szene in
## _build() und meldet sich mit finish(placements) fertig.
## placements = Array von PlayerData, sortiert 1. Platz zuerst.

signal finished(placements: Array)

var players: Array = []       # PlayerData
var timer_duration := 0.0     # 0 = kein Timer
var _time_left := 0.0
var _running := false


func setup(p_list: Array) -> void:
	players = p_list
	_time_left = timer_duration
	_build()
	_running = true


## Baut die Minigame-Szene. Muss in jedem Spiel überschrieben werden.
func _build() -> void:
	pass


## Wird jede Frame aufgerufen (für Bewegung, Timer).
func _tick(delta: float) -> void:
	if _running and timer_duration > 0.0:
		_time_left -= delta
		if _time_left <= 0.0:
			_time_left = 0.0
			_finish_by_time()


## Zeit abgelaufen → Platzierungen nach aktuellen Scores.
func _finish_by_time() -> void:
	var sorted := players.duplicate()
	sorted.sort_custom(func(a, b): return get_score(a.id) > get_score(b.id))
	_running = false
	finished.emit(sorted)


func get_score(pid: int) -> int:
	return 0


## Spieler tippt/agiert (für Touch). Wird von Unterklassen überschrieben.
func on_tap(player: PlayerData) -> void:
	pass


## Leitet Touch/Maus-Events an on_tap weiter (Touch-Steuerung).
func _input(event: InputEvent) -> void:
	if not _running:
		return
	if event is InputEventScreenTouch and event.pressed:
		on_tap(_current_player())
	elif event is InputEventMouseButton and event.pressed:
		on_tap(_current_player())


func _current_player() -> PlayerData:
	return players[0] if players.size() > 0 else null


func _process(delta: float) -> void:
	_tick(delta)
