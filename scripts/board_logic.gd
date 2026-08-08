class_name BoardLogic
extends RefCounted
## Reine Spiellogik für Party Arena (headless testbar, keine Nodes).
## 40-Felder-Pfad, 2-8 Spieler, Sterne/Münzen/Items, Catch-up.

# Feld-Typen
enum FieldType {
	START,
	STAR_SHOP,
	ITEM_SHOP,
	EVENT,
	LUCKY,
	COIN_BONUS,
	MINIGAME,
	JUNCTION,
}

# Spiel-Konstanten (aus dem geschärften Spielkonzept)
const BOARD_SIZE := 40
const STAR_COST := 20
const STAR_SHOP_SLOTS := [5, 22]        # Stern wandert zwischen diesen
const ITEM_SHOP_SLOTS := [13, 31]
const EVENT_SLOTS := [7, 12, 18, 26, 33, 37]
const LUCKY_SLOTS := [9, 16, 28]
const COIN_BONUS_SLOTS := [3, 11, 20, 35]
const JUNCTION_SLOTS := [14, 30]
const MAX_ROUNDS := 10

var board := []          # Array von {type, name}
var players: Array = []  # Array von PlayerData
var current_player_index := 0
var round_number := 1
var star_position := 5    # aktuelle Stern-Position
var game_over := false


func _init() -> void:
	_build_board()


func _build_board() -> void:
	board.clear()
	for i in BOARD_SIZE:
		var ftype := FieldType.MINIGAME
		if i == 0:
			ftype = FieldType.START
		elif i in STAR_SHOP_SLOTS:
			ftype = FieldType.STAR_SHOP
		elif i in ITEM_SHOP_SLOTS:
			ftype = FieldType.ITEM_SHOP
		elif i in EVENT_SLOTS:
			ftype = FieldType.EVENT
		elif i in LUCKY_SLOTS:
			ftype = FieldType.LUCKY
		elif i in COIN_BONUS_SLOTS:
			ftype = FieldType.COIN_BONUS
		elif i in JUNCTION_SLOTS:
			ftype = FieldType.JUNCTION
		board.append({"type": ftype, "name": _field_name(ftype)})


func _field_name(t: int) -> String:
	match t:
		FieldType.START: return "Start"
		FieldType.STAR_SHOP: return "Sternen-Shop"
		FieldType.ITEM_SHOP: return "Item-Shop"
		FieldType.EVENT: return "Ereignis"
		FieldType.LUCKY: return "Glück oder Pech"
		FieldType.COIN_BONUS: return "Münz-Bonus"
		FieldType.JUNCTION: return "Abzweigung"
		_: return "Mini-Spiel"


func add_player(p: PlayerData) -> void:
	players.append(p)


## Würfeln: Standard 1-6, mit Catch-up-Boost für hintenliegende Spieler.
func roll_dice(p: PlayerData) -> int:
	var base := randi_range(1, 6)
	# Catch-up: Spieler in den letzten 2 Runden mit <= 1 Stern bekommen +1..+2
	if round_number >= MAX_ROUNDS - 2 and p.stars <= 1:
		base += randi_range(1, 2)
	return base


## Bewegen und Feld-Effekt auslösen. Gibt ein Ergebnis-Dict zurück.
func move_player(p: PlayerData, steps: int) -> Dictionary:
	p.position = (p.position + steps) % BOARD_SIZE
	return resolve_field(p, p.position)


## Feld-Effekt eines Felds. Gibt Dictionary mit events/coins zurück.
func resolve_field(p: PlayerData, pos: int) -> Dictionary:
	var ftype: int = board[pos]["type"]
	var result := {"type": ftype, "coins": 0, "stars": 0, "event": "", "can_buy_star": false}

	match ftype:
		FieldType.STAR_SHOP:
			result.can_buy_star = (p.coins >= STAR_COST)
		FieldType.COIN_BONUS:
			var bonus := randi_range(5, 10)
			p.add_coins(bonus)
			result.coins = bonus
		FieldType.LUCKY:
			var good := randi_range(0, 1) == 0
			if good:
				var g := randi_range(3, 8)
				p.add_coins(g)
				result.coins = g
				result.event = "Glück! +%d Münzen" % g
			else:
				var l := randi_range(2, 6)
				p.add_coins(-l)
				result.coins = -l
				result.event = "Pech! -%d Münzen" % l
		FieldType.EVENT:
			result.event = _random_event(p)
		_:
			pass
	return result


