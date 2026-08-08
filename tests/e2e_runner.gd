extends Node
## E2E-Runner: läuft im echten Main-Loop, lädt die Szene, simuliert Klicks,
## lässt Engine-Timer feuern und prüft den Ablauf. Aufgerufen vom Test.

var e2e_tree: SceneTree
var scene: Node = null
var click_sent := false
var elapsed := 0.0
var start_pos := 0
var failures := 0
var passes := 0
var _started := false


func _ready() -> void:
	e2e_tree = get_meta("e2e_tree")
	# Szene laden
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_fail("Hauptszene nicht ladbar")
		e2e_tree.finish(1)
		return
	scene = packed.instantiate()
	get_tree().root.add_child(scene)
	start_pos = scene.logic.current_player().position
	print("[E2E] Szene geladen. Felder:", scene.field_nodes.size())
	print("[E2E] board_holder Parent:", scene.board_holder.get_parent().name)
	print("[E2E] bg_rect Parent:", scene.bg_rect.get_parent().name)
	_started = true


func _process(delta: float) -> void:
	if not _started:
		return
	elapsed += delta

	if not click_sent and elapsed >= 1.0:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		scene._input(click)
		click_sent = true
		print("[E2E] Klick gesendet. turn_phase:", scene.turn_phase)

	if elapsed >= 6.0:
		_finish_checks()
		e2e_tree.finish(failures)


func _finish_checks() -> void:
	var logic = scene.logic
	var p0: PlayerData = logic.players[0]
	var p1: PlayerData = logic.players[1]
	var any_move: bool = p0.position != 0 or p1.position != 0 or p0.coins > 0 or p1.coins > 0

	_check(logic != null, "Board-Logik existiert")
	_check(scene.field_nodes.size() == 40, "40 Felder sichtbar")
	_check(scene.status_label != null and scene.action_button != null, "UI-Elemente existieren")
	_check(any_move, "Klick hat Spiel fortbewegt (Münzen/Position)")
	var advanced: bool = logic.round_number > 1 or logic.players[0].position != 0 or logic.players[1].position != 0
	_check(advanced, "Spielablauf fortgeschritten (Minigame durchlaufen)")


func _check(cond: bool, msg: String) -> void:
	if cond:
		passes += 1
		print("  ✓ " + msg)
	else:
		failures += 1
		print("  ✗ FAIL: " + msg)


func _fail(msg: String) -> void:
	failures += 1
	print("  ✗ FAIL: " + msg)
