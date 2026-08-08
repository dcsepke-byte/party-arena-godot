class_name Minigame
extends RefCounted
## Basis-API für Minispiele. Jedes Spiel erbt davon und implementiert
## _start / _process_step. Gibt Platzierungen 1..N zurück → Münzen.

var players: Array = []        # PlayerData
var _scores: Dictionary = {}   # player_id -> score
var _finished: Array = []      # player_ids in Reihenfolge
var _time_left := 30.0
var _active := false

signal minigame_finished(scores: Dictionary, placements: Array)


func start_game(p_list: Array) -> void:
	players = p_list
	_scores = {}
	_finished = []
	for p in players:
		_scores[p.id] = 0
	_active = true
	_start()


## Wird von der Szene jede Frame aufgerufen.
func tick(delta: float) -> void:
	if not _active:
		return
	_time_left -= delta
	_process_step(delta)
	if _time_left <= 0:
		_finish_all()


func _start() -> void:
	pass


func _process_step(delta: float) -> void:
	pass


func set_score(player_id: int, score: int) -> void:
	_scores[player_id] = score


func get_score(player_id: int) -> int:
	return _scores.get(player_id, 0)


## Spieler ist fertig (für Rennen: Platzierung nach Reihenfolge).
func finish_player(player_id: int) -> void:
	if player_id not in _finished:
		_finished.append(player_id)


func _finish_all() -> void:
	_active = false
	# Restliche Spieler nach Score sortiert anhängen
	var remaining: Array = []
	for p in players:
		if p.id not in _finished:
			remaining.append(p)
	remaining.sort_custom(func(a, b): return _scores.get(a.id, 0) > _scores.get(b.id, 0))
	var placements: Array = _finished
	for p in remaining:
		placements.append(p.id)
	minigame_finished.emit(_scores, placements)
