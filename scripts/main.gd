extends Node2D
## Party Arena — Hauptsteuerung (vertikaler Slice, 2-8 Spieler lokal).

const BoardLogicScript := preload("res://scripts/board_logic.gd")
const PlayerDataScript := preload("res://scripts/player_data.gd")
const ReactionMinigameScript := preload("res://minigames/reaction_minigame.gd")
const CoinMinigameScript := preload("res://minigames/coin_minigame.gd")

const PLAYER_COLORS := [
	Color("#ff6a00"), Color("#00f0ff"), Color("#ffd34e"),
	Color("#ff4d6d"), Color("#2bffb9"), Color("#3a86ff"),
	Color("#7b2ff7"), Color("#ff3cac"),
]

var logic: BoardLogicScript
var active_minigame: Minigame = null

# UI-Referenzen
var status_label: Label
var dice_label: Label
var board_holder: Node2D
var player_markers: Dictionary = {}  # player_id -> Sprite
var field_nodes: Array = []

# Pixel-Art Basis
var bg_rect: ColorRect
var turn_phase := "roll"  # roll | move | minigame | star | done

# Spieler-Figuren als simple Kreise (Pixel-Basis; echte Sprites später von Danny)
var pawn_color: Color


func _ready() -> void:
	logic = BoardLogicScript.new()
	_setup_players()
	_build_ui()
	_build_board_display()
	_update_status()
	# Ersten Spieler aktivieren
	turn_phase = "roll"
	_status("Spielfeld bereit. Spieler 1 würfelt!")


func _setup_players() -> void:
	# Vertikaler Slice: 2 Spieler (später bis 8 wählbar)
	logic.add_player(PlayerDataScript.new(0, "Brix", PLAYER_COLORS[0]))
	logic.add_player(PlayerDataScript.new(1, "Nixie", PLAYER_COLORS[1]))


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# Hintergrund (dunkel, Pixel-Basis)
	bg_rect = ColorRect.new()
	bg_rect.color = Color("#1a1a2e")
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg_rect)

	# Status
	status_label = _make_label(20, Vector2(20, 20), Vector2(900, 40))
	status_label.add_theme_font_size_override("font_size", 24)
	layer.add_child(status_label)

	# Würfel-Anzeige
	dice_label = _make_label(20, Vector2(20, 560), Vector2(900, 40))
	dice_label.add_theme_font_size_override("font_size", 32)
	layer.add_child(dice_label)


