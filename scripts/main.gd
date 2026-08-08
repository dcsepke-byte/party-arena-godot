extends Node2D
## Party Arena — Hauptsteuerung (vertikaler Slice, 2-8 Spieler lokal).

const BoardLogicScript := preload("res://scripts/board_logic.gd")
const PlayerDataScript := preload("res://scripts/player_data.gd")
const MinigameRunnerScript := preload("res://scripts/minigame_runner.gd")

const PLAYER_COLORS := [
	Color("#ff6a00"), Color("#00f0ff"), Color("#ffd34e"),
	Color("#ff4d6d"), Color("#2bffb9"), Color("#3a86ff"),
	Color("#7b2ff7"), Color("#ff3cac"),
]

var logic: BoardLogicScript
var active_minigame: BaseMinigame = null
var minigame_runner: Node = null
var _mg_layer: CanvasLayer = null

# UI-Referenzen
var status_label: Label
var dice_label: Label
var action_button: Button
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
	# Minigame-Runner auf eigenem Layer (über dem Board)
	_mg_layer = CanvasLayer.new()
	_mg_layer.layer = 10
	add_child(_mg_layer)
	minigame_runner = MinigameRunnerScript.new()
	minigame_runner.setup(logic.players, _mg_layer)
	minigame_runner.minigame_done.connect(_on_minigame_done)
	_mg_layer.add_child(minigame_runner)
	# Minigame-Layer initial ausblenden
	_mg_layer.visible = false
	_update_status()
	# Ersten Spieler aktivieren
	turn_phase = "roll"
	_status("Spielfeld bereit. Spieler 1 würfelt!")
	# Auto-Test-Modus (headless): `godot --headless -- --autotest`
	if OS.get_cmdline_user_args().has("--autotest"):
		print("[AUTOTEST] Starte Auto-Wurf")
		_do_roll()


func _setup_players() -> void:
	# Vertikaler Slice: 2 Spieler (später bis 8 wählbar)
	logic.add_player(PlayerDataScript.new(0, "Brix", PLAYER_COLORS[0]))
	logic.add_player(PlayerDataScript.new(1, "Nixie", PLAYER_COLORS[1]))


func _build_ui() -> void:
	# Hintergrund ZUERST als Root-Kind (Layer 0) — damit er HINTER dem
	# Spielfeld liegt (board_holder wird in _build_board_display danach hinzugefügt).
	# WICHTIG: NICHT aufs CanvasLayer legen, sonst verdeckt der Hintergrund das Board.
	bg_rect = ColorRect.new()
	bg_rect.color = Color("#1a1a2e")
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # nie Klicks blockieren
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.size = Vector2(1920, 1080)
	bg_rect.position = Vector2(-1000, -600)
	add_child(bg_rect)

	var layer := CanvasLayer.new()
	add_child(layer)

	# Status (oben)
	status_label = _make_label(20, Vector2(16, 16), Vector2(1200, 60))
	status_label.add_theme_font_size_override("font_size", 30)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layer.add_child(status_label)

	# Würfel-Anzeige (mittig, groß)
	dice_label = _make_label(20, Vector2(16, 0), Vector2(1200, 120))
	dice_label.add_theme_font_size_override("font_size", 34)
	dice_label.anchor_top = 1.0
	dice_label.anchor_bottom = 1.0
	dice_label.offset_top = -180.0
	dice_label.offset_bottom = -60.0
	layer.add_child(dice_label)

	# Großer Touch-Button (unten, groß & gut tappbar)
	action_button = Button.new()
	action_button.text = "🎲 WÜRFELN"
	action_button.add_theme_font_size_override("font_size", 44)
	action_button.anchor_left = 0.0
	action_button.anchor_right = 1.0
	action_button.anchor_top = 1.0
	action_button.anchor_bottom = 1.0
	action_button.offset_left = 16.0
	action_button.offset_right = -16.0
	action_button.offset_top = -100.0
	action_button.offset_bottom = -16.0
	# Button ist rein visuell. MOUSE_FILTER_IGNORE, damit Klicks/Taps durchs
	# GUI zu _input() durchkommen (ein STOP-Button würde alle Taps schlucken).
	action_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(action_button)


