class_name PlayerData
extends RefCounted
## Ein Arenian im Spiel: Position, Sterne, Münzen, Items.

var id: int
var name: String
var color: Color
var position: int = 0
var stars: int = 0
var coins: int = 0
var minigame_wins: int = 0
var items: Array = []  # Array von Item-ID-Strings
var active: bool = true


func _init(p_id: int, p_name: String, p_color: Color) -> void:
	id = p_id
	name = p_name
	color = p_color


func add_coins(amount: int) -> void:
	coins = max(0, coins + amount)


func add_star() -> void:
	stars += 1


func has_item(item_id: String) -> bool:
	return item_id in items


func use_item(item_id: String) -> void:
	items.erase(item_id)
