extends Control
## MainMenuUI — judul, tombol Mulai/Lanjut/Muat/Pengaturan, slot save,
## serta latar gradasi + kartu "sebelumnya di Kota Tua Pesisir".

var _title_label: Label
var _subtitle: Label
var _button_box: VBoxContainer
var _slot_box: VBoxContainer
var _bg: ColorRect
var _keyart: TextureRect
var _t: float = 0.0
var _credits_dim: ColorRect
var _credits_panel: PanelContainer
var _memory_dim: ColorRect
var _memory_box: VBoxContainer


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
	# Key art anime (Kota Tua Pesisir saat senja) + gradasi gelap agar teks terbaca.
	var keyart_tex: Texture2D = ThemeFactory.art_texture("res://assets/art/ui/keyart_menu.png")
	if keyart_tex:
		_keyart = TextureRect.new()
		_keyart.texture = keyart_tex
		_keyart.set_anchors_preset(Control.PRESET_FULL_RECT)
		_keyart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_keyart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_keyart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_keyart)
		var shade := ColorRect.new()
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.color = Color(0.03, 0.05, 0.1, 0.42)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shade)
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
	_build_credits_overlay()
	_build_memory_overlay()


func _process(delta: float) -> void:
	# Latar bernapas halus (gradasi via modulasi warna).
	_t += delta
	if visible:
		var k: float = 0.5 + 0.5 * sin(_t * 0.4)
		_bg.color = Color("#1A365D").lerp(Color("#3b2f52"), k * 0.55)
		if _keyart and not GameManager.reduce_motion:
			# Ken Burns pelan: zoom 100→106 % bolak-balik.
			var z: float = 1.0 + 0.06 * (0.5 + 0.5 * sin(_t * 0.12))
			_keyart.pivot_offset = _keyart.size * 0.5
			_keyart.scale = Vector2(z, z)


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
	if not _seen_endings().is_empty():
		_add_button(dm.tr_key("menu_ngplus"), _on_new_game_plus)
		_add_button(dm.tr_key("menu_hard"), _on_new_game_hard)
	if SaveManager.has_any_save():
		_add_button(dm.tr_key("menu_continue"), _on_continue)
	_add_button(dm.tr_key("menu_load"), _on_show_slots)
	_add_button(dm.tr_key("menu_settings"), func() -> void: sm.ui_screen_requested.emit("settings"))
	_add_button(dm.tr_key("menu_quit"), _on_quit)
	_add_button(dm.tr_key("menu_credits"), _on_credits)
	_add_button(dm.tr_key("menu_memory"), open_memory)
	# Galeri ending.
	_build_gallery(dm, GameManager)


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


func _on_new_game_plus() -> void:
	SignalBus.sfx_requested.emit("sfx_clue_found")
	var main := get_tree().current_scene
	if main and main.has_method("start_new_game"):
		main.start_new_game(true)


func _on_new_game_hard() -> void:
	SignalBus.sfx_requested.emit("sfx_memory")
	var main := get_tree().current_scene
	if main and main.has_method("start_new_game"):
		main.start_new_game(false, true)


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


## Galeri 4 ending: yang sudah ditemukan tampil, sisanya "???".
func _build_gallery(dm, _gm) -> void:
	var title := Label.new()
	title.text = dm.tr_key("menu_endings_seen").format({"n": _seen_endings().size()})
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(title, 14, ThemeFactory.PASTEL_PINK)
	_slot_box.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	_slot_box.add_child(row)
	for eid in ["ending_kebenaranutuh", "ending_pengorbanan", "ending_rahasiaterkubur", "ending_lukalama"]:
		var e: Dictionary = dm.get_ending(eid)
		var chip := Label.new()
		if eid in _seen_endings():
			var t: String = str(e.get("title", eid)) if dm.language == "id" else str(e.get("title_en", eid))
			chip.text = "%s %s" % [str(e.get("art", "\u2726")), t]
			ThemeFactory.style_label(chip, 13, ThemeFactory.PASTEL_YELLOW)
		else:
			chip.text = "\u2754 ???"
			ThemeFactory.style_label(chip, 13, Color(0.5, 0.5, 0.55))
		row.add_child(chip)


