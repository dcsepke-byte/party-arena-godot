extends SceneTree
## ECHTER E2E-Test mit Main-Loop über Autoload-Node.
## Da SceneTree._init() kein await/Timer unterstützt, laufen wir über einen
## Node, den wir in den Main-Loop einhängen, und dessen _process die Timer
## der Engine verarbeitet.

var runner: Node
var failures := 0
var passes := 0


func _init() -> void:
	runner = Node.new()
	runner.set_script(load("res://tests/e2e_runner.gd"))
	runner.set_meta("e2e_tree", self)
	root.add_child(runner)


## Wird vom Runner nach Abschluss aufgerufen.
func finish(fail: int) -> void:
	print("\n========== E2E-TEST (echter Main-Loop) ==========")
	print("PASS: %d  FAIL: %d" % [passes, fail])
	quit(fail if fail > 0 else 0)
