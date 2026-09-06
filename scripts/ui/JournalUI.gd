extends Control
## JournalUI — buku harian Ardi: tab Catatan, Tokoh, dan Linimasa.
## Terisi otomatis dari clue, dialog, dan deduksi.

var _notes_list: VBoxContainer
var _chars_list: VBoxContainer
var _timeline_list: VBoxContainer
var _moments_list: VBoxContainer
var _ach_list: VBoxContainer
var _photos_box: VBoxContainer
var _choices_list: VBoxContainer
var _memories_list: VBoxContainer
var _quests_list: VBoxContainer
var _export_btn: Button
var _tabs: TabContainer
var _stats_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	visibility_changed.connect(_on_visibility_refresh)
	SignalBus.journal_updated.connect(_on_visibility_refresh)


func _build() -> void:
	add_child(ThemeFactory.dim_layer(0.6))
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 560)
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style())
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "📓 Jurnal Ardi"
	ThemeFactory.style_label(title, 24, ThemeFactory.PASTEL_YELLOW, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_export_btn = Button.new()
	ThemeFactory.style_button(_export_btn, 14)
	_export_btn.pressed.connect(_on_export)
	header.add_child(_export_btn)
	var close_btn := Button.new()
	close_btn.text = "✕"
	ThemeFactory.style_button(close_btn, 16)
	close_btn.pressed.connect(func() -> void: GameManager.change_state("gameplay"))
	header.add_child(close_btn)
	_stats_label = Label.new()
	ThemeFactory.style_label(_stats_label, 14, ThemeFactory.PASTEL_BLUE)
	root.add_child(_stats_label)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_tabs)
	_notes_list = _make_tab("Catatan")
	_chars_list = _make_tab("Tokoh")
	_timeline_list = _make_tab("Linimasa")
	_moments_list = _make_tab("Momen")
	_ach_list = _make_tab("Pencapaian")
	_photos_box = _make_tab("Foto")
	_choices_list = _make_tab("Pilihan")
	_memories_list = _make_tab("Kenangan")
	_quests_list = _make_tab("Tugas")


func _make_tab(tab_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	scroll.add_child(box)
	return box


func _on_export() -> void:
	var dm := DataManager
	var path: String = JournalExporter.export_markdown()
	if path == "":
		SignalBus.toast_requested.emit(dm.tr_key("journal_export_fail"), "system")
		return
	SignalBus.sfx_requested.emit("sfx_clue_found")
	SignalBus.toast_requested.emit(dm.tr_key("journal_export_ok").format({"file": path.get_file()}), "system")
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(path), false)


func refresh() -> void:
	_export_btn.text = DataManager.tr_key("journal_export")
	_update_stats()
	_refresh_notes()
	_refresh_characters()
	_refresh_timeline()
	_refresh_moments()
	_refresh_achievements()
	_refresh_photos()
	_refresh_choices()
	_refresh_memories()
	_refresh_quests()


## Tab Tugas: tujuan utama + tugas sampingan (quests.json) dengan progres langkah.
func _refresh_quests() -> void:
	for c in _quests_list.get_children():
		c.queue_free()
	var dm := DataManager
	var gm := GameManager
	var main_box := PanelContainer.new()
	main_box.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.16, 0.2, 0.12, 0.85), ThemeFactory.PASTEL_YELLOW, 1, 8))
	_quests_list.add_child(main_box)
	var mv := VBoxContainer.new()
	main_box.add_child(mv)
	var mt := Label.new()
	ThemeFactory.style_label(mt, 16, ThemeFactory.PASTEL_YELLOW, true)
	mt.text = "🎯 " + dm.tr_key("quests_main")
	mv.add_child(mt)
	var mb := Label.new()
	ThemeFactory.style_label(mb, 14, Color(0.92, 0.92, 0.92))
	mb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mb.text = gm.objective_text()
	mv.add_child(mb)
	var shown: int = 0
	for q in dm.quests:
		var qd: Dictionary = q
		var st: Dictionary = gm.quest_status(qd)
		if str(st["state"]) == "hidden":
			continue
		shown += 1
		var done: bool = str(st["state"]) == "done"
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", ThemeFactory.panel_style(
			Color(0.08, 0.12, 0.2, 0.75), Color(0.45, 0.75, 0.45, 0.8) if done else Color(0.3, 0.35, 0.45, 0.6), 1, 8))
		_quests_list.add_child(card)
		var v := VBoxContainer.new()
		card.add_child(v)
		var t := Label.new()
		ThemeFactory.style_label(t, 16, Color(0.6, 0.9, 0.6) if done else Color(0.95, 0.95, 0.95), true)
		var qname: String = str(qd.get("name_en", qd.get("name", ""))) if dm.language == "en" else str(qd.get("name", ""))
		var loc_name: String = str((dm.get_scene_data(str(qd.get("location", ""))) as Dictionary).get("name", ""))
		t.text = "%s %s%s  %s" % [str(qd.get("icon", "•")), qname, ("  ✔" if done else ""), ("· " + loc_name if loc_name != "" else "")]
		v.add_child(t)
		var steps: Array = qd.get("steps", [])
		for i in steps.size():
			var s: Dictionary = steps[i]
			var sl := Label.new()
			var step_ok: bool = done or i < int(st["step_done"])
			ThemeFactory.style_label(sl, 13, Color(0.55, 0.75, 0.55) if step_ok else Color(0.8, 0.8, 0.85))
			sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var stext: String = str(s.get("text_en", s.get("text", ""))) if dm.language == "en" else str(s.get("text", ""))
			var extra: String = ""
			if int(st["count_total"]) > 0:
				extra = "  (%d/%d)" % [int(st["count"]), int(st["count_total"])]
			sl.text = ("   ☑ " if step_ok else "   ☐ ") + stext + extra
			v.add_child(sl)
	if shown == 0:
		_quests_list.add_child(_empty_label(dm.tr_key("quests_empty")))


