extends SceneTree
## Headless-Test der Board-Logik (kein Rendering nötig).
## Läuft via: godot --headless --script tests/test_logic.gd

var failures := 0
var passes := 0


func _init() -> void:
	_test_board_size()
	_test_players()
	_test_move_and_fields()
	_test_star_buy()
	_test_bonus_stars()
	_test_catchup_boost()

	print("\n========== TEST-ERGEBNIS ==========")
	print("PASS: %d  FAIL: %d" % [passes, failures])
	if failures == 0:
		print("ALLE TESTS BESTANDEN ✓")
	else:
		print("TESTS FEHLGESCHLAGEN ✗")
	quit(failures if failures > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if cond:
		passes += 1
	else:
		failures += 1
		print("  ✗ FAIL: " + msg)


func _test_board_size() -> void:
	var b := BoardLogic.new()
	_check(b.board.size() == 40, "Board hat 40 Felder (hat %d)" % b.board.size())
	_check(b.board[0]["type"] == BoardLogic.FieldType.START, "Feld 0 ist Start")
	_check(b.STAR_SHOP_SLOTS.size() == 2, "2 Sternen-Shops")


func _test_players() -> void:
	var b := BoardLogic.new()
	var p1 := PlayerData.new(0, "Brix", Color.RED)
	var p2 := PlayerData.new(1, "Nixie", Color.BLUE)
	b.add_player(p1)
	b.add_player(p2)
	_check(b.players.size() == 2, "2 Spieler hinzugefügt")
	_check(b.current_player().name == "Brix", "Erster Spieler ist Brix")
	p1.add_coins(50)
	_check(p1.coins == 50, "Münzen addieren (50)")


func _test_move_and_fields() -> void:
	var b := BoardLogic.new()
	var p1 := PlayerData.new(0, "Brix", Color.RED)
	b.add_player(p1)
	# Auf Münz-Bonus-Feld (3) setzen
	p1.position = 3
	var r := b.resolve_field(p1, 3)
	_check(r["type"] == BoardLogic.FieldType.COIN_BONUS, "Feld 3 ist Münz-Bonus")
	_check(p1.coins > 0, "Münz-Bonus gibt Münzen")
	# Auf Glück-Feld setzen
	p1.coins = 0
	p1.position = 9
	var r2 := b.resolve_field(p1, 9)
	_check(r2["type"] == BoardLogic.FieldType.LUCKY, "Feld 9 ist Glück/Pech")


func _test_star_buy() -> void:
	var b := BoardLogic.new()
	var p1 := PlayerData.new(0, "Brix", Color.RED)
	b.add_player(p1)
	# Nicht genug Münzen
	p1.position = b.star_position
	var r := b.buy_star(p1)
	_check(not r.ok, "Kauf ohne Münzen schlägt fehl")
	# Genug Münzen
	p1.add_coins(25)
	var r2 := b.buy_star(p1)
	_check(r2.ok, "Kauf mit 25 Münzen klappt")
	_check(p1.stars == 1, "Stern hinzugefügt")
	_check(p1.coins == 5, "20 Münzen abgezogen")
	_check(b.star_position != 5, "Stern wandert nach Kauf")


func _test_bonus_stars() -> void:
	var b := BoardLogic.new()
	var p1 := PlayerData.new(0, "Brix", Color.RED)
	var p2 := PlayerData.new(1, "Nixie", Color.BLUE)
	b.add_player(p1)
	b.add_player(p2)
	p1.minigame_wins = 3
	p2.coins = 30
	var awards := b.award_bonus_stars()
	_check(awards.most_wins == p1, "Bonus: meiste Siege")
	_check(awards.most_coins == p2, "Bonus: meiste Münzen")
	_check(p1.stars == 1, "p1 bekommt Bonus-Stern")


func _test_catchup_boost() -> void:
	var b := BoardLogic.new()
	var p1 := PlayerData.new(0, "Brix", Color.RED)
	b.add_player(p1)
	b.round_number = 9  # letzte Runden
	p1.stars = 0
	var dice := b.roll_dice(p1)
	_check(dice >= 2, "Catch-up-Boost erhöht Würfel (%d)" % dice)