func _make_label(p: int, pos: Vector2, size: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.text = ""
	return l


func _build_board_display() -> void:
	# Board als Node2D-Holder (Pixel-Art Grid später von Danny)
	board_holder = Node2D.new()
	add_child(board_holder)

	# Felder als kleine Quadrate auf einem Serpentinen-Pfad (40 Felder)
	var cols := 8
	for i in logic.BOARD_SIZE:
		var col := i % cols
		var row := i / cols
		var x := 100.0 + col * 120.0
		var y := 120.0 + row * 100.0
		# Serpentine: ungerade Zeilen rückwärts
		if row % 2 == 1:
			x = 100.0 + (cols - 1 - col) * 120.0

		var ftype: int = logic.board[i]["type"]
		var rect := ColorRect.new()
		rect.size = Vector2(60, 60)
		rect.position = Vector2(x, y)
		rect.color = _field_color(ftype)
		board_holder.add_child(rect)
		field_nodes.append(rect)

		# Feld-Name als Label
		var name_l := Label.new()
		name_l.text = str(i)
		name_l.position = Vector2(x + 22, y + 22)
		name_l.add_theme_font_size_override("font_size", 20)
		board_holder.add_child(name_l)


func _field_color(ftype: int) -> Color:
	match ftype:
		BoardLogic.FieldType.START: return Color("#ffd54f")
		BoardLogic.FieldType.STAR_SHOP: return Color("#fff176")
		BoardLogic.FieldType.ITEM_SHOP: return Color("#81c784")
		BoardLogic.FieldType.EVENT: return Color("#ff8a65")
		BoardLogic.FieldType.LUCKY: return Color("#ba68c8")
		BoardLogic.FieldType.COIN_BONUS: return Color("#4dd0e1")
		BoardLogic.FieldType.JUNCTION: return Color("#ce93d8")
		_: return Color("#90caf9")


func _update_status() -> void:
	var p := logic.current_player()
	if p == null:
		return
	status_label.text = "Runde %d/%d · %s · ⭐%d · 🪙%d" % [
		logic.round_number, logic.MAX_ROUNDS, p.name, p.stars, p.coins
	]


func _status(msg: String) -> void:
	dice_label.text = msg


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_handle_space()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()


func _handle_space() -> void:
	match turn_phase:
		"roll":
			_do_roll()
		"minigame":
			pass  # Minigame läuft autonom
		"star":
			_try_buy_star()
		"done":
			_show_winner()


func _do_roll() -> void:
	var p := logic.current_player()
	var dice := logic.roll_dice(p)
	_status("%s würfelt: %d" % [p.name, dice])
	# Mini-Animation: Feld-Marker bewegen
	await get_tree().create_timer(0.5).timeout
	_animate_move(p, dice)
	turn_phase = "minigame"


func _animate_move(p, dice) -> void:
	# Simpel: Zielposition anzeigen, Feld-Effekt anwenden
	var result := logic.move_player(p, dice)
	_update_status()
	_move_pawn(p)
	_status("%s steht auf Feld %d — %s" % [p.name, p.position, _effect_text(result)])
	await get_tree().create_timer(0.8).timeout
	# Nach Bewegung: Minispiel (nur wenn nicht auf Shop, das Stern wählt)
	_start_minigame()


func _effect_text(result: Dictionary) -> String:
	match result["type"]:
		BoardLogic.FieldType.STAR_SHOP:
			if result.can_buy_star:
				return "Sternen-Shop! (Leertaste zum Kauf)"
			return "Sternen-Shop (brauchst %d Münzen)" % logic.STAR_COST
		BoardLogic.FieldType.COIN_BONUS:
			return "+%d Münzen" % result.coins
		BoardLogic.FieldType.LUCKY, BoardLogic.FieldType.EVENT:
			return result.event
		BoardLogic.FieldType.ITEM_SHOP:
			return "Item-Shop"
		BoardLogic.FieldType.JUNCTION:
			return "Abzweigung"
		_: return "Mini-Spiel!"


func _move_pawn(p) -> void:
	# Pawn-Marker auf das Feld setzen (simple Positionslogik)
	pass


func _start_minigame() -> void:
	var current := logic.current_player()
	# Wähle zufällig Geschick (Münzen) oder Reaktion
	if randi_range(0, 1) == 0:
		active_minigame = ReactionMinigameScript.new()
		active_minigame.start_game(logic.players)
		_status("REAKTIONS-SPIEL: Warte auf das Signal, dann schnell tippen!")
		# Signal nach zufälliger Zeit
		_trigger_reaction_signal(active_minigame)
	else:
		active_minigame = CoinMinigameScript.new()
		active_minigame.start_game(logic.players)
		_status("MÜNZ-SPIEL: Sammle Münzen! (Space für Spieler %s)" % current.name)
		# Auto-Sim: Jeder Spieler sammelt zufällige Münzen über die Zeit
		_simulate_coin_minigame(active_minigame)


func _trigger_reaction_signal(mg: Minigame) -> void:
	await get_tree().create_timer(randf_range(1.0, 2.5)).timeout
	if mg is ReactionMinigame:
		mg.signal_shown()
		_status("JETZT TIPPEN!")


func _simulate_coin_minigame(mg: Minigame) -> void:
	# Simulation für vertikalen Slice: 30 Sekunden Münzen sammeln
	var t := 0.0
	while t < 30.0 and active_minigame == mg:
		for p in logic.players:
			if randf() < 0.3:
				mg.add_coin(p.id)
		t += 0.5
		await get_tree().create_timer(0.5).timeout
	mg.tick(100.0)  # Zeit ablaufen lassen -> finish


func _try_buy_star() -> void:
	var p := logic.current_player()
	var result := logic.buy_star(p)
	_status(result.message)
	_update_status()
	turn_phase = "done"


func _show_winner() -> void:
	logic.award_bonus_stars()
	var w := logic.winner()
	_status("🏆 %s gewinnt mit %d Sternen!" % [w.name, w.stars])
	turn_phase = "done"


## Von Reaktion-Minigame: Spieler-Space-Tap als Reaktion
func _react(player_id: int) -> void:
	if active_minigame is ReactionMinigame:
		(active_minigame as ReactionMinigame).react(player_id)
