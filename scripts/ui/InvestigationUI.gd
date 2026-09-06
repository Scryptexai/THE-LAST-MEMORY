extends Control
## InvestigationUI — daftar petunjuk + papan deduksi (hubung-hubungkan clue)
## + kesimpulan terpecahkan + tombol hint.

const MAX_SELECTED := 4

const TYPE_ICONS := {"document": "📄", "photo": "📷", "testimony": "🗣", "object": "🔑", "audio": "🎙"}

var _clue_list: VBoxContainer
var _detail_name: Label
var _detail_body: RichTextLabel
var _selected_label: Label
var _result_label: Label
var _solved_list: VBoxContainer
var _guide_list: VBoxContainer
var _progress_label: Label
var _hint_label: Label
var _hint_btn: Button
var _selected: Array = []
var _board: EvidenceBoard


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	visibility_changed.connect(_on_visibility_refresh)
	var bus := SignalBus
	bus.clue_found.connect(_on_clue_found_refresh)
	bus.deduction_solved.connect(_on_ded_solved_refresh)


func _build() -> void:
	add_child(ThemeFactory.dim_layer(0.6))
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1080, 640)
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style())
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)
	# Header.
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "🔍 INVESTIGASI — Kecelakaan Kereta 1983"
	ThemeFactory.style_label(title, 24, ThemeFactory.PASTEL_YELLOW, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_progress_label = Label.new()
	ThemeFactory.style_label(_progress_label, 16, ThemeFactory.CREAM)
	header.add_child(_progress_label)
	_hint_btn = Button.new()
	ThemeFactory.style_button(_hint_btn, 15)
	_hint_btn.pressed.connect(_on_hint)
	header.add_child(_hint_btn)
	var close_btn := Button.new()
	close_btn.text = "✕"
	ThemeFactory.style_button(close_btn, 16)
	close_btn.pressed.connect(func() -> void: GameManager.change_state("gameplay"))
	header.add_child(close_btn)
	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeFactory.style_label(_hint_label, 14, ThemeFactory.PASTEL_BLUE)
	root.add_child(_hint_label)
	# Kolom: clue | deduksi.
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)
	# Kiri: daftar clue.
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(330, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	var lh := Label.new()
	lh.text = "Petunjuk"
	ThemeFactory.style_label(lh, 18, ThemeFactory.ACCENT_LIGHT, true)
	left.add_child(lh)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_clue_list = VBoxContainer.new()
	_clue_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clue_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_clue_list)
	# Tengah: detail clue.
	var mid := VBoxContainer.new()
	mid.custom_minimum_size = Vector2(300, 0)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(mid)
	_detail_name = Label.new()
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeFactory.style_label(_detail_name, 18, ThemeFactory.PASTEL_YELLOW, true)
	mid.add_child(_detail_name)
	_detail_body = RichTextLabel.new()
	_detail_body.bbcode_enabled = true
	_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_body.add_theme_font_override("normal_font", ThemeFactory.body_font(15))
	_detail_body.add_theme_color_override("default_color", ThemeFactory.CREAM)
	mid.add_child(_detail_body)
	var bh := Label.new()
	bh.text = "🧵 Papan Benang Merah"
	ThemeFactory.style_label(bh, 15, ThemeFactory.PASTEL_PINK, true)
	mid.add_child(bh)
	_board = EvidenceBoard.new()
	_board.custom_minimum_size = Vector2(300, 230)
	_board.clue_clicked.connect(_on_clue_toggled)
	mid.add_child(_board)
	# Kanan: papan deduksi.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	cols.add_child(right)
	var rh := Label.new()
	rh.text = "Papan Deduksi"
	ThemeFactory.style_label(rh, 18, ThemeFactory.ACCENT_LIGHT, true)
	right.add_child(rh)
	var info := Label.new()
	info.text = "Pilih 2–4 petunjuk, lalu hubungkan."
	ThemeFactory.style_label(info, 13, Color(0.8, 0.8, 0.85))
	right.add_child(info)
	_selected_label = Label.new()
	_selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeFactory.style_label(_selected_label, 14, ThemeFactory.PASTEL_PINK)
	right.add_child(_selected_label)
	var link_btn := Button.new()
	link_btn.text = "🔗 Hubungkan Clue"
	ThemeFactory.style_button(link_btn, 17)
	link_btn.pressed.connect(_on_link)
	right.add_child(link_btn)
	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeFactory.style_label(_result_label, 14, ThemeFactory.PASTEL_YELLOW)
	right.add_child(_result_label)
	var gh := Label.new()
	gh.text = "🧩 Teka-teki"
	ThemeFactory.style_label(gh, 16, ThemeFactory.PASTEL_BLUE, true)
	right.add_child(gh)
	_guide_list = VBoxContainer.new()
	_guide_list.add_theme_constant_override("separation", 2)
	right.add_child(_guide_list)
	var sh := Label.new()
	sh.text = "Kesimpulan Terpecahkan"
	ThemeFactory.style_label(sh, 16, ThemeFactory.GOOD, true)
	right.add_child(sh)
	var scroll2 := ScrollContainer.new()
	scroll2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll2)
	_solved_list = VBoxContainer.new()
	_solved_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_solved_list.add_theme_constant_override("separation", 4)
	scroll2.add_child(_solved_list)


