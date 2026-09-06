extends Control
## HUD — prompt interaksi, banner lokasi, objektif, tombol menu, toast,
## menu perjalanan (peta), dan overlay kilas balik.

var _prompt: PanelContainer
var _prompt_label: Label
var _banner: PanelContainer
var _banner_label: Label
var _objective_label: Label
var _toast_box: VBoxContainer
var _travel_panel: PanelContainer
var _travel_list: VBoxContainer
var _memory_overlay: ColorRect
var _memory_label: Label
var _banner_tween: Tween
var _hud_buttons: HBoxContainer
var _chapter_card: PanelContainer
var _chapter_label: Label
var _chapter_tween: Tween
var _compass: PanelContainer
var _compass_label: Label
var _compass_cd: float = 0.0
var _compass_target: Node3D = null
const ARROWS := ["▲", "◥", "▶", "◢", "▼", "◣", "◀", "◤"]
var _recap: PanelContainer
var _recap_body: RichTextLabel
var _recap_title: Label
var _recap_close: Button
var _recap_tween: Tween
var _memory_bars: Array = []  # 2 ColorRect letterbox
var _memory_tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	var bus := SignalBus
	bus.prompt_requested.connect(_on_prompt)
	bus.prompt_cleared.connect(_on_prompt_cleared)
	bus.location_changed.connect(_on_location)
	bus.objective_changed.connect(_on_objective)
	bus.toast_requested.connect(show_toast)
	bus.memory_flashback_started.connect(_on_memory_start)
	bus.memory_flashback_ended.connect(_on_memory_end)
	bus.chapter_changed.connect(_on_chapter)
	bus.relationship_changed.connect(_on_relationship)
	refresh_state()


