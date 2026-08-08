class_name ReactionMinigame
extends Minigame
## Reaktions-Minispiel: Wer am schnellsten auf das grüne Signal reagiert.
## Schnellste Zeit = Platz 1. Headless testbar.

var start_time := 0.0
var reaction_times: Dictionary = {}  # player_id -> ms


func _start() -> void:
	# Zufällige Verzögerung, wann das Signal kommt
	start_time = -1.0


## Wird aufgerufen, wenn das Signal erscheint (von der Szene).
func signal_shown() -> void:
	start_time = Time.get_ticks_msec()


## Spieler tippt. Misst Reaktionszeit.
func react(player_id: int) -> void:
	if player_id in reaction_times:
		return
	if start_time < 0:
		return  # noch kein Signal
	var elapsed := Time.get_ticks_msec() - start_time
	reaction_times[player_id] = elapsed
	finish_player(player_id)


## Für Tests: simulierte Reaktionszeiten direkt setzen.
func test_set_reaction(player_id: int, ms: int) -> void:
	reaction_times[player_id] = ms
	finish_player(player_id)