## Album kilas balik 1983: kenangan yang sudah dialami bisa diputar ulang.
func _refresh_memories() -> void:
	var dm := DataManager
	var gm := GameManager
	for c in _memories_list.get_children():
		c.queue_free()
	var roots: Array = dm.memory_roots()
	var seen: int = 0
	for nid in roots:
		if bool(gm.get_flag("memseen_" + str(nid), false)):
			seen += 1
	var head := Label.new()
	head.text = dm.tr_key("journal_memories_head").format({"n": seen, "t": roots.size()})
	ThemeFactory.style_label(head, 16, ThemeFactory.PASTEL_YELLOW, true)
	_memories_list.add_child(head)
	for nid in roots:
		var node: Dictionary = dm.get_dialogue(str(nid))
		var known: bool = bool(gm.get_flag("memseen_" + str(nid), false))
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.22, 0.15, 0.07, 0.9) if known else Color(0.1, 0.12, 0.18, 0.8), Color(0.85, 0.65, 0.3, 0.6) if known else Color(0.4, 0.4, 0.45, 0.4), 1, 6))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		p.add_child(hb)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		var nm := Label.new()
		nm.text = ("◈ %s · 1983" % str(node.get("speaker", "???"))) if known else "◈ ??? · 1983"
		ThemeFactory.style_label(nm, 16, ThemeFactory.PASTEL_YELLOW if known else Color(0.55, 0.55, 0.6), true)
		vb.add_child(nm)
		var t := Label.new()
		var full: String = dm.localized(node)
		t.text = (full.substr(0, 90) + ("…" if full.length() > 90 else "")) if known else dm.tr_key("journal_memory_locked")
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ThemeFactory.style_label(t, 14, ThemeFactory.CREAM if known else Color(0.6, 0.6, 0.65))
		vb.add_child(t)
		if known:
			var b := Button.new()
			b.text = dm.tr_key("journal_memory_replay")
			ThemeFactory.style_button(b, 14)
			b.pressed.connect(_on_replay_memory.bind(str(nid)))
			hb.add_child(b)
		_memories_list.add_child(p)


func _on_replay_memory(node_id: String) -> void:
	SignalBus.sfx_requested.emit("sfx_memory")
	GameManager.change_state("gameplay")
	DialogueManager.start_dialogue(node_id)


## Riwayat pilihan dialog (terbaru di atas) + waktu bermain saat memilih.
func _refresh_choices() -> void:
	var dlgm := DialogueManager
	var dm := DataManager
	for c in _choices_list.get_children():
		c.queue_free()
	var hist: Array = (dlgm.history as Array)
	if hist.is_empty():
		_choices_list.add_child(_empty_label(dm.tr_key("journal_choices_empty")))
		return
	var head := Label.new()
	head.text = dm.tr_key("journal_choices_head").format({"n": hist.size()})
	ThemeFactory.style_label(head, 16, ThemeFactory.PASTEL_YELLOW, true)
	_choices_list.add_child(head)
	for i in range(hist.size() - 1, -1, -1):
		var h: Dictionary = hist[i]
		var node: Dictionary = dm.get_dialogue(str(h.get("node", "")))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var tm := Label.new()
		tm.text = MathUtils.format_playtime(float(h.get("time", 0.0)))
		tm.custom_minimum_size = Vector2(70, 0)
		ThemeFactory.style_label(tm, 14, ThemeFactory.ACCENT_LIGHT, true)
		hb.add_child(tm)
		var t := Label.new()
		t.text = "%s: \"%s\"" % [str(node.get("speaker", "?")), str(h.get("text", ""))]
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeFactory.style_label(t, 15, ThemeFactory.CREAM)
		hb.add_child(t)
		_choices_list.add_child(hb)