func _build() -> void:
	_add_vignette()
	# --- Bar atas: objektif + tombol ---
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_top = 12
	top.offset_right = -16
	top.offset_bottom = 60
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	var obj_panel := PanelContainer.new()
	obj_panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.06, 0.12, 0.22, 0.75), Color(0.85, 0.48, 0.03, 0.6), 1, 8))
	obj_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(obj_panel)
	_objective_label = Label.new()
	ThemeFactory.style_label(_objective_label, 16, ThemeFactory.CREAM)
	obj_panel.add_child(_objective_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	_hud_buttons = HBoxContainer.new()
	_hud_buttons.add_theme_constant_override("separation", 8)
	top.add_child(_hud_buttons)
	_add_hud_button("🧭", "open_map", "Peta [M]")
	_add_hud_button("🔍", "open_investigation", "Clue [L]")
	_add_hud_button("🎒", "open_inventory", "Tas [I]")
	_add_hud_button("📓", "open_journal", "Jurnal [J]")
	_add_hud_button("⚙", "open_settings", "Opsi")
	_add_hud_button("📷", "photo_mode", "Foto [P]")
	# --- Kompas tujuan (di bawah bar atas) ---
	_compass = PanelContainer.new()
	_compass.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_compass.offset_left = -170
	_compass.offset_right = 170
	_compass.offset_top = 64
	_compass.offset_bottom = 96
	_compass.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.06, 0.12, 0.22, 0.7), ThemeFactory.PASTEL_BLUE, 1, 8))
	_compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compass.visible = false
	add_child(_compass)
	_compass_label = Label.new()
	_compass_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(_compass_label, 15, ThemeFactory.PASTEL_BLUE)
	_compass.add_child(_compass_label)
	# --- Banner lokasi (tengah atas) ---
	_banner = PanelContainer.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_left = -260
	_banner.offset_right = 260
	_banner.offset_top = 80
	_banner.offset_bottom = 150
	_banner.add_theme_stylebox_override("panel", ThemeFactory.panel_style())
	_banner.visible = false
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)
	_banner_label = Label.new()
	ThemeFactory.style_label(_banner_label, 30, ThemeFactory.PASTEL_YELLOW, true)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_label)
	# --- Kartu bab (tengah layar, muncul sesaat) ---
	_chapter_card = PanelContainer.new()
	_chapter_card.set_anchors_preset(Control.PRESET_CENTER)
	_chapter_card.offset_left = -320
	_chapter_card.offset_right = 320
	_chapter_card.offset_top = -70
	_chapter_card.offset_bottom = 70
	_chapter_card.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.04, 0.07, 0.14, 0.88), ThemeFactory.PASTEL_YELLOW, 2, 14))
	_chapter_card.visible = false
	_chapter_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_chapter_card)
	_chapter_label = Label.new()
	ThemeFactory.style_label(_chapter_label, 30, ThemeFactory.PASTEL_YELLOW, true)
	_chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chapter_card.add_child(_chapter_label)
	# --- Prompt interaksi (bawah tengah) ---
	_prompt = PanelContainer.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_left = -220
	_prompt.offset_right = 220
	_prompt.offset_top = -130
	_prompt.offset_bottom = -80
	_prompt.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.06, 0.12, 0.22, 0.85), ThemeFactory.ACCENT, 2, 10))
	_prompt.visible = false
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt)
	_prompt_label = Label.new()
	ThemeFactory.style_label(_prompt_label, 18, ThemeFactory.CREAM)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_child(_prompt_label)
	# --- Toast (kanan bawah) ---
	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_toast_box.offset_left = -420
	_toast_box.offset_top = -320
	_toast_box.offset_right = -16
	_toast_box.offset_bottom = -16
	_toast_box.add_theme_constant_override("separation", 6)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_box)
	# --- Panel perjalanan (tersembunyi) ---
	_travel_panel = PanelContainer.new()
	_travel_panel.set_anchors_preset(Control.PRESET_CENTER)
	_travel_panel.offset_left = -220
	_travel_panel.offset_right = 220
	_travel_panel.offset_top = -260
	_travel_panel.offset_bottom = 260
	_travel_panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style())
	_travel_panel.visible = false
	add_child(_travel_panel)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 8)
	_travel_panel.add_child(tv)
	var title := Label.new()
	ThemeFactory.style_label(title, 24, ThemeFactory.PASTEL_YELLOW, true)
	title.text = "🧭 Perjalanan"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tv.add_child(title)
	_travel_list = VBoxContainer.new()
	_travel_list.add_theme_constant_override("separation", 6)
	tv.add_child(_travel_list)
	var close_btn := Button.new()
	close_btn.text = "Tutup"
	ThemeFactory.style_button(close_btn, 16)
	close_btn.pressed.connect(func() -> void: _travel_panel.visible = false)
	tv.add_child(close_btn)
	# --- Kartu "Sebelumnya..." saat melanjutkan simpanan ---
	_recap = PanelContainer.new()
	_recap.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_recap.offset_left = 24
	_recap.offset_right = 444
	_recap.offset_top = -150
	_recap.offset_bottom = 150
	_recap.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.04, 0.07, 0.14, 0.92), ThemeFactory.PASTEL_YELLOW, 2, 12))
	_recap.visible = false
	add_child(_recap)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 6)
	_recap.add_child(rv)
	_recap_title = Label.new()
	ThemeFactory.style_label(_recap_title, 18, ThemeFactory.PASTEL_YELLOW, true)
	rv.add_child(_recap_title)
	_recap_body = RichTextLabel.new()
	_recap_body.bbcode_enabled = true
	_recap_body.fit_content = true
	_recap_body.scroll_active = false
	_recap_body.custom_minimum_size = Vector2(380, 0)
	_recap_body.add_theme_font_override("normal_font", ThemeFactory.body_font(14))
	_recap_body.add_theme_font_override("bold_font", ThemeFactory.body_font(14))
	_recap_body.add_theme_color_override("default_color", ThemeFactory.CREAM)
	rv.add_child(_recap_body)
	_recap_close = Button.new()
	ThemeFactory.style_button(_recap_close, 14)
	_recap_close.pressed.connect(_hide_recap)
	rv.add_child(_recap_close)
	# --- Overlay memori (sepia + label 1983) ---
	_memory_overlay = ColorRect.new()
	_memory_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_memory_overlay.color = Color(1, 1, 1, 1)
	_memory_overlay.visible = false
	_memory_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mem_sh := Shader.new()
	mem_sh.code = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
