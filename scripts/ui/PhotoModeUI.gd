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
		_layout()
	else:
		if _cam and is_instance_valid(_cam):
			_cam.fov = _orig_fov
		_cam = null


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
