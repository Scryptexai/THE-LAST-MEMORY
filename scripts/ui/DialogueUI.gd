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


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	var bus := SignalBus
	bus.dialogue_node_shown.connect(_on_node_shown)
	bus.dialogue_finished.connect(_on_dialogue_finished)
	visibility_changed.connect(_on_visibility)


func _build() -> void:
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
	_text_label.add_theme_font_override("normal_font", ThemeFactory.body_font(19))
	_text_label.add_theme_font_override("bold_font", ThemeFactory.body_font(19))
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
	_make_click_through(_panel)


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


func _on_dialogue_finished(_dlg: String, _last: String) -> void:
	_typing = false


func _on_node_shown(node_id: String) -> void:
	_current_node = node_id
	var dm := DataManager
	var dlgm := DialogueManager
	var node: Dictionary = dm.get_dialogue(node_id)
	# Warna panel berbeda untuk kilas balik.
	if bool(node.get("memory", false)):
		_panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.25, 0.16, 0.06, 0.95), ThemeFactory.PASTEL_YELLOW, 2, 12))
		_name_label.text = "◈ %s  ·  1983" % str(node.get("speaker", "???"))
	else:
		_panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.05, 0.1, 0.19, 0.94)))
		_name_label.text = str(node.get("speaker", "???"))
	_full_text = dm.localized(node)
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
			b.text = label_text
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			ThemeFactory.style_button(b, 16)
			b.pressed.connect(_on_choice_pressed.bind(i))
			_choice_box.add_child(b)


func _relationship_preview(choice: Dictionary, dm: Node) -> String:
	# Tampilkan pratinjau jujur efek hubungan (ala Life is Strange).
	var parts: Array = []
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
	if not visible or not _typing:
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
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT):
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