float rnd(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec4 src = texture(screen_tex, SCREEN_UV);
	float g = dot(src.rgb, vec3(0.3, 0.59, 0.11));
	vec3 sepia = vec3(g * 1.08, g * 0.9, g * 0.62);
	vec2 uv = UV - vec2(0.5);
	float vig = smoothstep(0.35, 0.95, length(uv) * 1.45);
	float grain = (rnd(UV * 900.0 + vec2(TIME * 7.0, TIME * 3.0)) - 0.5) * 0.09;
	vec3 col = mix(src.rgb, sepia + grain, strength);
	col = mix(col, col * (1.0 - vig * 0.75), strength);
	COLOR = vec4(col, 1.0);
}
"""
	var mem_mat := ShaderMaterial.new()
	mem_mat.shader = mem_sh
	mem_mat.set_shader_parameter("strength", 0.0)
	_memory_overlay.material = mem_mat
	add_child(_memory_overlay)
	# Letterbox sinematik (atas & bawah), meluncur masuk saat kilas balik.
	for i in 2:
		var bar := ColorRect.new()
		bar.color = Color(0.02, 0.02, 0.03, 1.0)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i == 0:
			bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
			bar.offset_bottom = 0
		else:
			bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			bar.offset_top = 0
		bar.visible = false
		add_child(bar)
		_memory_bars.append(bar)
	_memory_label = Label.new()
	ThemeFactory.style_label(_memory_label, 40, Color(1.0, 0.9, 0.6, 0.9), true)
	_memory_label.text = "— 1983 —"
	_memory_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_memory_label.offset_left = -200
	_memory_label.offset_right = 200
	_memory_label.offset_top = 150
	_memory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_memory_label.visible = false
	_memory_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_memory_label)


func _add_hud_button(icon: String, action: String, tooltip: String) -> void:
	var b := Button.new()
	b.text = "%s %s" % [icon, tooltip]
	b.tooltip_text = tooltip
	ThemeFactory.style_button(b, 14)
	b.pressed.connect(_on_hud_button.bind(action))
	_hud_buttons.add_child(b)


func _on_hud_button(action: String) -> void:
	var gm := GameManager
	SignalBus.sfx_requested.emit("sfx_dialogue_click")
	match action:
		"open_map":
			toggle_travel()
		"open_investigation":
			gm.change_state("investigation" if gm.state == "gameplay" else "gameplay")
		"open_inventory":
			gm.change_state("inventory" if gm.state == "gameplay" else "gameplay")
		"open_journal":
			gm.change_state("journal" if gm.state == "gameplay" else "gameplay")
		"photo_mode":
			gm.change_state("photo" if gm.state == "gameplay" else "gameplay")
		"open_settings":
			(get_parent() as CanvasLayer).get_parent()  # no-op aman
			SignalBus.ui_screen_requested.emit("settings")


# ---------- Kompas tujuan ----------

func _process(delta: float) -> void:
	var gm := GameManager
	if gm.state != "gameplay" or gm.hard_mode or _memory_overlay.visible:
		_compass.visible = false
		return
	_compass_cd -= delta
	if _compass_cd <= 0.0:
		_compass_cd = 0.5
		_compass_target = _pick_compass_target()
	if _compass_target == null or not is_instance_valid(_compass_target):
		_compass.visible = false
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		_compass.visible = false
		return
	var to: Vector3 = _compass_target.global_position - player.global_position
	to.y = 0.0
	var dist: float = to.length()
	if dist < 1.5:
		_compass.visible = false
		return
	var yaw: float = float(player.get("cam_yaw"))
	var fwd := Vector2(-sin(yaw), -cos(yaw))
	var dir := Vector2(to.x, to.z).normalized()
	var ang: float = atan2(fwd.x * dir.y - fwd.y * dir.x, fwd.dot(dir))  # + = kanan
	var idx: int = int(roundf(ang / (PI / 4.0))) % 8
	if idx < 0:
		idx += 8
	var nm: String = str(_compass_target.get("display_name"))
	_compass_label.text = "%s  %s  %dm" % [ARROWS[idx], nm, int(dist)]
	_compass.visible = true


## Target kompas: portal keluar bila objektif ada di lokasi lain; bila di lokasi ini,
## objek interaktif aktif terdekat yang masih menyimpan petunjuk belum ditemukan.
func _pick_compass_target() -> Node3D:
	var gm := GameManager
	var dm := DataManager
	var im := InvestigationManager
	var target_loc: String = dm.get_objective_location(gm.current_objective)
	if target_loc == "":
		return null
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return null
	var best: Node3D = null
	var best_d: float = INF
	for n in get_tree().get_nodes_in_group("interactable"):
		var obj := n as Node3D
		if obj == null:
			continue
		var d: float = obj.global_position.distance_to(player.global_position)
		if target_loc != gm.current_location:
			if str(obj.get("target_location")) != "__travel__":
				continue
		else:
			var cid: String = str(obj.get("clue_id"))
			if cid == "" or cid == "<null>" or im.has_clue(cid):
				continue
			if obj.has_method("_is_active") and not bool(obj.call("_is_active")):
				continue
		if d < best_d:
			best_d = d
			best = obj
	return best


# ---------- Refresh ----------

func refresh_state() -> void:
	var gm := GameManager
	var in_game: bool = gm.state in ["gameplay", "dialogue", "investigation", "inventory", "journal", "pause", "photo"]
	_hud_buttons.visible = in_game and gm.state != "photo"
	_objective_label.text = ("🕵 " if gm.hard_mode else "🎯 ") + gm.objective_text()
	if gm.state != "gameplay":
		_travel_panel.visible = false
		_on_prompt_cleared()
		if _recap and _recap.visible and gm.state in ["main_menu", "loading", "ending"]:
			_hide_recap()


func toggle_travel() -> void:
	_travel_panel.visible = not _travel_panel.visible
	if _travel_panel.visible:
		_rebuild_travel()


func _rebuild_travel() -> void:
	for c in _travel_list.get_children():
		c.queue_free()
	var dm := DataManager
	var gm := GameManager
	for scene_id in dm.scenes.keys():
		var data: Dictionary = dm.scenes[scene_id]
		var unlock_flag: String = str(data.get("unlock_flag", ""))
		if unlock_flag != "" and not bool(gm.get_flag(unlock_flag, false)):
			continue  # lokasi belum terbuka (mis. Makam Bukit setelah bab 3)
		var b := Button.new()
		var here: String = " 📍" if scene_id == gm.current_location else ""
		b.text = str(data.get("name", scene_id)) + here
		b.disabled = scene_id == gm.current_location
		ThemeFactory.style_button(b, 16)
		b.pressed.connect(_on_travel_to.bind(str(scene_id)))
		_travel_list.add_child(b)


func _on_travel_to(scene_id: String) -> void:
	_travel_panel.visible = false
	var main := get_tree().current_scene
	if main and main.has_method("travel_to"):
		main.travel_to(scene_id, "default")


# ---------- Signal handlers ----------

func _on_prompt(text: String) -> void:
	var dm := DataManager
	_prompt_label.text = "[E] " + text + "\n(%s)" % dm.tr_key("prompt_hint_interact")
	_prompt.visible = true


func _on_prompt_cleared() -> void:
	_prompt.visible = false


func _on_location(location_id: String) -> void:
	var dm := DataManager
	_banner_label.text = str((dm.get_scene_data(location_id) as Dictionary).get("name", location_id))
	_banner.visible = true
	_banner.modulate.a = 0.0
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.5)
	_banner_tween.tween_interval(2.2)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.8)
	_banner_tween.tween_callback(func() -> void: _banner.visible = false)


func _on_objective(text: String) -> void:
	_objective_label.text = "🎯 " + text
	show_toast("🎯 " + text, "objective")


func show_toast(text: String, kind: String) -> void:
	if _toast_box.get_child_count() > 4:
		(_toast_box.get_child(0) as Node).queue_free()
	var panel := PanelContainer.new()
	var border := ThemeFactory.ACCENT
	match kind:
		"clue":
			border = ThemeFactory.PASTEL_YELLOW
		"deduction":
			border = ThemeFactory.ACCENT_LIGHT
		"relationship_up":
			border = ThemeFactory.GOOD
		"relationship_down":
			border = ThemeFactory.BAD
		"objective":
			border = ThemeFactory.PASTEL_BLUE
		"achievement":
			border = ThemeFactory.PASTEL_YELLOW
		_:
			border = ThemeFactory.ACCENT
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.06, 0.12, 0.22, 0.9), border, 1, 8))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeFactory.style_label(l, 15, ThemeFactory.CREAM)
	panel.add_child(l)
	_toast_box.add_child(panel)
	var tw := create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(panel, "modulate:a", 0.0, 0.6)
	tw.tween_callback(panel.queue_free)


func _on_relationship(char_id: String, _old: int, new_value: int) -> void:
	# Kilas info level hubungan baru.
	var rm := RelationshipManager
	var dm := DataManager
	var char_name: String = str((dm.get_character(char_id) as Dictionary).get("name", char_id))
	show_toast("💛 %s: %s (%d)" % [char_name, rm.level_label(char_id), new_value], "system")


func _on_memory_start(_node_id: String) -> void:
	_memory_overlay.visible = true
	_memory_label.visible = true
	_memory_label.modulate.a = 0.0
	for b in _memory_bars:
		(b as ColorRect).visible = true
	if _memory_tween and _memory_tween.is_valid():
		_memory_tween.kill()
	_memory_tween = create_tween().set_parallel(true)
	_memory_tween.tween_method(_set_memory_strength, 0.0, 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	_memory_tween.tween_property(_memory_bars[0], "offset_bottom", 70.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_memory_tween.tween_property(_memory_bars[1], "offset_top", -70.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_memory_tween.tween_property(_memory_label, "modulate:a", 1.0, 1.4).set_delay(0.4)


func _set_memory_strength(v: float) -> void:
	var m := _memory_overlay.material as ShaderMaterial
	if m:
		m.set_shader_parameter("strength", v)


func _on_memory_end(_node_id: String) -> void:
	if _memory_tween and _memory_tween.is_valid():
		_memory_tween.kill()
	_memory_tween = create_tween().set_parallel(true)
	_memory_tween.tween_method(_set_memory_strength, 1.0, 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	_memory_tween.tween_property(_memory_bars[0], "offset_bottom", 0.0, 0.7)
	_memory_tween.tween_property(_memory_bars[1], "offset_top", 0.0, 0.7)
	_memory_tween.tween_property(_memory_label, "modulate:a", 0.0, 0.4)
	_memory_tween.chain().tween_callback(_finish_memory_end)


func _finish_memory_end() -> void:
	_memory_overlay.visible = false
	for b in _memory_bars:
		(b as ColorRect).visible = false
	_memory_label.visible = false


## Vignette sinematik di tepi layar (di belakang semua elemen HUD).
func _add_vignette() -> void:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv) * 1.5;
	float v = smoothstep(0.45, 1.0, d);
	COLOR = vec4(0.02, 0.03, 0.06, v * 0.5);
}
"""
	var smat := ShaderMaterial.new()
	smat.shader = sh
	rect.material = smat
	add_child(rect)


