extends Control
## InventoryUI — tas Ardi: grid barang + panel detail (nama, deskripsi,
## kegunaan). Hadiah diserahkan otomatis saat bicara dengan pemiliknya.

const ICONS := {"key": "🔑", "gift": "🎁", "tool": "🔦", "misc": "📦"}

var _grid: GridContainer
var _detail_name: Label
var _detail_body: RichTextLabel
var _count_label: Label
var _selected_item: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	visibility_changed.connect(_on_visibility_refresh)
	SignalBus.inventory_updated.connect(_on_visibility_refresh)


func _build() -> void:
	add_child(ThemeFactory.dim_layer(0.6))
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 480)
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style())
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "🎒 Tas Ardi"
	ThemeFactory.style_label(title, 24, ThemeFactory.PASTEL_YELLOW, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_count_label = Label.new()
	ThemeFactory.style_label(_count_label, 15, ThemeFactory.CREAM)
	header.add_child(_count_label)
	var close_btn := Button.new()
	close_btn.text = "✕"
	ThemeFactory.style_button(close_btn, 16)
	close_btn.pressed.connect(func() -> void: GameManager.change_state("gameplay"))
	header.add_child(close_btn)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(detail)
	_detail_name = Label.new()
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeFactory.style_label(_detail_name, 20, ThemeFactory.PASTEL_YELLOW, true)
	detail.add_child(_detail_name)
	_detail_body = RichTextLabel.new()
	_detail_body.bbcode_enabled = true
	_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ThemeFactory.apply_font(_detail_body, "normal_font", 15)
	_detail_body.add_theme_color_override("default_color", ThemeFactory.CREAM)
	detail.add_child(_detail_body)


func refresh() -> void:
	var dm := DataManager
	var im := InvestigationManager
	for c in _grid.get_children():
		c.queue_free()
	_count_label.text = dm.tr_key("inventory_count").format({"n": (im.inventory as Array).size()})
	if (im.inventory as Array).is_empty():
		var empty := Label.new()
		empty.text = dm.tr_key("inventory_empty")
		ThemeFactory.style_label(empty, 15, Color(0.8, 0.8, 0.85))
		_grid.add_child(empty)
	else:
		for item_id in im.inventory:
			var item: Dictionary = dm.get_item(str(item_id))
			var b := Button.new()
			b.toggle_mode = true
			b.button_pressed = str(item_id) == _selected_item
			var icon: String = ICONS.get(str(item.get("kind", "misc")), "📦")
			b.text = "%s\n%s" % [icon, str(item.get("name", item_id))]
			b.custom_minimum_size = Vector2(170, 84)
			ThemeFactory.style_button(b, 14)
			if b.button_pressed:
				b.add_theme_color_override("font_color", ThemeFactory.ACCENT_LIGHT)
			b.pressed.connect(_on_item_pressed.bind(str(item_id)))
			_grid.add_child(b)
	if _selected_item != "" and (im.inventory as Array).has(_selected_item):
		_show_detail(dm.get_item(_selected_item), dm)
	elif not (im.inventory as Array).is_empty():
		_show_detail(dm.get_item(str((im.inventory as Array)[0])), dm)
	else:
		_detail_name.text = ""
		_detail_body.text = dm.tr_key("inventory_empty")


func _on_item_pressed(item_id: String) -> void:
	SignalBus.sfx_requested.emit("sfx_dialogue_click")
	_selected_item = item_id
	refresh()


func _show_detail(item: Dictionary, dm: Node) -> void:
	if item.is_empty():
		return
	_selected_item = str(item.get("id", ""))
	_detail_name.text = str(item.get("name", ""))
	var targets: Array = item.get("usable_on", [])
	var use_text: String = "—"
	if not targets.is_empty():
		var names: Array = []
		for t in targets:
			names.append(_target_name(str(t), dm))
		use_text = ", ".join(names)
	var kind_label: String = str(item.get("kind", "misc"))
	_detail_body.text = "[b]Jenis:[/b] %s\n[b]Berguna untuk:[/b] %s\n\n%s\n\n[i]%s[/i]" % [
		kind_label, use_text, str(item.get("description", "")),
		dm.tr_key("inventory_gift_hint") if kind_label == "gift" else dm.tr_key("inventory_use_hint")]


func _target_name(target_id: String, dm: Node) -> String:
	# Target bisa berupa NPC (character_id) atau objek (cari di semua lokasi).
	if not (dm.get_character(target_id) as Dictionary).is_empty():
		return str((dm.get_character(target_id) as Dictionary).get("name", target_id))
	for scene_id in dm.scenes.keys():
		for o in (dm.scenes[scene_id] as Dictionary).get("interactables", []):
			if str((o as Dictionary).get("object_id", "")) == target_id:
				return str((o as Dictionary).get("display_name", target_id))
	return target_id


func _on_visibility_refresh() -> void:
	if visible:
		refresh()
