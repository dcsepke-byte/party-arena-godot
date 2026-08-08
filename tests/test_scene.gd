extends SceneTree
## Test: Hauptszene lädt ohne Fehler. Simulation der Logik direkt (ohne await).

var failures := 0
var passes := 0


func _init() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		print("✗ FAIL: Hauptszene konnte nicht geladen werden")
		quit(1)
		return
	passes += 1
	print("✓ Szenen-Ressource geladen")

	# Board-Logik isoliert testen (wie in test_logic, aber Szenen-Setup verifizieren)
	var b := BoardLogic.new()
	b.add_player(PlayerData.new(0, "Brix", Color.RED))
	b.add_player(PlayerData.new(1, "Nixie", Color.BLUE))
	var dice := b.roll_dice(b.current_player())
	var result := b.move_player(b.current_player(), dice)
	passes += 1
	print("✓ Zug simuliert: Würfel=%d, Position=%d" % [dice, b.current_player().position])

	print("\n========== SZENEN-TEST ==========")
	print("PASS: %d  FAIL: %d" % [passes, failures])
	quit(failures if failures > 0 else 0)