func refresh() -> void:
	var dm := DataManager
	var im := InvestigationManager
	_selected = _selected.filter(func(c: Variant) -> bool: return str(c) in im.clues_found)
	_board.selected = _selected
	_board.rebuild()
	# Daftar clue.
	for c in _clue_list.get_children():
		c.queue_free()
	if (im.clues_found as Array).is_empty():
		var empty := Label.new()
		empty.text = dm.tr_key("invest_empty")
		ThemeFactory.style_label(empty, 14, Color(0.75, 0.75, 0.8))
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_clue_list.add_child(empty)
	else:
		for clue_id in im.clues_found:
			var clue: Dictionary = dm.get_clue(str(clue_id))
			var b := Button.new()
			b.toggle_mode = true
			b.button_pressed = str(clue_id) in _selected
			var icon: String = TYPE_ICONS.get(str(clue.get("type", "document")), "📄")
			b.text = "%s %s" % [icon, str(clue.get("name", clue_id))]
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			ThemeFactory.style_button(b, 14)
			if b.button_pressed:
				b.add_theme_color_override("font_color", ThemeFactory.ACCENT_LIGHT)
			b.pressed.connect(_on_clue_toggled.bind(str(clue_id)))
			_clue_list.add_child(b)
	var prog: Dictionary = im.clue_progress()
	_progress_label.text = dm.tr_key("invest_progress").format({"f": prog["found"], "t": prog["total"]})
	_hint_btn.text = dm.tr_key("invest_hint").format({"n": im.hints_left})
	_hint_btn.disabled = im.hints_left <= 0
	_update_selected_label(dm)
	# Panduan teka-teki (siluet + progres + hint bertahap).
	for c in _guide_list.get_children():
		c.queue_free()
	for ded_id in dm.deductions.keys():
		if ded_id in im.deductions_solved:
			continue
		var ded: Dictionary = dm.deductions[ded_id]
		var req: Array = ded.get("required_clues", [])
		var found_n: int = 0
		for rc in req:
			if str(rc) in im.clues_found:
				found_n += 1
		var locked: bool = false
		for pre in ded.get("requires_deductions", []):
			if not (str(pre) in im.deductions_solved):
				locked = true
		var gl := Label.new()
		gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if locked:
			gl.text = "🔒 ??? — pecahkan kesimpulan sebelumnya dulu."
			ThemeFactory.style_label(gl, 13, Color(0.6, 0.6, 0.65))
		elif found_n == 0:
			gl.text = "❔ Teka-teki (%d petunjuk) — petunjuknya belum ditemukan." % req.size()
			ThemeFactory.style_label(gl, 13, Color(0.75, 0.75, 0.8))
		else:
			gl.text = "❔ %d/%d petunjuk — %s" % [found_n, req.size(), str(ded.get("hint", ""))]
			ThemeFactory.style_label(gl, 13, ThemeFactory.PASTEL_BLUE)
		_guide_list.add_child(gl)
	# Kesimpulan.
	for c in _solved_list.get_children():
		c.queue_free()
	if (im.deductions_solved as Array).is_empty():
		var none := Label.new()
		none.text = dm.tr_key("invest_no_deduction")
		ThemeFactory.style_label(none, 13, Color(0.75, 0.75, 0.8))
		_solved_list.add_child(none)
	else:
		for ded_id in im.deductions_solved:
			var ded: Dictionary = dm.get_deduction(str(ded_id))
			var p := PanelContainer.new()
			p.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.08, 0.2, 0.14, 0.9), ThemeFactory.GOOD, 1, 6))
			var vb := VBoxContainer.new()
			p.add_child(vb)
			var t := Label.new()
			t.text = "✓ " + str(ded.get("title", ded_id))
			ThemeFactory.style_label(t, 15, ThemeFactory.GOOD, true)
			vb.add_child(t)
			var concl := Label.new()
			concl.text = str(ded.get("conclusion", ""))
			concl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ThemeFactory.style_label(concl, 13, ThemeFactory.CREAM)
			vb.add_child(concl)
			_solved_list.add_child(p)
	if _detail_name.text == "":
		_detail_name.text = dm.tr_key("invest_select_clue")


