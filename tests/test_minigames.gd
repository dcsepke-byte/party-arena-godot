extends SceneTree
## Headless-Test der Minigame-Logik (Reaktion + Münzen).

var failures := 0
var passes := 0


func _init() -> void:
	_test_reaction()
	_test_coin()
	_test_placements()

	print("\n========== MINIGAME-TEST ==========")
	print("PASS: %d  FAIL: %d" % [passes, failures])
	quit(failures if failures > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if cond:
		passes += 1
	else:
		failures += 1
		print("  ✗ FAIL: " + msg)


func _test_reaction() -> void:
	var p1 := PlayerData.new(0, "Brix", Color.RED)
	var p2 := PlayerData.new(1, "Nixie", Color.BLUE)
	var mg := ReactionMinigame.new()
	mg.start_game([p1, p2])
	mg.signal_shown()
	mg.test_set_reaction(p1.id, 120)
	mg.test_set_reaction(p2.id, 250)
	_check(mg.reaction_times.size() == 2, "Beide Spieler haben reagiert")
	_check(mg.reaction_times[p1.id] < mg.reaction_times[p2.id], "Brix ist schneller")


func _test_coin() -> void:
	var p1 := PlayerData.new(0, "Brix", Color.RED)
	var p2 := PlayerData.new(1, "Nixie", Color.BLUE)
	var mg := CoinMinigame.new()
	mg.start_game([p1, p2])
	mg.add_coin(p1.id)
	mg.add_coin(p1.id)
	mg.add_coin(p2.id)
	_check(mg.get_score(p1.id) == 2, "Brix hat 2 Münzen")
	_check(mg.get_score(p2.id) == 1, "Nixie hat 1 Münze")


func _test_placements() -> void:
	var p1 := PlayerData.new(0, "Brix", Color.RED)
	var p2 := PlayerData.new(1, "Nixie", Color.BLUE)
	var mg := CoinMinigame.new()
	mg.start_game([p1, p2])
	mg.add_coin(p1.id)
	mg.add_coin(p1.id)
	mg.finish_player(p1.id)
	mg.finish_player(p2.id)
	_check(mg._finished.size() == 2, "Beide fertig")
