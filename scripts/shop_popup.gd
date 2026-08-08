class_name ShopPopup
extends Control
## Shop-Popup: Schaufenster mit Items/Sternen. Öffnet sich auf Shop-Feldern.
## signal buy(item_id) — main.gd führt den Kauf aus.

signal buy(item_id: String)
signal closed

const ITEMS := {
	"lucky_dice": {"name": "Glücks-Würfel", "icon": "🎲", "price": 8, "desc": "Würfle 1-10 statt 1-6"},
	"star_teleport": {"name": "Stern-Teleporter", "icon": "⭐", "price": 15, "desc": "Springe zum Stern-Feld"},
	"shield": {"name": "Schutzschild", "icon": "🛡️", "price": 10, "desc": "Ignoriere 1 Pech-Ereignis"},
	"coin_magnet": {"name": "Münz-Magnet", "icon": "🧲", "price": 6, "desc": "+5 Münzen beim Münz-Feld"},
	"thief_glove": {"name": "Dieb-Handschuh", "icon": "🧤", "price": 12, "desc": "Stehle 5 Münzen von Mitspieler"},
}

var _player: PlayerData
var _coins_label: Label
var _is_star_shop := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # Popup fängt Taps


func open(p: PlayerData, is_star_shop: bool) -> void:
	_player = p
	_is_star_shop = is_star_shop
	_build()
	visible = true


func _build() -> void:
	# Hintergrund (halbtransparent)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# Panel
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -170
	panel.offset_right = 170
	panel.offset_top = -250
	panel.offset_bottom = 250
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	# Titel
	var title := Label.new()
	title.text = "⭐ Sternen-Shop" if _is_star_shop else "🛒 Item-Shop"
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Münzen
	_coins_label = Label.new()
	_coins_label.text = "🪙 %d Münzen" % _player.coins
	_coins_label.add_theme_font_size_override("font_size", 22)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_coins_label)

	if _is_star_shop:
		_add_star_row(vbox)
	else:
		for item_id in ITEMS:
			_add_item_row(vbox, item_id)

	# Schließen
	var close := Button.new()
	close.text = "Schließen"
	close.pressed.connect(func(): closed.emit())
	vbox.add_child(close)


func _add_star_row(vbox: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	vbox.add_child(row)
	var lbl := Label.new()
	lbl.text = "⭐ Stern (20 Münzen)"
	lbl.add_theme_font_size_override("font_size", 20)
	row.add_child(lbl)
	var btn := Button.new()
	btn.text = "Kaufen"
	btn.pressed.connect(func(): buy.emit("star"))
	row.add_child(btn)


func _add_item_row(vbox: VBoxContainer, item_id: String) -> void:
	var item: Dictionary = ITEMS[item_id]
	var row := HBoxContainer.new()
	vbox.add_child(row)
	var lbl := Label.new()
	lbl.text = "%s %s (%d🪙)" % [item.icon, item.name, item.price]
	lbl.add_theme_font_size_override("font_size", 18)
	row.add_child(lbl)
	var btn := Button.new()
	btn.text = "Kaufen"
	btn.pressed.connect(func(): buy.emit(item_id))
	row.add_child(btn)


func update_coins() -> void:
	if _coins_label:
		_coins_label.text = "🪙 %d Münzen" % _player.coins
