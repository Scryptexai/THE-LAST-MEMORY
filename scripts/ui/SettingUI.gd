extends Control
## SettingUI — pengaturan audio & bahasa + menu jeda (lanjut, simpan, menu utama).

var _music_slider: HSlider
var _sfx_slider: HSlider
var _ambient_slider: HSlider
var _lang_btn: OptionButton
var _mute_check: CheckBox
var _title: Label
var _resume_btn: Button
var _slot_row: HBoxContainer
var _help_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	visibility_changed.connect(_on_visibility_refresh)


func _build() -> void:
	add_child(ThemeFactory.dim_layer(0.65))
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style())
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(_title, 26, ThemeFactory.PASTEL_YELLOW, true)
	root.add_child(_title)
	_music_slider = _add_slider(root, "🎵 Musik")
	_sfx_slider = _add_slider(root, "🔔 Efek Suara")
	_ambient_slider = _add_slider(root, "🌊 Suasana")
	_music_slider.value_changed.connect(func(v: float) -> void: AudioManager.set_music_volume(v / 100.0))
	_sfx_slider.value_changed.connect(func(v: float) -> void:
		AudioManager.set_sfx_volume(v / 100.0)
		SignalBus.sfx_requested.emit("sfx_dialogue_click"))
	_ambient_slider.value_changed.connect(func(v: float) -> void: AudioManager.set_ambient_volume(v / 100.0))
	# Bahasa.
	var lang_row := HBoxContainer.new()
	root.add_child(lang_row)
	var lang_label := Label.new()
	lang_label.text = "🌐 Bahasa / Language"
	ThemeFactory.style_label(lang_label, 16, ThemeFactory.CREAM)
	lang_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang_row.add_child(lang_label)
	_lang_btn = OptionButton.new()
	_lang_btn.add_item("Indonesia", 0)
	_lang_btn.add_item("English", 1)
	ThemeFactory.style_button(_lang_btn, 15)
	_lang_btn.item_selected.connect(_on_language)
	lang_row.add_child(_lang_btn)
	# Mute.
	_mute_check = CheckBox.new()
	_mute_check.text = "🔇 Bisukan semua suara"
	_mute_check.add_theme_font_override("font", ThemeFactory.body_font(16))
	_mute_check.add_theme_color_override("font_color", ThemeFactory.CREAM)
	_mute_check.toggled.connect(func(on: bool) -> void: AudioManager.set_muted(on))
	root.add_child(_mute_check)
	# Slot simpan.
	var save_label := Label.new()
	save_label.text = "💾 Simpan permainan"
	ThemeFactory.style_label(save_label, 16, ThemeFactory.ACCENT_LIGHT, true)
	root.add_child(save_label)
	_slot_row = HBoxContainer.new()
	_slot_row.add_theme_constant_override("separation", 8)
	root.add_child(_slot_row)
	# Tombol aksi.
	_resume_btn = _add_action(root, "▶ Lanjutkan", _on_resume)
	_add_action(root, "🏠 Menu Utama", _on_menu)
	_add_action(root, "🚪 Keluar Game", func() -> void: get_tree().quit())
	_help_label = Label.new()
	_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeFactory.style_label(_help_label, 13, Color(0.8, 0.8, 0.85))
	root.add_child(_help_label)


func _add_slider(parent: VBoxContainer, label_text: String) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := Label.new()
	l.text = label_text
	l.custom_minimum_size = Vector2(150, 0)
	ThemeFactory.style_label(l, 16, ThemeFactory.CREAM)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.step = 1
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(s)
	return s


func _add_action(parent: VBoxContainer, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	ThemeFactory.style_button(b, 17)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func refresh() -> void:
	var dm := DataManager
	var am := AudioManager
	var gm := GameManager
	_title.text = dm.tr_key("settings_title")
	_music_slider.set_value_no_signal(am.music_volume * 100.0)
	_sfx_slider.set_value_no_signal(am.sfx_volume * 100.0)
	_ambient_slider.set_value_no_signal(am.ambient_volume * 100.0)
	_mute_check.set_pressed_no_signal(am.muted)
	_lang_btn.select(1 if dm.language == "en" else 0)
	var in_game: bool = gm.state in ["pause", "settings"] and gm.state != "main_menu" and get_tree().current_scene and get_tree().current_scene.get("in_game") == true
	_resume_btn.visible = in_game
	for c in _slot_row.get_children():
		c.queue_free()
	var sm := SignalBus
	if in_game:
		for i in range(1, 4):
			var b := Button.new()
			b.text = dm.tr_key("menu_slot").format({"n": i})
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ThemeFactory.style_button(b, 15)
			b.pressed.connect(_on_save_slot.bind(i))
			_slot_row.add_child(b)
	else:
		var l := Label.new()
		l.text = dm.tr_key("settings_no_save")
		ThemeFactory.style_label(l, 14, Color(0.75, 0.75, 0.8))
		_slot_row.add_child(l)
	_help_label.text = dm.tr_key("settings_controls")


func _on_language(index: int) -> void:
	DataManager.set_language("en" if index == 1 else "id")
	refresh()


func _on_save_slot(slot: int) -> void:
	if SaveManager.save_to_slot(slot):
		SignalBus.sfx_requested.emit("sfx_deduction_correct")
	refresh()


func _on_resume() -> void:
	var gm := GameManager
	gm.change_state("gameplay")


func _on_menu() -> void:
	var main := get_tree().current_scene
	if main and main.has_method("quit_to_menu"):
		main.quit_to_menu()


func _on_visibility_refresh() -> void:
	if visible:
		refresh()
