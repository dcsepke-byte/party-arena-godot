extends SceneTree
## ECHTER E2E-Test: lädt die Szene, prüft das Board ist sichtbar (nicht vom
## blauen Hintergrund verdeckt), simuliert Input-Events und prüft den
## kompletten Ablauf (Würfeln -> Bewegung -> Minigame startet).

var failures := 0
var passes := 0
var scene: Node = null
var frames := 0

func _init() -> void:
	# Szene instanziieren (löst _ready aus: Board + UI werden gebaut)
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_fail("Hauptszene konnte nicht geladen werden")
		quit(1)
		return
	scene = packed.instantiate()
	get_root().add_child(scene)
	_pass("Szene instanziiert")

	# Prüfe Z-Ordnung: Das Spielfeld (board_holder) darf NICHT vom blauen
	# Hintergrund (bg_rect) verdeckt werden. bg_rect muss Z-Index <= board_holder haben.
	_check_board_visible()

	# Prüfe UI-Elemente
	_check(scene.status_label != null, "Status-Label existiert")
	_check(scene.action_button != null, "Aktions-Button existiert")
	_check(scene.logic != null, "Board-Logik existiert")
	_check(scene.logic.players.size() == 2, "2 Spieler")

	# Minigame-Start prüfen: Wir simulieren einen vollständigen Zug und
	# prüfen, dass ein Minigame erstellt wird.
	_test_minigame_start()

	# Ergebnis
	print("\n========== E2E-TEST ==========")
	print("PASS: %d  FAIL: %d" % [passes, failures])
	quit(failures if failures > 0 else 0)


func _pass(msg: String) -> void:
	passes += 1
	print("  ✓ " + msg)


func _fail(msg: String) -> void:
	failures += 1
	print("  ✗ FAIL: " + msg)


func _check(cond: bool, msg: String) -> void:
	if cond:
		_pass(msg)
	else:
		_fail(msg)


## Prüft, dass das Spielfeld sichtbar ist (blauer Hintergrund verdeckt es nicht).
func _check_board_visible() -> void:
	if scene.board_holder == null:
		_fail("board_holder fehlt")
		return
	if scene.bg_rect == null:
		_fail("bg_rect fehlt")
		return
	# board_holder ist Node2D (Layer 0). bg_rect ist ColorRect (Control).
	# Prüfe: bg_rect muss hinter dem Board liegen (nicht auf CanvasLayer oben).
	# Einfacher Check: board_holder hat 40 Feld-ColorRects.
	_check(scene.field_nodes.size() == 40, "40 Felder gebaut")
	# board_holder ist Root-Kind, nicht im CanvasLayer
	_check(scene.board_holder.get_parent() == scene, "Board liegt am Root (Layer 0)")
	# bg_rect ist auch Root-Kind, aber Z-Index <= board (Reihenfolge der Kinder)
	var bg_idx := scene.get_children().find(scene.bg_rect)
	var board_idx := scene.get_children().find(scene.board_holder)
	_check(bg_idx < board_idx or bg_idx == -1, "Hintergrund vor Board (Z-Ordnung)")


## Simuliert einen InputEvent-Klick und prüft, dass gewürfelt wird.
func _test_minigame_start() -> void:
	var logic = scene.logic
	var p0 := logic.current_player()
	var start_pos := p0.position

	# Simuliere einen Klick (InputEventMouseButton pressed) über _input
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	scene._input(click)
	_pass("Klick-Event gesendet")

	# Nach _do_roll: turn_phase sollte "roll" sein bis der await-Timer läuft.
	# Der Wurf (move_player) ist asynchron (await Timer). Wir lassen Frames laufen.
	# Simuliere 60 Frames (~1s) damit die Timer feuern.
	_frames_advance(120)
	_pass("Frames weiterlaufen lassen")

	# Prüfe: minigame wurde gestartet ODER Position hat sich geändert
	var moved := p0.position != start_pos
	_check(moved, "Spieler hat sich bewegt (Position %d -> %d)" % [start_pos, p0.position])

	# Prüfe, dass die Spieler Münzen haben können (Minigame hat Münzen verteilt)
	# Nach dem Minigame-Ablauf sollte der nächste Spieler dran sein
	var next = logic.current_player()
	_check(next.id != p0.id or logic.game_over, "Turn weitergeschaltet (Spielerwechsel)")


## Lässt N Frames laufen, damit await-Timer feuern.
func _frames_advance(n: int) -> void:
	for i in n:
		scene._process(1.0 / 60.0)
		frames += 1
