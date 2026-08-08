class_name CoinDash
extends BaseMinigame
## Coin Dash: Sammle Münzen, weiche Gegnern aus. 20 Sekunden.
## Touch: Tippe links/rechts, um zu wechseln (Spielfigur in 4 Bahnen).

const DURATION := 20.0
const LANES := 4

var player_pos := 1          # Bahn der Spielfigur (0-3)
var coins: Array = []        # {pos: Vector2, collected: bool}
var enemies: Array = []      # {pos: Vector2, speed: float}
var score := 0
var player_color := Color("#ffd34e")
var _spawn_timer := 0.0


func _init() -> void:
	name = "Coin Dash"
	timer_duration = DURATION


func _build() -> void:
	# Spielfigur (gelbes Quadrat)
	queue_redraw()
	# Anfangs Münzen spawnen
	for i in 8:
		_spawn_coin()


func _process(delta: float) -> void:
	super(delta)  # Timer
	# Gegner bewegen
	for e in enemies:
		e.pos.y += e.speed * delta
		# Kollision mit Spieler
		if abs(e.pos.y - _player_y()) < 24 and abs(e.pos.x - _player_x()) < 24:
			# Verliert 3 Münzen
			score = max(0, score - 3)
			e.pos.y = -100  # raus
	# Münzen einsammeln
	for c in coins:
		if not c.collected and abs(c.pos.y - _player_y()) < 28 and abs(c.pos.x - _player_x()) < 28:
			c.collected = true
			score += 1
	# Spawnen
	_spawn_timer += delta
	if _spawn_timer > 0.8:
		_spawn_timer = 0
		if randf() < 0.7:
			_spawn_coin()
		if randf() < 0.4:
			_spawn_enemy()
	queue_redraw()


func _spawn_coin() -> void:
	coins.append({"pos": Vector2(randf_range(40, 350), randf_range(0, 100)), "collected": false})


func _spawn_enemy() -> void:
	enemies.append({"pos": Vector2(randf_range(40, 350), 0), "speed": randf_range(60, 120)})


func _player_x() -> float:
	return 60.0 + player_pos * 80.0


func _player_y() -> float:
	return 500.0


func _draw() -> void:
	# Hintergrund
	draw_rect(Rect2(0, 0, 390, 844), Color("#1a1a2e"))
	# Münzen
	for c in coins:
		if not c.collected:
			draw_circle(c.pos, 10, Color("#ffd700"))
	# Gegner (rot)
	for e in enemies:
		draw_circle(e.pos, 14, Color("#e74c3c"))
	# Spieler (gelb)
	draw_rect(Rect2(_player_x() - 20, _player_y() - 20, 40, 40), player_color)
	# Punkte
	draw_string(ThemeDB.fallback_font, Vector2(16, 60), "🪙 %d" % score, HORIZONTAL_ALIGNMENT_LEFT, 300, 28, Color.WHITE)


func on_tap(player: PlayerData) -> void:
	# Bahn wechseln
	player_pos = (player_pos + 1) % LANES


func get_score(pid: int) -> int:
	return score
