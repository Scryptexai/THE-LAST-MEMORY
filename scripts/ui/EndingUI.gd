extends Control
## EndingUI — layar salah satu dari 4 ending + statistik + navigasi
## (lanjut menjelajah / menu utama / permainan baru).

var _title: Label
var _art: Label
var _desc: RichTextLabel
var _stats: Label
var _current_ending: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	SignalBus.ending_triggered.connect(_on_ending)


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.12, 1.0)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.06, 0.1, 0.18, 0.97), ThemeFactory.ACCENT, 3, 16))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	var over := Label.new()
	over.text = "✦ TAMAT ✦"
	over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(over, 16, ThemeFactory.ACCENT_LIGHT, true)
	root.add_child(over)
	_art = Label.new()
	_art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(_art, 54, ThemeFactory.CREAM)
	root.add_child(_art)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(_title, 40, ThemeFactory.PASTEL_YELLOW, true)
	root.add_child(_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 200)
	root.add_child(scroll)
	_desc = RichTextLabel.new()
	_desc.bbcode_enabled = true
	_desc.fit_content = true
	_desc.scroll_active = false
	_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desc.add_theme_font_override("normal_font", ThemeFactory.body_font(17))
	_desc.add_theme_color_override("default_color", ThemeFactory.CREAM)
	scroll.add_child(_desc)
	_stats = Label.new()
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(_stats, 14, ThemeFactory.PASTEL_BLUE)
	root.add_child(_stats)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	_add_btn(row, "🔄 Jelajahi Lagi", _on_explore)
	_add_btn(row, "🏠 Menu Utama", _on_menu)
	_add_btn(row, "✨ Cerita Baru", _on_new)
	_add_btn(row, "🕯 Ruang Memori", _on_memory)


func _add_btn(parent: Container, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	ThemeFactory.style_button(b, 16)
	b.pressed.connect(cb)
	parent.add_child(b)


func _on_ending(ending_id: String) -> void:
	_current_ending = ending_id
	var dm := DataManager
	var gm := GameManager
	var im := InvestigationManager
	var rm := RelationshipManager
	var sm := SaveManager
	var e: Dictionary = dm.get_ending(ending_id)
	_art.text = str(e.get("art", "🌅"))
	if dm.language == "en" and str(e.get("title_en", "")) != "":
		_title.text = str(e["title_en"])
	else:
		_title.text = str(e.get("title", ending_id))
	var body: String = str(e.get("description_en", "")) if dm.language == "en" and str(e.get("description_en", "")) != "" else str(e.get("description", ""))
	_desc.text = body
	var lines: Array = dm.epilogue_lines()
	if not lines.is_empty():
		_desc.text += "\n\n[color=#FBBF24][b]— %s —[/b][/color]" % dm.tr_key("ending_epilogue")
		for ln in lines:
			var l: Dictionary = ln
			_desc.text += "\n%s [b]%s[/b] — %s" % [str(l["icon"]), str(l["name"]), str(l["text"])]
	_desc.text += _decision_trail(dm)
	var prog: Dictionary = im.clue_progress()
	_stats.text = "Petunjuk %d/%d   ·   Deduksi %d/4   ·   Rara 💛%d   Harto 💛%d   Mira 💛%d\nWaktu %s   ·   Pilihan %d   ·   Ending %d/4   \u00b7   \u2605 %d%%" % [
		prog["found"], prog["total"], (im.deductions_solved as Array).size(),
		rm.get_value("rara"), rm.get_value("pak_harto"), rm.get_value("mira"),
		MathUtils.format_playtime(sm.playtime), (DialogueManager.history as Array).size(),
		(gm.endings_seen as Array).size(), gm.completion_percent()]
	SignalBus.music_requested.emit(str(e.get("music", "music_ending")))


## Jejak keputusan kunci perjalanan ini + perbandingan dengan perjalanan sebelumnya.
func _decision_trail(dm: Node) -> String:
	var sm := SaveManager
	var gm := GameManager
	var picked: Dictionary = {}
	for h in DialogueManager.history:
		var hd: Dictionary = h
		picked[str(hd.get("node", ""))] = int(hd.get("choice", -1))
	var out: String = ""
	for d in dm.decisions:
		var dd: Dictionary = d
		var node: String = str(dd.get("node", ""))
		if not picked.has(node):
			continue
		var idx: String = str(picked[node])
		var opts: Dictionary = dd.get("options", {})
		var o: Dictionary = opts.get(idx, {})
		var label: String = str(dd.get("label_en", dd.get("label", ""))) if dm.language == "en" else str(dd.get("label", ""))
		var otext: String = str(o.get("text_en", o.get("text", "?"))) if dm.language == "en" else str(o.get("text", "?"))
		var tally: Dictionary = sm.choice_tally(node)
		var total: int = 0
		for k in tally.keys():
			total += int(tally[k])
		var pct: String = ""
		if total >= 2:
			pct = "  [color=#93C5FD](%d%% %s)[/color]" % [int(round(100.0 * float(tally.get(idx, 0)) / float(total))), dm.tr_key("ending_trail_pct")]
		out += "\n%s [b]%s[/b] — %s%s" % [str(dd.get("icon", "•")), label, otext, pct]
	if out == "":
		return ""
	var head: String = "\n\n[color=#FBBF24][b]— %s —[/b][/color]" % dm.tr_key("ending_trail")
	# Petunjuk ending yang belum dibuka.
	var missing: int = dm.endings.size() - (gm.endings_seen as Array).size()
	if missing > 0:
		out += "\n\n[i]%s[/i]" % dm.tr_key("ending_trail_more").format({"n": missing})
	return head + out


func _on_explore() -> void:
	# Kembali ke sesaat sebelum pilihan akhir.
	var gm := GameManager
	if gm.has_method("restore_pre_ending"):
		gm.restore_pre_ending()


func _on_menu() -> void:
	var main := get_tree().current_scene
	if main and main.has_method("quit_to_menu"):
		main.quit_to_menu()


func _on_new() -> void:
	var main := get_tree().current_scene
	if main and main.has_method("start_new_game"):
		main.start_new_game()


func _on_memory() -> void:
	var main := get_tree().current_scene
	if main and main.has_method("quit_to_menu"):
		main.quit_to_menu()
	await get_tree().process_frame
	var ui := get_tree().get_first_node_in_group("ui_layer")
	if ui and (ui as Node).has_method("get_screen"):
		var menu := (ui as Node).call("get_screen", "main_menu") as Control
		if menu and menu.has_method("open_memory"):
			menu.call("open_memory")