func _make_label(p: int, pos: Vector2, size: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.text = ""
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	# Spielfiguren als farbige Kreise auf Feld 0 (Start)
	player_markers.clear()
	for p in logic.players:
		var pawn := _make_pawn(p)
		player_markers[p.id] = pawn
		board_holder.add_child(pawn)
		_position_pawn(p, 0)


func _make_pawn(p: PlayerData) -> ColorRect:
	var rect := ColorRect.new()
	rect.size = Vector2(40, 40)
	rect.color = p.color
	rect.position = Vector2(0, 0)
	return rect


func _position_pawn(p: PlayerData, field_idx: int) -> void:
	var pawn: ColorRect = player_markers.get(p.id)
	if pawn == null:
		return
	# Feld-Zentrum = Feld-Position + 10 (Feld 60px, Pawn 40px)
	var idx := field_idx % logic.BOARD_SIZE
	var cols := 8
	var col := idx % cols
	var row := idx / cols
	var x := 100.0 + col * 120.0
	var y := 120.0 + row * 100.0
	if row % 2 == 1:
		x = 100.0 + (cols - 1 - col) * 120.0
	pawn.position = Vector2(x + 10, y + 10)


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


## Fängt ALLE Input-Events (inkl. Touch), bevor sie konsumiert werden.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_handle_space()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
	# Touch auf Mobile-Web: Tap irgendwo würfelt
	elif event is InputEventScreenTouch and event.pressed:
		_handle_space()
	# Klick (Desktop / Test)
	elif event is InputEventMouseButton and event.pressed:
		_handle_space()


func _set_button_text(txt: String) -> void:
	if action_button:
		action_button.text = txt


func _handle_space() -> void:
	match turn_phase:
		"roll":
			_do_roll()
		"minigame":
			pass  # Minigame läuft autonom, Taps werden ignoriert
		"star":
			_try_buy_star()
		"done":
			_show_winner()


func _do_roll() -> void:
	# Sofort blockieren: verhindert parallele Würfe, solange await-Kette läuft.
	turn_phase = "minigame"
	var p := logic.current_player()
	var dice := logic.roll_dice(p)
	_set_button_text("🎲 Würfelt…")
	_status("%s würfelt: %d" % [p.name, dice])
	await get_tree().create_timer(0.2).timeout
	_animate_move(p, dice)


func _animate_move(p, dice) -> void:
	# Simpel: Zielposition anzeigen, Feld-Effekt anwenden
	var result := logic.move_player(p, dice)
	_update_status()
	_move_pawn(p)
	_status("%s steht auf Feld %d — %s" % [p.name, p.position, _effect_text(result)])
	await get_tree().create_timer(0.4).timeout
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
	# Pawn-Marker auf das neue Feld setzen
	_position_pawn(p, p.position)


func _start_minigame() -> void:
	# Echte Minispiele über den Runner starten (statt Text-Simulation)
	_mg_layer.visible = true
	_set_button_text("🎮 Minispiel…")
	_status("Minispiel läuft…")
	minigame_runner.start_random()


## Runner fertig → Münzen schon verteilt, weiter zum nächsten Spieler.
func _on_minigame_done(_rewards: Dictionary) -> void:
	_mg_layer.visible = false
	_status("Minispiel vorbei! Münzen verteilt.")
	await get_tree().create_timer(0.6).timeout
	_active_player_next()


## Nächster Spieler (oder Runden-Ende -> Game Over).
func _active_player_next() -> void:
	logic.next_turn()
	if logic.game_over:
		turn_phase = "done"
		_set_button_text("🏆 Ergebnis")
		_show_winner()
		return
	_update_status()
	turn_phase = "roll"
	_set_button_text("🎲 WÜRFELN")
	_status("%s ist dran — würfle!" % logic.current_player().name)


func _player_by_id(pid: int) -> PlayerData:
	for p in logic.players:
		if p.id == pid:
			return p
	return null


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