func _refresh_notes() -> void:
	var im := InvestigationManager
	for c in _notes_list.get_children():
		c.queue_free()
	if (im.journal_notes as Array).is_empty():
		_notes_list.add_child(_empty_label("Belum ada catatan."))
		return
	var notes: Array = (im.journal_notes as Array).duplicate()
	notes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("order", 0)) > int(b.get("order", 0)))
	for n in notes:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.1, 0.15, 0.26, 0.9), Color(0.5, 0.55, 0.65, 0.5), 1, 6))
		var vb := VBoxContainer.new()
		p.add_child(vb)
		var src := Label.new()
		src.text = str((n as Dictionary).get("source", ""))
		ThemeFactory.style_label(src, 12, ThemeFactory.ACCENT_LIGHT)
		vb.add_child(src)
		var t := Label.new()
		t.text = str((n as Dictionary).get("text", ""))
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ThemeFactory.style_label(t, 15, ThemeFactory.CREAM)
		vb.add_child(t)
		_notes_list.add_child(p)


func _refresh_characters() -> void:
	var dm := DataManager
	var im := InvestigationManager
	var rm := RelationshipManager
	for c in _chars_list.get_children():
		c.queue_free()
	for char_id in dm.characters.keys():
		var cdata: Dictionary = dm.characters[char_id]
		var met: bool = str(char_id) in im.characters_met
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.1, 0.15, 0.26, 0.9), Color(0.5, 0.55, 0.65, 0.5), 1, 6))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		p.add_child(hb)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		var nm := Label.new()
		nm.text = str(cdata.get("name", char_id)) if met else "??? (belum dikenal)"
		ThemeFactory.style_label(nm, 18, ThemeFactory.PASTEL_YELLOW if met else Color(0.6, 0.6, 0.65), true)
		vb.add_child(nm)
		var desc := Label.new()
		desc.text = str(cdata.get("description", "")) if met else "Seseorang yang belum kau temui di Kota Tua Pesisir."
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ThemeFactory.style_label(desc, 14, ThemeFactory.CREAM)
		vb.add_child(desc)
		if met and str(char_id) != "ardi" and str(char_id) != "nenek":
			var rel := Label.new()
			rel.text = "💛 %s (%d/%d)" % [rm.level_label(str(char_id)), rm.get_value(str(char_id)), rm.get_max(str(char_id))]
			ThemeFactory.style_label(rel, 14, ThemeFactory.PASTEL_PINK)
			vb.add_child(rel)
			var likes: String = str(cdata.get("likes", ""))
			if likes != "":
				var gl := Label.new()
				gl.text = "Hadiah kesukaan: " + likes
				gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				ThemeFactory.style_label(gl, 14, ThemeFactory.PASTEL_BLUE)
				vb.add_child(gl)
		_chars_list.add_child(p)


func _refresh_timeline() -> void:
	var im := InvestigationManager
	for c in _timeline_list.get_children():
		c.queue_free()
	if (im.timeline_events as Array).is_empty():
		_timeline_list.add_child(_empty_label("Linimasa masih kosong."))
		return
	var events: Array = (im.timeline_events as Array).duplicate()
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("order", 0)) < int(b.get("order", 0)))
	for e in events:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var year := Label.new()
		year.text = str((e as Dictionary).get("year", "?"))
		year.custom_minimum_size = Vector2(70, 0)
		ThemeFactory.style_label(year, 16, ThemeFactory.ACCENT_LIGHT, true)
		hb.add_child(year)
		var dot := Label.new()
		dot.text = "●"
		ThemeFactory.style_label(dot, 14, ThemeFactory.ACCENT)
		hb.add_child(dot)
		var t := Label.new()
		t.text = str((e as Dictionary).get("text", ""))
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeFactory.style_label(t, 15, ThemeFactory.CREAM)
		hb.add_child(t)
		_timeline_list.add_child(hb)


func _empty_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	ThemeFactory.style_label(l, 15, Color(0.75, 0.75, 0.8))
	return l


