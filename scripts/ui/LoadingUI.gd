extends Control
## LoadingUI — layar transisi lokasi dengan progress bar & tips.

var _bar: ProgressBar
var _label: Label
var _tip: Label
var _dots: float = 0.0

const TIPS := [
	"TIPS: Tekan E untuk berinteraksi dengan objek bercahaya.",
	"TIPS: Buka papan investigasi [L] untuk menghubungkan petunjuk.",
	"TIPS: Pilihan dialog memengaruhi hubungan dan ending.",
	"TIPS: Benda milik nenek kadang memicu kilas balik 1983.",
	"TIPS: Jurnal [J] mencatat semua penemuanmu otomatis.",
	"TIPS: Tekan M untuk membuka peta perjalanan antarlokasi.",
	"TIPS: Persahabatan membuka pintu yang terkunci bagi orang asing.",
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ThemeFactory.dim_layer(0.92)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(_label, 28, ThemeFactory.PASTEL_YELLOW, true)
	box.add_child(_label)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(420, 22)
	_bar.min_value = 0
	_bar.max_value = 100
	_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.14, 0.22)
	bg.set_corner_radius_all(11)
	_bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ThemeFactory.ACCENT
	fill.set_corner_radius_all(11)
	_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_bar)
	_tip = Label.new()
	_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeFactory.style_label(_tip, 15, ThemeFactory.CREAM)
	box.add_child(_tip)
	SignalBus.loading_progress.connect(_on_progress)
	visibility_changed.connect(_on_visible)


func _on_visible() -> void:
	if visible:
		_tip.text = TIPS[randi() % TIPS.size()]
		_on_progress(0.0, DataManager.tr_key("loading_travel"))


func _process(delta: float) -> void:
	if not visible:
		return
	_dots += delta
	var n: int = int(_dots * 2.0) % 4
	_label.text = _base_text + ".".repeat(n)


var _base_text: String = "Memuat"


func _on_progress(ratio: float, label: String) -> void:
	_base_text = label
	_bar.value = clampf(ratio, 0.0, 1.0) * 100.0
