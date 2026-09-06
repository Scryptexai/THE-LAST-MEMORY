extends Control
## DialogueUI — kotak dialog Life is Strange: efek mengetik, nama pembicara,
## pilihan bercabang (dengan pratinjau efek hubungan), tombol skip & lanjut.

const CHARS_PER_SEC := 45.0

var _name_label: Label
var _text_label: RichTextLabel
var _choice_box: VBoxContainer
var _next_hint: Label
var _skip_btn: Button
var _panel: PanelContainer
var _full_text: String = ""
var _shown: float = 0.0
var _typing: bool = false
var _current_node: String = ""
var _tick_sfx_cd: float = 0.0
var _auto_timer: float = 0.0
var _backlog: Array = []  # Array[String] "Speaker: teks" (maks 40)
var _backlog_panel: PanelContainer
var _backlog_text: RichTextLabel
var _auto_badge: Label
var _portrait: TextureRect
var _portrait_frame: PanelContainer
var _portrait_who: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	var bus := SignalBus
	bus.dialogue_node_shown.connect(_on_node_shown)
	bus.dialogue_finished.connect(_on_dialogue_finished)
	visibility_changed.connect(_on_visibility)


func _build() -> void:
	# Potret anime pembicara di kiri atas kotak dialog.
	_portrait_frame = PanelContainer.new()
	_portrait_frame.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_portrait_frame.offset_left = 40
	_portrait_frame.offset_right = 40 + 232
	_portrait_frame.offset_top = -24 - 330 - 40
	_portrait_frame.offset_bottom = -24 - 330 + 300
	_portrait_frame.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.05, 0.1, 0.19, 0.0), ThemeFactory.ACCENT, 2, 14))
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.clip_contents = true
	_portrait_frame.visible = false
	add_child(_portrait_frame)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(_portrait)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 60
	_panel.offset_right = -60
	_panel.offset_top = -330
	_panel.offset_bottom = -24
	_panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.05, 0.1, 0.19, 0.94)))
	add_child(_panel)
	var margin := VBoxContainer.new()
	margin.add_theme_constant_override("separation", 8)
	_panel.add_child(margin)
	var top := HBoxContainer.new()
	margin.add_child(top)
	_name_label = Label.new()
	ThemeFactory.style_label(_name_label, 22, ThemeFactory.ACCENT_LIGHT, true)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_name_label)
	_skip_btn = Button.new()
	_skip_btn.text = "⏭"
	_skip_btn.tooltip_text = "Lewati mengetik"
	ThemeFactory.style_button(_skip_btn, 14)
	_skip_btn.pressed.connect(_on_skip_pressed)
	top.add_child(_skip_btn)
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.scroll_active = false
	_text_label.custom_minimum_size = Vector2(0, 96)
	ThemeFactory.apply_font(_text_label, "normal_font", 19)
	ThemeFactory.apply_font(_text_label, "bold_font", 19)
	_text_label.add_theme_color_override("default_color", ThemeFactory.CREAM)
	margin.add_child(_text_label)
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 6)
	margin.add_child(_choice_box)
	_next_hint = Label.new()
	_next_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ThemeFactory.style_label(_next_hint, 14, Color(0.8, 0.8, 0.85))
	margin.add_child(_next_hint)
	_skip_btn.focus_mode = Control.FOCUS_NONE
	_auto_badge = Label.new()
	_auto_badge.text = "▶▶ AUTO"
	ThemeFactory.style_label(_auto_badge, 12, ThemeFactory.ACCENT_LIGHT, true)
	_auto_badge.visible = false
	top.add_child(_auto_badge)
	top.move_child(_auto_badge, 1)
	var log_btn := Button.new()
	log_btn.text = "☰"
	log_btn.tooltip_text = "Riwayat dialog"
	log_btn.focus_mode = Control.FOCUS_NONE
	ThemeFactory.style_button(log_btn, 14)
	log_btn.pressed.connect(_toggle_backlog)
	top.add_child(log_btn)
	# Panel riwayat (di atas panel dialog).
	_backlog_panel = PanelContainer.new()
	_backlog_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_backlog_panel.offset_left = 60
	_backlog_panel.offset_right = -60
	_backlog_panel.offset_top = 70
	_backlog_panel.offset_bottom = 380
	_backlog_panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.04, 0.07, 0.14, 0.96), ThemeFactory.PASTEL_BLUE, 1, 10))
	_backlog_panel.visible = false
	add_child(_backlog_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_backlog_panel.add_child(scroll)
	_backlog_text = RichTextLabel.new()
	_backlog_text.bbcode_enabled = true
	_backlog_text.fit_content = true
	_backlog_text.scroll_active = false
	_backlog_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeFactory.apply_font(_backlog_text, "normal_font", 15)
	ThemeFactory.apply_font(_backlog_text, "bold_font", 15)
	_backlog_text.add_theme_color_override("default_color", ThemeFactory.CREAM)
	scroll.add_child(_backlog_text)
	_make_click_through(_panel)


func _toggle_backlog() -> void:
	_backlog_panel.visible = not _backlog_panel.visible
	if _backlog_panel.visible:
		var out: String = ""
		for line in _backlog:
			out += str(line) + "\n"
		_backlog_text.text = out if out != "" else "…"


## Klik di mana pun (kecuali tombol pilihan) memajukan dialog.
func _make_click_through(c: Control) -> void:
	if c is Button:
		return
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in c.get_children():
		if child is Control:
			_make_click_through(child as Control)


func _on_visibility() -> void:
	if not visible:
		_typing = false
		_backlog_panel.visible = false
	else:
		_auto_badge.visible = GameManager.auto_advance


func _on_dialogue_finished(_dlg: String, _last: String) -> void:
	_typing = false
	_backlog.clear()


func _on_node_shown(node_id: String) -> void:
	_current_node = node_id
	var dm := DataManager
	var dlgm := DialogueManager
	var node: Dictionary = dm.get_dialogue(node_id)
	# Warna panel berbeda untuk kilas balik.
	var hc: bool = GameManager.high_contrast
	if bool(node.get("memory", false)):
		_panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(
			Color(0.1, 0.06, 0.0, 1.0) if hc else Color(0.25, 0.16, 0.06, 0.95), ThemeFactory.PASTEL_YELLOW, 3 if hc else 2, 12))
		_name_label.text = "◈ %s  ·  1983" % str(node.get("speaker", "???"))
	else:
		_panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(
			Color(0.0, 0.0, 0.0, 1.0) if hc else Color(0.05, 0.1, 0.19, 0.94), Color.WHITE if hc else ThemeFactory.ACCENT, 3 if hc else 2, 12))
		_name_label.text = str(node.get("speaker", "???"))
	_text_label.add_theme_color_override("default_color", Color.WHITE if hc else ThemeFactory.CREAM)
	ThemeFactory.apply_font(_text_label, "normal_font", 21 if hc else 19)
	_full_text = dm.localized(node)
	_update_portrait(str(node.get("speaker_id", node.get("speaker", ""))), bool(node.get("memory", false)))
	_backlog.append("[b]%s[/b]: %s" % [str(node.get("speaker", "???")), _full_text])
	if _backlog.size() > 40:
		_backlog.pop_front()
	_auto_timer = 0.0
	_auto_badge.visible = GameManager.auto_advance
	_text_label.text = _full_text
	_text_label.visible_characters = 0
	_shown = 0.0
	_typing = true
	_rebuild_choices(node, dlgm, dm)


