class_name TowerStack
extends BaseMinigame
## Tower Stack: Stapele Blöcke. Je präziser der Block auf den vorherigen passt,
## desto höher der Turm. 30 Sekunden, meiste Blöcke gewinnt.

const DURATION := 30.0
const BLOCK_W := 200.0
const BLOCK_H := 40.0
const MAX_DEVIATION := 80.0

var stack: Array = []     # {x_center, width}
var current_x := 0.0
var current_dir := 1.0
var blocks := 0
var _move_speed := 200.0


func _init() -> void:
	name = "Tower Stack"
	timer_duration = DURATION


func _build() -> void:
	# Start-Block unten mittig
	stack.append({"x_center": 195.0, "width": BLOCK_W})
	current_x = 0.0


func _process(delta: float) -> void:
	super(delta)
	current_x += current_dir * _move_speed * delta
	if current_x > 390.0:
		current_x = 390.0
		current_dir = -1.0
	elif current_x < 0.0:
		current_x = 0.0
		current_dir = 1.0
	queue_redraw()


func on_tap(player: PlayerData) -> void:
	var top := stack[stack.size() - 1]
	# Deviations-Berechnung: aktuelle Position vs. Top-Block
	var new_w := top.width - abs(current_x - top.x_center)
	if new_w <= 5:
		# Verpasst — Spiel vorbei
		_running = false
		finished.emit([players[0]])
		return
	var new_center := top.x_center if current_x > top.x_center else current_x + new_w / 2
	# Korrektur: Der neue Block sitzt auf der Überlappung
	new_center = current_x + new_w / 2
	if abs(current_x - top.x_center) < 2:
		# Perfekt — Bonus
		new_w = top.width
		new_center = top.x_center
	stack.append({"x_center": new_center, "width": new_w})
	blocks += 1
	# Neuer Block startet
	current_x = 0.0


func _draw() -> void:
	draw_rect(Rect2(0, 0, 390, 844), Color("#1a1a2e"))
	# Stack von unten aufbauen
	var y := 650.0
	for s in stack:
		draw_rect(Rect2(s.x_center - s.width / 2, y - BLOCK_H, s.width, BLOCK_H), Color("#3498db"))
		y -= BLOCK_H
	# Aktueller Block
	draw_rect(Rect2(current_x - BLOCK_W / 2, y - BLOCK_H, BLOCK_W, BLOCK_H), Color("#e74c3c"))
	draw_string(ThemeDB.fallback_font, Vector2(16, 60), "🧱 Blöcke: %d" % blocks, HORIZONTAL_ALIGNMENT_LEFT, 300, 30, Color.WHITE)


func get_score(pid: int) -> int:
	return blocks