func _build_credits_overlay() -> void:
	_credits_dim = ThemeFactory.dim_layer(0.75)
	_credits_dim.visible = false
	add_child(_credits_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_credits_dim.add_child(center)
	_credits_panel = PanelContainer.new()
	_credits_panel.custom_minimum_size = Vector2(560, 0)
	_credits_panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style())
	center.add_child(_credits_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_credits_panel.add_child(vb)
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.custom_minimum_size = Vector2(520, 0)
	ThemeFactory.apply_font(body, "normal_font", 16)
	body.add_theme_color_override("default_color", ThemeFactory.CREAM)
	vb.add_child(body)
	body.set_meta("credits_body", true)
	var close_btn := Button.new()
	close_btn.text = "\u2715"
	ThemeFactory.style_button(close_btn, 16)
	close_btn.pressed.connect(_on_credits_close)
	vb.add_child(close_btn)


func _on_credits() -> void:
	var dm := DataManager
	for c in _credits_panel.get_child(0).get_children():
		if c is RichTextLabel and (c as RichTextLabel).has_meta("credits_body"):
			(c as RichTextLabel).text = dm.tr_key("credits_body")
	_credits_dim.visible = true


func _on_credits_close() -> void:
	_credits_dim.visible = false


## Gabungan sesi + memori global lintas-sesi.
func _seen_endings() -> Array:
	var out: Array = (GameManager.endings_seen as Array).duplicate()
	for e in (SaveManager.load_global().get("endings", []) as Array):
		if not (e in out):
			out.append(e)
	return out


func _seen_achievements() -> Array:
	var out: Array = (AchievementManager.unlocked as Array).duplicate()
	for a in (SaveManager.load_global().get("achievements", []) as Array):
		if not (a in out):
			out.append(a)
	return out


func _build_memory_overlay() -> void:
	_memory_dim = ThemeFactory.dim_layer(0.8)
	_memory_dim.visible = false
	add_child(_memory_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_memory_dim.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style())
	center.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 440)
	panel.add_child(scroll)
	_memory_box = VBoxContainer.new()
	_memory_box.add_theme_constant_override("separation", 10)
	_memory_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_memory_box)


func open_memory() -> void:
	_refresh_memory()
	_memory_dim.visible = true


func _on_memory_close() -> void:
	_memory_dim.visible = false


func _refresh_memory() -> void:
	var dm := DataManager
	for c in _memory_box.get_children():
		c.queue_free()
	var seen := _seen_endings()
	var ach := _seen_achievements()
	var title := Label.new()
	title.text = dm.tr_key("menu_memory")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(title, 28, ThemeFactory.PASTEL_YELLOW, true)
	_memory_box.add_child(title)
	var stats := Label.new()
	stats.text = dm.tr_key("memory_stats").format({"n": seen.size(), "a": ach.size(), "t": dm.achievements.size()})
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(stats, 15, ThemeFactory.PASTEL_BLUE)
	_memory_box.add_child(stats)
	var sm := SaveManager
	var gstats := Label.new()
	var fastest: float = sm.global_stat("fastest_ending")
	gstats.text = dm.tr_key("memory_gstats").format({
		"runs": int(sm.global_stat("runs")),
		"time": MathUtils.format_playtime(sm.global_stat("total_playtime")),
		"best": int(sm.global_stat("best_completion")),
		"fast": MathUtils.format_playtime(fastest) if fastest > 0.0 else "—"})
	gstats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gstats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeFactory.style_label(gstats, 14, ThemeFactory.PASTEL_PINK)
	_memory_box.add_child(gstats)
	for eid in ["ending_kebenaranutuh", "ending_pengorbanan", "ending_rahasiaterkubur", "ending_lukalama"]:
		_memory_box.add_child(_memory_card(dm, str(eid), eid in seen))
	var hint := Label.new()
	hint.text = dm.tr_key("memory_hint")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(hint, 14, Color(0.7, 0.7, 0.75))
	_memory_box.add_child(hint)
	var close_btn := Button.new()
	close_btn.text = "✕ Tutup"
	ThemeFactory.style_button(close_btn, 16)
	close_btn.pressed.connect(_on_memory_close)
	_memory_box.add_child(close_btn)


func _memory_card(dm, eid: String, seen: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.1, 0.15, 0.26, 0.9), Color(0.5, 0.55, 0.65, 0.5), 1, 6))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	p.add_child(vb)
	var head := Label.new()
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if seen:
		var e: Dictionary = dm.get_ending(eid)
		var t: String = str(e.get("title", eid)) if dm.language == "id" else str(e.get("title_en", eid))
		var d: String = str(e.get("description", "")) if dm.language == "id" else str(e.get("description_en", ""))
		head.text = "%s %s" % [str(e.get("art", "✦")), t]
		ThemeFactory.style_label(head, 18, ThemeFactory.PASTEL_YELLOW, true)
		body.text = d
		ThemeFactory.style_label(body, 14, ThemeFactory.CREAM)
	else:
		head.text = "🔒 ???"
		ThemeFactory.style_label(head, 18, Color(0.5, 0.5, 0.55), true)
		body.text = dm.tr_key("memory_locked")
		ThemeFactory.style_label(body, 14, Color(0.6, 0.6, 0.65))
	vb.add_child(head)
	vb.add_child(body)
	return p