func _on_clue_toggled(clue_id: String) -> void:
	var dm := DataManager
	SignalBus.sfx_requested.emit("sfx_dialogue_click")
	# Toggle seleksi + tampilkan detail.
	if clue_id in _selected:
		_selected.erase(clue_id)
	else:
		if _selected.size() >= MAX_SELECTED:
			_selected.pop_front()
		_selected.append(clue_id)
	var clue: Dictionary = dm.get_clue(clue_id)
	_detail_name.text = str(clue.get("name", clue_id))
	var loc_name: String = str((dm.get_scene_data(str(clue.get("found_in", ""))) as Dictionary).get("name", "?"))
	var rel: Array = clue.get("related_to", [])
	_detail_body.text = "[b]Jenis:[/b] %s\n[b]Ditemukan di:[/b] %s\n[b]Terkait:[/b] %s\n\n%s" % [
		str(clue.get("type", "")), loc_name, ", ".join(rel), str(clue.get("description", ""))]
	refresh_selection_visual()
	_update_selected_label(dm)


func refresh_selection_visual() -> void:
	_board.selected = _selected
	_board.rebuild()
	# Bangun ulang daftar agar status toggle sinkron.
	var keep_detail_name: String = _detail_name.text
	var keep_detail_body: String = _detail_body.text
	refresh()
	_detail_name.text = keep_detail_name
	_detail_body.text = keep_detail_body


func _update_selected_label(dm: Node) -> void:
	if _selected.is_empty():
		_selected_label.text = "Terpilih: —"
	else:
		var names: Array = []
		for c in _selected:
			names.append(str((dm.get_clue(str(c)) as Dictionary).get("name", c)))
		_selected_label.text = "Terpilih (%d): %s" % [_selected.size(), " + ".join(names)]


func _on_link() -> void:
	var dm := DataManager
	if _selected.size() < 2:
		_result_label.text = dm.tr_key("invest_need_two")
		return
	var im := InvestigationManager
	var res: Dictionary = im.try_deduction(_selected)
	if bool(res.get("solved", false)):
		var ded: Dictionary = dm.get_deduction(str(res["deduction_id"]))
		_result_label.text = "✓ %s — %s" % [str(ded.get("title", "")), str(ded.get("conclusion", ""))]
		_selected.clear()
	else:
		_result_label.text = "✗ " + str(res.get("reason", ""))
	refresh()


func _on_hint() -> void:
	var im := InvestigationManager
	var res: Dictionary = im.use_hint()
	_hint_label.text = "💡 " + str(res.get("text", ""))
	refresh()


func _on_visibility_refresh() -> void:
	if visible:
		refresh()


func _on_clue_found_refresh(_clue_id: String) -> void:
	_on_visibility_refresh()


func _on_ded_solved_refresh(_ded_id: String) -> void:
	_on_visibility_refresh()
