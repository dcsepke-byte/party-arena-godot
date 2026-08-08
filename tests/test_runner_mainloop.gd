extends SceneTree
## Testet den MinigameRunner direkt: startet ein Minigame und prüft,
## dass es instanziiert wird und ein finished-Signal feuert (Main-Loop).

var runner: Node
var holder: Node2D
var players: Array = []
var elapsed := 0.0
var started := false
var done := false

func _init() -> void:
	players = [PlayerData.new(0, "Brix", Color("#ff6a00")), PlayerData.new(1, "Nixie", Color("#00f0ff"))]
	# Runner auf einem Layer
	holder = Node2D.new()
	root.add_child(holder)
	var layer := CanvasLayer.new()
	holder.add_child(layer)
	runner = load("res://scripts/minigame_runner.gd").new()
	runner.setup(players, layer)
	layer.add_child(runner)
	runner.start_named(7)  # Tap-Madness (einfach, kein await in _build)
	runner.minigame_done.connect(_on_done)
	print("[T] Runner gestartet")


func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed > 8.0:
		print("[T] Ende: done=", done, " runner=", runner.current)
		quit(0 if done else 1)
	return true

func _on_done(rewards: Dictionary) -> void:
	done = true
	print("[T] Minigame fertig, rewards=", rewards)
