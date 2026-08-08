extends SceneTree
## Testet alle 8 Minigames: Instanziierung + Basis-Logik.
## Jedes Spiel muss ohne Fehler bauen und get_score zurückgeben.

var failures := 0
var passes := 0
var players: Array = []

func _init() -> void:
	players = [PlayerData.new(0, "Brix", Color("#ff6a00")), PlayerData.new(1, "Nixie", Color("#00f0ff"))]

	var games := [
		"res://minigames/coin_dash.gd",
		"res://minigames/simon_game.gd",
		"res://minigames/ninja_slash.gd",
		"res://minigames/tower_stack.gd",
		"res://minigames/target_jagd.gd",
		"res://minigames/reaction_game.gd",
		"res://minigames/precision_stop.gd",
		"res://minigames/tap_madness.gd",
	]
	for path in games:
		_test_game(path)

	print("\n========== MINIGAME-TEST ==========")
	print("PASS: %d  FAIL: %d" % [passes, failures])
	quit(failures if failures > 0 else 0)

func _test_game(path: String) -> void:
	var script: GDScript = load(path)
	if script == null:
		_fail(path + " nicht ladbar")
		return
	var g: BaseMinigame = script.new()
	var ok := true
	if g == null:
		_fail(path + " nicht instanziierbar")
		return
	ok = true
	# Basis-Felder prüfen
	if g.name == "" or g.name == "Node2D":
		ok = false
		_fail(path + " hat keinen Namen")
	# setup ohne Fehler (ohne in den Tree zu hängen, nur Konstruktor)
	# Wir hängen in einen Test-Node, damit _ready/aufbau läuft
	var holder := Node2D.new()
	root.add_child(holder)
	holder.add_child(g)
	g.setup(players)
	# score-Funktion testen
	g.get_score(0)
	root.remove_child(holder)
	holder.queue_free()
	# Erfolg
	_pass(path + " OK (" + g.name + ")")

func _pass(msg: String) -> void:
	passes += 1
	print("  ✓ " + msg)

func _fail(msg: String) -> void:
	failures += 1
	print("  ✗ FAIL: " + msg)