func _update_stats() -> void:
	var im := InvestigationManager
	var sm := SaveManager
	var prog: Dictionary = im.clue_progress()
	_stats_label.text = "⏱ %s    🔍 %d/%d    🧩 %d/4    💡 %d    \u2605 %d%%" % [
		MathUtils.format_playtime(sm.playtime), prog["found"], prog["total"],
		(im.deductions_solved as Array).size(), im.hints_left, GameManager.completion_percent()]


func _refresh_moments() -> void:
	var dm := DataManager
	var im := InvestigationManager
	for c in _moments_list.get_children():
		c.queue_free()
	for mid in dm.moments.keys():
		var m: Dictionary = dm.moments[mid]
		var taken: bool = str(mid) in im.moments_taken
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.1, 0.15, 0.26, 0.9), Color(0.5, 0.55, 0.65, 0.5), 1, 6))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		p.add_child(hb)
		var thumb := TextureRect.new()
		thumb.custom_minimum_size = Vector2(220, 124)
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if taken:
			var img := Image.load_from_file("user://moments/%s.png" % str(mid))
			if img != null and not img.is_empty():
				thumb.texture = ImageTexture.create_from_image(img)
		hb.add_child(thumb)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		var nm := Label.new()
		nm.text = ("📷 " + str(m.get("name", mid))) if taken else "❔ ???"
		ThemeFactory.style_label(nm, 17, ThemeFactory.PASTEL_YELLOW if taken else Color(0.6, 0.6, 0.65), true)
		vb.add_child(nm)
		var hint := Label.new()
		if taken:
			hint.text = str((dm.get_scene_data(str(m.get("location", ""))) as Dictionary).get("name", ""))
		else:
			hint.text = str(m.get("hint", ""))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ThemeFactory.style_label(hint, 14, ThemeFactory.CREAM)
		vb.add_child(hint)
		_moments_list.add_child(p)


func _refresh_achievements() -> void:
	var dm := DataManager
	var am := AchievementManager
	for c in _ach_list.get_children():
		c.queue_free()
	var got: int = 0
	for aid in dm.achievements.keys():
		if am.is_unlocked(str(aid)):
			got += 1
	var head := Label.new()
	head.text = "🏆 %d/%d terbuka" % [got, dm.achievements.size()]
	ThemeFactory.style_label(head, 16, ThemeFactory.PASTEL_YELLOW, true)
	_ach_list.add_child(head)
	for aid in dm.achievements.keys():
		var a: Dictionary = dm.achievements[aid]
		var un: bool = am.is_unlocked(str(aid))
		var nm: String = str(a.get("name_en", "")) if dm.language == "en" and str(a.get("name_en", "")) != "" else str(a.get("name", aid))
		var ds: String = str(a.get("desc_en", "")) if dm.language == "en" and str(a.get("desc_en", "")) != "" else str(a.get("desc", ""))
		var l := Label.new()
		l.text = ("🏆 " if un else "🔒 ") + nm + "\n" + ds
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ThemeFactory.style_label(l, 15, ThemeFactory.PASTEL_YELLOW if un else Color(0.55, 0.55, 0.6))
		_ach_list.add_child(l)


func _refresh_photos() -> void:
	var pm := PhotoManager
	pm.rescan()
	for c in _photos_box.get_children():
		c.queue_free()
	var head := Label.new()
	head.text = "📷 %d foto" % pm.photo_count()
	ThemeFactory.style_label(head, 16, ThemeFactory.PASTEL_BLUE, true)
	_photos_box.add_child(head)
	if pm.photo_count() == 0:
		var empty := Label.new()
		empty.text = DataManager.tr_key("photo_empty")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ThemeFactory.style_label(empty, 15, Color(0.7, 0.7, 0.75))
		_photos_box.add_child(empty)
		return
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_photos_box.add_child(grid)
	var shown: int = 0
	for f in pm.photos:
		if shown >= PhotoManager.MAX_THUMBS:
			break
		var img := Image.load_from_file(pm.photo_path(str(f)))
		if img == null or img.is_empty():
			continue
		var thumb := TextureRect.new()
		thumb.texture = ImageTexture.create_from_image(img)
		thumb.custom_minimum_size = Vector2(170, 100)
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb.tooltip_text = str(f)
		grid.add_child(thumb)
		shown += 1
	if pm.photo_count() > shown:
		var more := Label.new()
		more.text = "+%d lainnya di user://photos" % (pm.photo_count() - shown)
		ThemeFactory.style_label(more, 14, Color(0.7, 0.7, 0.75))
		_photos_box.add_child(more)


func _on_visibility_refresh() -> void:
	if visible:
		refresh()