func _rebuild_choices(node: Dictionary, dlgm: Node, dm: Node) -> void:
	for c in _choice_box.get_children():
		c.queue_free()
	var choices: Array = node.get("choices", [])
	if choices.is_empty():
		_next_hint.text = "▶ %s" % dm.tr_key("dialogue_continue")
	else:
		_next_hint.text = ""
		for i in choices.size():
			var choice: Dictionary = choices[i]
			var avail: Dictionary = dlgm.choice_availability(choice)
			var b := Button.new()
			var rel_preview: String = _relationship_preview(choice, dm)
			var label_text: String = dm.localized(choice)
			if not bool(avail.get("ok", false)):
				label_text = "🔒 " + label_text + "\n   ↳ " + str(avail.get("reason", ""))
			elif rel_preview != "":
				label_text += "\n   ↳ " + rel_preview
			if GameManager.new_game_plus and SaveManager.choice_taken_before(str(node.get("id", "")), i):
				label_text = "◇ " + label_text  # NG+: pernah dipilih di perjalanan sebelumnya
			b.text = "%d. %s" % [i + 1, label_text]
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			ThemeFactory.style_button(b, 16)
			b.pressed.connect(_on_choice_pressed.bind(i))
			_choice_box.add_child(b)


func _relationship_preview(choice: Dictionary, dm: Node) -> String:
	# Tampilkan pratinjau jujur efek hubungan (ala Life is Strange).
	var parts: Array = []
	if GameManager.hard_mode:
		return ""
	var rel: Dictionary = choice.get("relationship", {})
	if rel.is_empty() and choice.has("flags"):
		pass
	for k in rel.keys():
		var delta: int = int(rel[k])
		if delta == 0 or str(k) == "none":
			continue
		var char_name: String = str((dm.get_character(str(k)) as Dictionary).get("name", k))
		var arrow: String = "💛+%d" % delta if delta > 0 else "💔%d" % delta
		parts.append("%s %s" % [char_name, arrow])
	return "   ".join(parts)


