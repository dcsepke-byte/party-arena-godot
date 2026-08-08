class_name TargetJagd
extends BaseMinigame
## Ziel-Jagd: Triff die Sterne (+,+2), meide die Bomben (-,-3). 20 Sekunden.
## Tippe direkt auf das Ziel auf dem Bildschirm.

const DURATION := 20.0
const STAR_COUNT := 8
const BOMB_COUNT := 4

var targets: Array = []   # {pos, kind: "star"/"bomb", hit: bool}
var score := 0
var _spawn_timer := 0.0


func _init() -> void:
	name = "Ziel-Jagd"
	timer_duration = DURATION


func _build() -> void:
	for i in STAR_COUNT:
		_spawn_target("star")
	for i in BOMB_COUNT:
		_spawn_target("bomb")


func _spawn_target(kind: String) -> void:
	targets.append({
		"pos": Vector2(randf_range(40, 350), randf_range(120, 500)),
		"kind": kind,
		"hit": false
	})


func _process(delta: float) -> void:
	super(delta)
	_spawn_timer += delta
	if _spawn_timer > 1.5:
		_spawn_timer = 0
		# Nachlegen
		var active := 0
		for t in targets:
			if not t.hit:
				active += 1
		if active < STAR_COUNT / 2:
			_spawn_target("star")


func on_tap(player: PlayerData) -> void:
	# Finde nächstes Ziel in der Nähe des Taps
	pass


func _input(event: InputEvent) -> void:
	if not _running:
		return
	if event is InputEventScreenTouch and event.pressed:
		_hit_at(event.position)


func _hit_at(pos: Vector2) -> void:
	var best := -1
	var best_d := 60.0
	for i in targets.size():
		if targets[i].hit:
			continue
		var d := targets[i].pos.distance_to(pos)
		if d < best_d:
			best_d = d
			best = i
	if best >= 0:
		targets[best].hit = true
		if targets[best].kind == "star":
			score += 2
		else:
			score -= 3
		queue_redraw()
	# Nachlegen
	if targets[best].kind == "star":
		_spawn_target("star")


func _draw() -> void:
	draw_rect(Rect2(0, 0, 390, 844), Color("#1a1a2e"))
	for t in targets:
		if t.hit:
			continue
		if t.kind == "star":
			_draw_star(t.pos)
		else:
			draw_circle(t.pos, 20, Color("#e74c3c"))
			draw_string(ThemeDB.fallback_font, t.pos - Vector2(8, -28), "💣", HORIZONTAL_ALIGNMENT_LEFT, 50, 22, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(16, 60), "🎯 %d Punkte" % score, HORIZONTAL_ALIGNMENT_LEFT, 300, 30, Color.WHITE)


func _draw_star(center: Vector2) -> void:
	var pts := PackedVector2Array()
	var outer := 20.0
	var inner := 8.0
	for i in 10:
		var r := outer if i % 2 == 0 else inner
		var ang := -PI / 2 + i * PI / 5
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	draw_colored_polygon(pts, Color("#ffd700"))


func get_score(pid: int) -> int:
	return score
