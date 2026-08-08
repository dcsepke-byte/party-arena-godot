class_name PrecisionStop
extends BaseMinigame
## Präzisions-Stopp: Stoppe den wandernden Balken genau in der Mitte.
## 3 Versuche, beste Abweichung gewinnt (minimalste Abweichung).

const ATTEMPTS := 3
const BAR_WIDTH := 240.0

var bar_pos := 0.0       # 0..1
var bar_dir := 1.0
var attempts_done := 0
var best_dev := 9999.0   # Abweichung in %


func _init() -> void:
	name = "Präzisions-Stopp"


func _build() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	super(delta)
	if attempts_done < ATTEMPTS:
		bar_pos += bar_dir * delta * 0.6
		if bar_pos > 1.0:
			bar_pos = 1.0
			bar_dir = -1.0
		elif bar_pos < 0.0:
			bar_pos = 0.0
			bar_dir = 1.0
		queue_redraw()


func on_tap(player: PlayerData) -> void:
	if attempts_done >= ATTEMPTS:
		return
	var dev: float = abs(bar_pos - 0.5) * 200.0  # in %
	if dev < best_dev:
		best_dev = dev
	attempts_done += 1
	if attempts_done >= ATTEMPTS:
		_running = false
		finished.emit([players[0]])
	else:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 390, 844), Color("#1a1a2e"))
	# Zielzone (Mitte)
	var cx := 195.0
	draw_rect(Rect2(cx - 10, 300, 20, 160), Color("#2ecc71"))
	# Balken
	var bx := cx - BAR_WIDTH / 2 + bar_pos * BAR_WIDTH
	draw_rect(Rect2(bx, 300, 30, 160), Color("#3498db"))
	draw_string(ThemeDB.fallback_font, Vector2(16, 60), "🎚️ Beste: %.1f%%" % best_dev, HORIZONTAL_ALIGNMENT_LEFT, 300, 28, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(16, 100), "Versuche: %d/%d" % [attempts_done, ATTEMPTS], HORIZONTAL_ALIGNMENT_LEFT, 300, 24, Color.WHITE)


func get_score(pid: int) -> int:
	# Geringere Abweichung = besser
	return -int(best_dev * 10)