## Stern kaufen (wenn genug Münzen & auf Stern-Feld). Stern wandert.
func buy_star(p: PlayerData) -> Dictionary:
	var result := {"ok": false, "message": ""}
	if p.position != star_position:
		result.message = "Du stehst nicht auf dem Sternen-Feld."
		return result
	if p.coins < STAR_COST:
		result.message = "Nicht genug Münzen (%d nötig)." % STAR_COST
		return result
	p.add_coins(-STAR_COST)
	p.add_star()
	result.ok = true
	# Stern wandert zum anderen Shop-Feld
	star_position = STAR_SHOP_SLOTS[1] if star_position == STAR_SHOP_SLOTS[0] else STAR_SHOP_SLOTS[0]
	result.message = "Stern gekauft! Der Stern wandert."
	return result


## Zufalls-Ereignis (Catch-up-freundlich, hilft Verlierern).
func _random_event(p: PlayerData) -> String:
	var r := randi_range(0, 4)
	match r:
		0:
			var amt := randi_range(5, 12)
			p.add_coins(amt)
			return "Münzregen! +%d Münzen" % amt
		1:
			var amt2 := randi_range(3, 8)
			p.add_coins(-amt2)
			return "Abzocke! -%d Münzen" % amt2
		2:
			# Vorrücken (Catch-up: mehr wenn hinten)
			var steps := 1
			if _is_behind(p):
				steps = 3
			p.position = (p.position + steps) % BOARD_SIZE
			return "Windgeist! +%d Felder" % steps
		3:
			# Münzen von Mitspieler stehlen
			var target := _richest_other(p)
			if target:
				var steal := 5
				target.add_coins(-steal)
				p.add_coins(steal)
				return "Dieb-Handschuh! -%d Münzen von %s" % [steal, target.name]
		_:
			var amt3 := randi_range(2, 5)
			p.add_coins(amt3)
			return "Kleiner Bonus! +%d Münzen" % amt3
	return ""


func _is_behind(p: PlayerData) -> bool:
	for o in players:
		if o.id != p.id and o.position > p.position:
			return true
	return false


func _richest_other(p: PlayerData) -> PlayerData:
	var best: PlayerData = null
	for o in players:
		if o.id == p.id:
			continue
		if best == null or o.coins > best.coins:
			best = o
	return best


## Nach dem Würfeln: aktiven Spieler weiterreichen, Runde prüfen.
func next_turn() -> void:
	current_player_index = (current_player_index + 1) % players.size()
	if current_player_index == 0:
		round_number += 1
		if round_number > MAX_ROUNDS:
			game_over = true


func current_player() -> PlayerData:
	return players[current_player_index] if players.size() > 0 else null


## Bonus-Sterne am Ende (semi-opak).
func award_bonus_stars() -> Dictionary:
	var awards := {"most_wins": null, "most_coins": null}
	if players.is_empty():
		return awards
	var max_wins := -1
	for p in players:
		if p.minigame_wins > max_wins:
			max_wins = p.minigame_wins
			awards.most_wins = p
	if max_wins > 0 and awards.most_wins:
		awards.most_wins.add_star()
	var max_coins := -1
	for p in players:
		if p.coins > max_coins:
			max_coins = p.coins
			awards.most_coins = p
	if max_coins > 0 and awards.most_coins and awards.most_coins != awards.most_wins:
		awards.most_coins.add_star()
	return awards


func winner() -> PlayerData:
	var best: PlayerData = null
	for p in players:
		if best == null or p.stars > best.stars or (p.stars == best.stars and p.coins > best.coins):
			best = p
	return best
