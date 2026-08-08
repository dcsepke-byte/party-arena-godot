class_name NinjaSlash
extends BaseMinigame
## Ninja Slash: Schlitze Früchte (+2), meide Bomben (-4). 20 Sekunden.
## Swipe/Tippe aufs Ziel.

const DURATION := 20.0
const FRUIT_COUNT := 10
const BOMB_COUNT := 3

var targets: Array = []   # {pos, kind: "fruit"/"bomb", vy, hit}
var score := 0
var _spawn_timer := 0.0
var slice_line: Array = []  # Slice-Punkte


func _init() -> void:
	name = "Ninja Slash"
	timer_duration = DURATION


func _build() -> void:
	for i in FRUIT_COUNT:
		_spawn_target("fruit")
	for i in BOMB_COUNT:
		_spawn_target("bomb")


func _spawn_target(kind: String) -> void:
	targets.append({
		"pos": Vector2(randf_range(30, 360), randf_range(650, 750)),
		"kind": kind,
		"vy": randf_range(200, 350),
		"hit": false
	})


func _process(delta: float) -> void:
	super(delta)
	# Targets hochfliegen lassen
	for t in targets:
		if not t.hit:
			t.pos.y -= t.vy * delta
			if t.pos.y < -30:
				t.pos.y = 700
	_spawn_timer += delta
	if _spawn_timer > 1.0:
		_spawn_timer = 0
		var active := 0
		for t in targets:
			if not t.hit:
				active += 1
		if active < 4:
			_spawn_target("fruit")
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not _running:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			slice_line = [event.position]
			_hit_at(event.position)
		else:
			slice_line = []


func _hit_at(pos: Vector2) -> void:
	var best := -1
	var best_d := 80.0
	for i in targets.size():
		if targets[i].hit:
			continue
		var d: float = targets[i].pos.distance_to(pos)
		if d < best_d:
			best_d = d
			best = i
	if best >= 0:
		targets[best].hit = true
		if targets[best].kind == "fruit":
			score += 2
		else:
			score = max(0, score - 4)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 390, 844), Color("#1a1a2e"))
	for t in targets:
		if t.hit:
			continue
		if t.kind == "fruit":
			draw_circle(t.pos, 22, Color("#ff4d6d"))
			draw_string(ThemeDB.fallback_font, t.pos - Vector2(10, 0), "🍎", HORIZONTAL_ALIGNMENT_LEFT, 44, 26, Color.WHITE)
		else:
			draw_circle(t.pos, 22, Color("#2c2c2c"))
			draw_string(ThemeDB.fallback_font, t.pos - Vector2(10, 0), "💣", HORIZONTAL_ALIGNMENT_LEFT, 44, 26, Color.WHITE)
	if slice_line.size() == 1:
		draw_circle(slice_line[0], 30, Color(1, 1, 1, 0.3))
	draw_string(ThemeDB.fallback_font, Vector2(16, 60), "🗡️ %d Punkte" % score, HORIZONTAL_ALIGNMENT_LEFT, 300, 30, Color.WHITE)


func get_score(pid: int) -> int:
	return score
