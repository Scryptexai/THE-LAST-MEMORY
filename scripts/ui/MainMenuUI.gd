extends Control
## MainMenuUI — judul, tombol Mulai/Lanjut/Muat/Pengaturan, slot save,
## serta latar gradasi + kartu "sebelumnya di Kota Tua Pesisir".

var _title_label: Label
var _subtitle: Label
var _button_box: VBoxContainer
var _slot_box: VBoxContainer
var _bg: ColorRect
var _t: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	refresh()
	visibility_changed.connect(_on_visibility_refresh)


func _build() -> void:
	_bg = ColorRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color("#1A365D")
	add_child(_bg)
	# Pita aksen sinematik.
	var band_top := ColorRect.new()
	band_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	band_top.offset_bottom = 90
	band_top.color = Color(0.03, 0.06, 0.12, 1.0)
	add_child(band_top)
	var band_bottom := ColorRect.new()
	band_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	band_bottom.offset_top = -90
	band_bottom.color = Color(0.03, 0.06, 0.12, 1.0)
	add_child(band_bottom)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 10)
	main.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(main)
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(_subtitle, 18, ThemeFactory.PASTEL_BLUE)
	main.add_child(_subtitle)
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(_title_label, 64, ThemeFactory.PASTEL_YELLOW, true)
	main.add_child(_title_label)
	var tagline := Label.new()
	tagline.text = "Kota Tua Pesisir, 2026 — masa lalu tidak pernah benar-benar pergi."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(tagline, 16, ThemeFactory.CREAM)
	main.add_child(tagline)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(1, 10)
	main.add_child(gap)
	_button_box = VBoxContainer.new()
	_button_box.add_theme_constant_override("separation", 8)
	_button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	main.add_child(_button_box)
	_slot_box = VBoxContainer.new()
	_slot_box.add_theme_constant_override("separation", 6)
	main.add_child(_slot_box)


func _process(delta: float) -> void:
	# Latar bernapas halus (gradasi via modulasi warna).
	_t += delta
	if visible:
		var k: float = 0.5 + 0.5 * sin(_t * 0.4)
		_bg.color = Color("#1A365D").lerp(Color("#3b2f52"), k * 0.55)


func refresh() -> void:
	var dm := DataManager
	_subtitle.text = dm.tr_key("menu_subtitle")
	_title_label.text = "THE LAST MEMORY"
	for c in _button_box.get_children():
		c.queue_free()
	for c in _slot_box.get_children():
		c.queue_free()
	var sm := SignalBus
	_add_button(dm.tr_key("menu_new"), _on_new_game)
	if SaveManager.has_any_save():
		_add_button(dm.tr_key("menu_continue"), _on_continue)
	_add_button(dm.tr_key("menu_load"), _on_show_slots)
	_add_button(dm.tr_key("menu_settings"), func() -> void: sm.ui_screen_requested.emit("settings"))
	_add_button(dm.tr_key("menu_quit"), _on_quit)
	# Sapa pemain lama dengan progres ending.
	var gm := GameManager
	if not (gm.endings_seen as Array).is_empty():
		var l := Label.new()
		l.text = dm.tr_key("menu_endings_seen").format({"n": (gm.endings_seen as Array).size()})
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeFactory.style_label(l, 14, ThemeFactory.PASTEL_PINK)
		_slot_box.add_child(l)


func _add_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 46)
	ThemeFactory.style_button(b, 20)
	b.pressed.connect(cb)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button_box.add_child(b)
	return b


func _on_new_game() -> void:
	SignalBus.sfx_requested.emit("sfx_door_open")
	var main := get_tree().current_scene
	if main and main.has_method("start_new_game"):
		main.start_new_game()


func _on_continue() -> void:
	SignalBus.sfx_requested.emit("sfx_door_open")
	var sm := SaveManager
	var data: Dictionary = sm.load_autosave()
	if data.is_empty():
		# Cari slot terbaru.
		for i in range(1, 4):
			var d: Dictionary = sm.load_from_slot(i)
			if not d.is_empty():
				data = d
				break
	var main := get_tree().current_scene
	if main and main.has_method("continue_game"):
		main.continue_game(data)


func _on_show_slots() -> void:
	for c in _slot_box.get_children():
		c.queue_free()
	var dm := DataManager
	var sm := SaveManager
	for i in range(1, 4):
		var info: Dictionary = sm.slot_info(i)
		var b := Button.new()
		b.custom_minimum_size = Vector2(420, 40)
		if info.is_empty():
			b.text = dm.tr_key("menu_slot_empty").format({"n": i})
			b.disabled = true
		else:
			var loc_name: String = str((dm.get_scene_data(str(info.get("location", ""))) as Dictionary).get("name", "?"))
			b.text = dm.tr_key("menu_slot_filled").format({"n": i, "loc": loc_name,
				"time": MathUtils.format_playtime(float(info.get("playtime", 0.0))),
				"clues": int(info.get("clues", 0))})
			b.pressed.connect(_on_load_slot.bind(i))
		ThemeFactory.style_button(b, 15)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_slot_box.add_child(b)


func _on_load_slot(slot: int) -> void:
	SignalBus.sfx_requested.emit("sfx_door_open")
	var main := get_tree().current_scene
	if main and main.has_method("continue_game"):
		main.continue_game(SaveManager.load_from_slot(slot))


func _on_quit() -> void:
	get_tree().quit()


func _on_visibility_refresh() -> void:
	if visible:
		refresh()