func _process(delta: float) -> void:
	if not visible:
		return
	if not _typing:
		# Auto-advance: dialog linear lanjut setelah jeda proporsional panjang teks.
		if GameManager.auto_advance and DialogueManager.is_active() and not _backlog_panel.visible:
			var choices: Array = (DialogueManager.current_node as Dictionary).get("choices", [])
			if choices.is_empty():
				_auto_timer += delta
				if _auto_timer >= clampf(1.2 + _full_text.length() * 0.03, 1.5, 6.0):
					_auto_timer = 0.0
					_advance_or_complete()
		return
	var total: int = _text_label.get_total_character_count()
	if _shown < total:
		_shown += CHARS_PER_SEC * GameManager.text_speed * delta
		_text_label.visible_characters = int(_shown)
		_tick_sfx_cd -= delta
		if _tick_sfx_cd <= 0.0:
			_tick_sfx_cd = 0.09
			SignalBus.sfx_requested.emit("sfx_typing")
	else:
		_typing = false
		_text_label.visible_characters = -1


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var dlgm := DialogueManager
	if not dlgm.is_active():
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var kc: int = (event as InputEventKey).physical_keycode
		# Angka 1-4 memilih opsi dialog langsung.
		if kc >= KEY_1 and kc <= KEY_4:
			var idx: int = kc - KEY_1
			var choices: Array = (dlgm.current_node as Dictionary).get("choices", [])
			if idx < choices.size():
				_on_choice_pressed(idx)
				get_viewport().set_input_as_handled()
				return
		if kc == KEY_A and not (event as InputEventKey).ctrl_pressed:
			GameManager.auto_advance = not GameManager.auto_advance
			_auto_badge.visible = GameManager.auto_advance
			SaveManager.save_settings()
			get_viewport().set_input_as_handled()
			return
		if kc == KEY_H:
			_toggle_backlog()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT):
		if _backlog_panel.visible:
			_backlog_panel.visible = false
			get_viewport().set_input_as_handled()
			return
		# Abaikan klik pada tombol pilihan (mereka menangani sendiri).
		_advance_or_complete()
		get_viewport().set_input_as_handled()


func _advance_or_complete() -> void:
	var dlgm := DialogueManager
	if _typing:
		_shown = _text_label.get_total_character_count()
		_text_label.visible_characters = -1
		_typing = false
		return
	var choices: Array = (dlgm.current_node as Dictionary).get("choices", [])
	if choices.is_empty():
		SignalBus.sfx_requested.emit("sfx_dialogue_click")
		dlgm.advance()


func _on_skip_pressed() -> void:
	_advance_or_complete()


func _on_choice_pressed(index: int) -> void:
	if _typing:
		_advance_or_complete()
		return
	DialogueManager.choose(index)


## Tampilkan potret pembicara (fade + geser kecil saat ganti tokoh). Sepia saat kilas balik.
func _update_portrait(who: String, memory: bool) -> void:
	var tex: Texture2D = ThemeFactory.portrait(who)
	if tex == null:
		_portrait_frame.visible = false
		_portrait_who = ""
		return
	_portrait_frame.visible = true
	_portrait.self_modulate = Color(1.0, 0.9, 0.75) if memory else Color.WHITE
	if who == _portrait_who:
		return
	_portrait_who = who
	_portrait.texture = tex
	if GameManager.reduce_motion:
		return
	_portrait_frame.modulate.a = 0.0
	_portrait_frame.position.x -= 18
	var tw := create_tween().set_parallel(true).bind_node(_portrait_frame)
	tw.tween_property(_portrait_frame, "modulate:a", 1.0, 0.25)
	tw.tween_property(_portrait_frame, "position:x", _portrait_frame.position.x + 18, 0.25).set_trans(Tween.TRANS_SINE)
