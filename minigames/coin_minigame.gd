class_name CoinMinigame
extends Minigame
## Münz-Sammel-Minispiel (Geschicklichkeit): 30 Sekunden Münzen einsammeln.
## Meiste Münzen = Platz 1. Headless testbar via add_coin().

const DURATION := 30.0


func _start() -> void:
	_time_left = DURATION


## Münze aufsammeln (von der Szene nach Kollision).
func add_coin(player_id: int) -> void:
	set_score(player_id, get_score(player_id) + 1)
