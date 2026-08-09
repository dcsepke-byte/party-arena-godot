class_name BackpackUI
extends Control
## Rucksack/Inventar-Overlay: zeigt Items des aktiven Spielers, benutzen per Tap.
## signal item_used(item_id) — main.gd führt die Aktion aus.

signal item_used(item_id: String)
signal closed

const ITEM_NAMES := {
	"lucky_dice": "🎲 Glücks-Würfel",
	"star_teleport": "⭐ Stern-Teleporter",
	"shield": "🛡️ Schutzschild",
	"coin_magnet": "🧲 Münz-Magnet",
	"thief_glove": "🧤 Dieb-Handschuh",
}

var _player: PlayerData
var _list: VBoxContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func open(p: PlayerData) -> void:
	_player = p
	_build()
	visible = true


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -170
	panel.offset_right = 170
	panel.offset_top = -250
	panel.offset_bottom = 250
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "🎒 Rucksack — %s" % _player.name
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_list = VBoxContainer.new()
	vbox.add_child(_list)
	_refresh()

	var close := Button.new()
	close.text = "Schließen"
	close.pressed.connect(func(): closed.emit())
	vbox.add_child(close)


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	if _player.items.is_empty():
		var empty := Label.new()
		empty.text = "Rucksack ist leer"
		empty.add_theme_font_size_override("font_size", 18)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)
		return
	for item_id in _player.items:
		var row := HBoxContainer.new()
		_list.add_child(row)
		var lbl := Label.new()
		lbl.text = ITEM_NAMES.get(item_id, item_id)
		lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(lbl)
		var btn := Button.new()
		btn.text = "Benutzen"
		btn.pressed.connect(func(): item_used.emit(item_id))
		row.add_child(btn)
