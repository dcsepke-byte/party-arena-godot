class_name TapMadness
extends BaseMinigame
## Tap-Wahnsinn: Tippe den großen Button so oft wie möglich in 10 Sekunden.

const DURATION := 10.0
var taps := 0


func _init() -> void:
	name = "Tap-Wahnsinn"
	timer_duration = DURATION


func _build() -> void:
	queue_redraw()


func on_tap(player: PlayerData) -> void:
	taps += 1
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 390, 844), Color("#1a1a2e"))
	# Großer Tap-Button
	draw_rect(Rect2(40, 300, 310, 250), Color("#ff8a65"))
	draw_string(ThemeDB.fallback_font, Vector2(70, 420), "TAP!", HORIZONTAL_ALIGNMENT_LEFT, 250, 60, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(16, 60), "👆 %d Taps" % taps, HORIZONTAL_ALIGNMENT_LEFT, 300, 36, Color.WHITE)


func get_score(pid: int) -> int:
	return taps
