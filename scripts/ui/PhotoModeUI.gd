extends Control
## PhotoModeUI — overlay mode foto: letterbox + garis sepertiga + zoom roda mouse.
## Masuk/keluar ditangani UIManager (aksi photo_mode & ui_cancel).

const BAR_H := 90.0
const FOV_MIN := 25.0
const FOV_MAX := 70.0
const FOV_STEP := 5.0

var _cam: Camera3D = null
var _orig_fov: float = 62.0
var _top_bar: ColorRect
var _bottom_bar: ColorRect
var _hint_label: Label
var _zoom_label: Label
var _grid: Array = []
var _filter_layer: CanvasLayer
var _filter_rect: ColorRect
var _filter_label: Label
var _filter_idx: int = 0

## Filter foto: nama kunci ui_strings + mode shader.
const FILTERS := [
	{"key": "photo_filter_normal", "mode": 0, "tag": ""},
	{"key": "photo_filter_1983", "mode": 1, "tag": "1983"},
	{"key": "photo_filter_bw", "mode": 2, "tag": "bw"},
	{"key": "photo_filter_senja", "mode": 3, "tag": "senja"},
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_top_bar = _make_bar()
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_bottom = BAR_H
	_bottom_bar = _make_bar()
	_bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_bar.offset_top = -BAR_H
	add_child(_top_bar)
	add_child(_bottom_bar)
	for i in 4:
		var line := ColorRect.new()
		line.color = Color(1.0, 1.0, 1.0, 0.22)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(line)
		_grid.append(line)
	_zoom_label = Label.new()
	_zoom_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_zoom_label.offset_top = 18.0
	_zoom_label.offset_bottom = 54.0
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(_zoom_label, 22, Color.WHITE, true)
	add_child(_zoom_label)
	_hint_label = Label.new()
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint_label.offset_top = -64.0
	_hint_label.offset_bottom = -24.0
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeFactory.style_label(_hint_label, 17, Color(0.92, 0.92, 0.95))
	add_child(_hint_label)
	_filter_label = Label.new()
	_filter_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_filter_label.offset_top = 54.0
	_filter_label.offset_bottom = 84.0
	_filter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(_filter_label, 16, Color(0.95, 0.88, 0.7))
	add_child(_filter_label)
	# Lapisan filter di bawah UI (layer 5) agar ikut tertangkap saat PhotoManager
	# menyembunyikan lapisan UI utama.
	_filter_layer = CanvasLayer.new()
	_filter_layer.layer = 5
	_filter_layer.visible = false
	add_child(_filter_layer)
	_filter_rect = ColorRect.new()
	_filter_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_filter_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform int mode = 0;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	vec2 d = SCREEN_UV - vec2(0.5);
	float vig = 1.0 - smoothstep(0.35, 0.95, length(d) * 1.35);
	if (mode == 1) {
		vec3 sep = vec3(l) * vec3(1.15, 0.98, 0.78);
		c = mix(c, sep, 0.85) * (0.9 + 0.1 * vig);
		c += (fract(sin(dot(SCREEN_UV * vec2(431.0, 297.0) + TIME, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.05;
	} else if (mode == 2) {
		float k = smoothstep(0.05, 0.95, l);
		c = vec3(k) * (0.85 + 0.15 * vig);
	} else if (mode == 3) {
		vec3 warm = c * vec3(1.12, 0.96, 0.82) + vec3(0.06, 0.02, 0.0);
		c = mix(warm, vec3(l) * vec3(1.0, 0.8, 0.6), 0.2) * (0.88 + 0.12 * vig);
	}
	COLOR = vec4(c, 1.0);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	_filter_rect.material = m
	_filter_layer.add_child(_filter_rect)
	visibility_changed.connect(_on_visibility_changed)
	call_deferred("_layout")


func _make_bar() -> ColorRect:
	var b := ColorRect.new()
	b.color = Color(0.0, 0.0, 0.0, 0.85)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_visible_in_tree():
		_layout()


## Posisikan 4 garis sepertiga mengikuti ukuran layar.
func _layout() -> void:
	var s := size
	if s.x <= 0.0 or s.y <= 0.0:
		s = get_viewport_rect().size
	var t := 2.0
	(_grid[0] as ColorRect).position = Vector2(s.x / 3.0, 0.0)
	(_grid[0] as ColorRect).size = Vector2(t, s.y)
	(_grid[1] as ColorRect).position = Vector2(s.x * 2.0 / 3.0, 0.0)
	(_grid[1] as ColorRect).size = Vector2(t, s.y)
	(_grid[2] as ColorRect).position = Vector2(0.0, s.y / 3.0)
	(_grid[2] as ColorRect).size = Vector2(s.x, t)
	(_grid[3] as ColorRect).position = Vector2(0.0, s.y * 2.0 / 3.0)
	(_grid[3] as ColorRect).size = Vector2(s.x, t)


func _on_visibility_changed() -> void:
	if visible:
		_cam = null
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player:
			_cam = player.get_node_or_null("CamPivot/SpringArm3D/Camera3D") as Camera3D
		if _cam:
			_orig_fov = _cam.fov
		_hint_label.text = DataManager.tr_key("photo_hint")
		_update_zoom_label()
		_apply_filter()
		_filter_layer.visible = true
		_layout()
	else:
		if _cam and is_instance_valid(_cam):
			_cam.fov = _orig_fov
		_cam = null
		_filter_layer.visible = false
		PhotoManager.current_filter = ""


func _apply_filter() -> void:
	var f: Dictionary = FILTERS[_filter_idx]
	(_filter_rect.material as ShaderMaterial).set_shader_parameter("mode", int(f["mode"]))
	_filter_label.text = "🎞 " + DataManager.tr_key(str(f["key"])) + "  (F)"
	PhotoManager.current_filter = str(f["tag"])


func _cycle_filter(dir: int) -> void:
	_filter_idx = posmod(_filter_idx + dir, FILTERS.size())
	_apply_filter()
	SignalBus.sfx_requested.emit("sfx_dialogue_click")


func _update_zoom_label() -> void:
	var f: float = _cam.fov if _cam and is_instance_valid(_cam) else _orig_fov
	_zoom_label.text = "📷 fov %.0f" % f


func _adjust_zoom(delta: float) -> void:
	if _cam == null or not is_instance_valid(_cam):
		return
	_cam.fov = clampf(_cam.fov + delta, FOV_MIN, FOV_MAX)
	_update_zoom_label()


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_LEFT:
				PhotoManager.capture()
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_UP:
				_adjust_zoom(-FOV_STEP)
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				_adjust_zoom(FOV_STEP)
				get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		PhotoManager.capture()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var k := event as InputEventKey
		if k.physical_keycode == KEY_F:
			_cycle_filter(-1 if k.shift_pressed else 1)
			get_viewport().set_input_as_handled()
