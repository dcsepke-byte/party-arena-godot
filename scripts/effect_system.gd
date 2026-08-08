class_name EffectSystem
extends Node
## Effekte: Popup-Text, Münz-Partikel, Screen-Shake, Farb-Blitz.
## Wird von main.gd aufgerufen.

var _shake_amount := 0.0
var _shake_target: Node2D = null


func setup(target: Node2D) -> void:
	_shake_target = target


func _process(delta: float) -> void:
	if _shake_target and _shake_amount > 0.0:
		_shake_target.position = Vector2(
			randf_range(-_shake_amount, _shake_amount),
			randf_range(-_shake_amount, _shake_amount)
		)
		_shake_amount = max(0.0, _shake_amount - delta * 20.0)
		if _shake_amount <= 0.0:
			_shake_target.position = Vector2.ZERO


## Popup-Text über einem Punkt (z.B. Feld-Effekt).
func popup_text(text: String, at: Vector2, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", color)
	label.position = at
	label.z_index = 50
	add_child(label)
	# Aufsteigen + verblassen
	var tween := create_tween()
	tween.tween_property(label, "position:y", at.y - 60, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)


## Münz-Partikel-Spritzer an einem Punkt.
func coin_burst(at: Vector2, count: int = 8) -> void:
	for i in count:
		var p := Label.new()
		p.text = "🪙"
		p.position = at
		p.z_index = 50
		add_child(p)
		var tween := create_tween()
		var dir := Vector2(randf_range(-1, 1), randf_range(-1, 0)).normalized() * randf_range(40, 90)
		tween.tween_property(p, "position", at + dir, 0.6)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.6)
		tween.tween_callback(p.queue_free)


## Konfetti beim Stern-Kauf.
func confetti(at: Vector2) -> void:
	for i in 20:
		var p := Label.new()
		p.text = ["⭐", "✨", "🎉", "🌟"][i % 4]
		p.position = at
		p.z_index = 50
		add_child(p)
		var tween := create_tween()
		var dir := Vector2(randf_range(-1, 1), randf_range(-1, 0)).normalized() * randf_range(60, 140)
		tween.tween_property(p, "position", at + dir, 0.8)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.8)
		tween.tween_callback(p.queue_free)


## Screen-Shake.
func shake(amount: float) -> void:
	_shake_amount = amount