## Kartu judul bab ala Life is Strange.
func _on_chapter(chapter_id: String) -> void:
	var dm := DataManager
	var key: String = "chapter_" + chapter_id
	var title: String = dm.tr_key(key)
	if title == key:
		return
	_chapter_label.text = title
	_chapter_card.visible = true
	_chapter_card.modulate.a = 0.0
	if _chapter_tween and _chapter_tween.is_valid():
		_chapter_tween.kill()
	_chapter_tween = create_tween()
	_chapter_tween.tween_property(_chapter_card, "modulate:a", 1.0, 0.6)
	_chapter_tween.tween_interval(2.4)
	_chapter_tween.tween_property(_chapter_card, "modulate:a", 0.0, 0.8)
	_chapter_tween.tween_callback(_hide_chapter_card)


func _hide_chapter_card() -> void:
	_chapter_card.visible = false


## Ringkasan "Sebelumnya di Kota Tua Pesisir": bab, objektif, 3 catatan terakhir, jam main.
func show_recap() -> void:
	var dm := DataManager
	var gm := GameManager
	var im := InvestigationManager
	var rm := RelationshipManager
	_recap_title.text = dm.tr_key("recap_title")
	_recap_close.text = dm.tr_key("recap_close")
	var ch: String = dm.tr_key("chapter_" + gm.current_chapter)
	var body: String = "[b]%s[/b]\n🎯 %s\n" % [ch, gm.objective_text()]
	var notes: Array = (im.journal_notes as Array).duplicate()
	notes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("order", 0)) > int(b.get("order", 0)))
	var shown: int = 0
	for n in notes:
		var nd: Dictionary = n
		if str(nd.get("id", "")).begins_with("ach:") or str(nd.get("id", "")).begins_with("met:"):
			continue
		body += "\n• " + str(nd.get("text", ""))
		shown += 1
		if shown >= 3:
			break
	var prog: Dictionary = im.clue_progress()
	body += "\n\n[color=#BFDBFE]🔍 %d/%d · 🧩 %d/4 · ⏱ %s · Rara 💛%d · Harto 💛%d · Mira 💛%d[/color]" % [
		prog["found"], prog["total"], (im.deductions_solved as Array).size(),
		MathUtils.format_playtime(SaveManager.playtime), rm.get_value("rara"), rm.get_value("pak_harto"), rm.get_value("mira")]
	_recap_body.text = body
	_recap.visible = true
	_recap.modulate.a = 0.0
	if _recap_tween and _recap_tween.is_valid():
		_recap_tween.kill()
	_recap_tween = create_tween()
	_recap_tween.tween_property(_recap, "modulate:a", 1.0, 0.5)
	_recap_tween.tween_interval(14.0)
	_recap_tween.tween_property(_recap, "modulate:a", 0.0, 0.8)
	_recap_tween.tween_callback(_hide_recap)


func _hide_recap() -> void:
	if _recap_tween and _recap_tween.is_valid():
		_recap_tween.kill()
	_recap.visible = false
