class_name FlyingDice
extends Node2D
## Fliegender Würfel: fliegt über das Spielfeld, dreht sich in der Luft,
## landet mit sichtbarer Augenzahl. Wird von main.gd gestartet.

signal landed(value: int)

var _value := 1
var _t := 0.0
var _duration := 1.2
var _start := Vector2.ZERO
var _target := Vector2.ZERO
var _flying := false
var _size := 60.0
var _rot := 0.0


func start(from: Vector2, to: Vector2, value: int) -> void:
	_start = from
	_target = to
	_value = value
	_t = 0.0
	_flying = true
	position = from
	queue_redraw()


func _process(delta: float) -> void:
	if not _flying:
		return
	_t += delta / _duration
	if _t >= 1.0:
		_t = 1.0
		_flying = false
		# Lande-Wackel
		position = _target
		landed.emit(_value)
		queue_redraw()
		return
	# Parabel-Flug (Bogen)
	var t := _t
	var x := lerpf(_start.x, _target.x, t)
	var y := lerpf(_start.y, _target.y, t) - sin(t * PI) * 120.0  # Bogenhöhe
	position = Vector2(x, y)
	# Drehung in der Luft
	_rot += delta * 8.0
	queue_redraw()


func _draw() -> void:
	# Würfel-Body (weiß mit schwarzem Rand)
	var r := Rect2(-_size / 2, -_size / 2, _size, _size)
	draw_rect(r, Color("#f5f5f5"))
	draw_rect(r, Color("#333333"), false, 4.0)
	# Augen (Punkte) je nach Wert
	_draw_pips(_value)


func _draw_pips(v: int) -> void:
	var s := _size / 6.0
	var c := _size / 4.0
	var pip := Color("#222222")
	var positions := {
		1: [Vector2(0, 0)],
		2: [Vector2(-c, -c), Vector2(c, c)],
		3: [Vector2(-c, -c), Vector2(0, 0), Vector2(c, c)],
		4: [Vector2(-c, -c), Vector2(c, -c), Vector2(-c, c), Vector2(c, c)],
		5: [Vector2(-c, -c), Vector2(c, -c), Vector2(0, 0), Vector2(-c, c), Vector2(c, c)],
		6: [Vector2(-c, -c), Vector2(c, -c), Vector2(-c, 0), Vector2(c, 0), Vector2(-c, c), Vector2(c, c)],
	}
	for p in positions[v]:
		draw_circle(p, s, pip)
