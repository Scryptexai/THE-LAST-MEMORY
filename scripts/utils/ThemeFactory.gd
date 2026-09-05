class_name ThemeFactory
extends RefCounted
## ThemeFactory — gaya visual terpusat (Life is Strange-ish):
## biru tua nostalgia, pastel hangat, aksen emas.

const PRIMARY := Color("#1A365D")
const PRIMARY_DARK := Color("#10243d")
const ACCENT := Color("#D97706")
const ACCENT_LIGHT := Color("#FBBF24")
const CREAM := Color("#FFF7E6")
const PASTEL_PINK := Color("#FBCFE8")
const PASTEL_BLUE := Color("#BFDBFE")
const PASTEL_YELLOW := Color("#FDE68A")
const INK := Color("#1F2937")
const GOOD := Color("#34D399")
const BAD := Color("#F87171")


static func title_font(size: int = 34) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = ["Playfair Display", "Georgia", "Times New Roman", "serif"]
	f.font_weight = 700
	f.font_size = size
	return f


static func body_font(size: int = 18) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = ["Inter", "Segoe UI", "Helvetica", "Arial", "sans-serif"]
	f.font_size = size
	return f


static func panel_style(bg: Color = Color(0.06, 0.12, 0.22, 0.92), border: Color = ACCENT, bw: int = 2, radius: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 8
	return s


static func button_styles() -> Dictionary:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.22, 0.38, 0.95)
	normal.border_color = ACCENT
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.34, 0.55, 0.98)
	hover.border_color = ACCENT_LIGHT
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = ACCENT
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.2, 0.2, 0.24, 0.7)
	disabled.border_color = Color(0.4, 0.4, 0.44)
	return {"normal": normal, "hover": hover, "pressed": pressed, "disabled": disabled}


static func style_button(b: Button, font_size: int = 18) -> Button:
	var st := button_styles()
	b.add_theme_stylebox_override("normal", st["normal"])
	b.add_theme_stylebox_override("hover", st["hover"])
	b.add_theme_stylebox_override("pressed", st["pressed"])
	b.add_theme_stylebox_override("disabled", st["disabled"])
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.62))
	b.add_theme_font_override("font", body_font(font_size))
	return b


static func style_label(l: Label, size: int = 18, color: Color = CREAM, title: bool = false) -> Label:
	l.add_theme_font_override("font", title_font(size) if title else body_font(size))
	l.add_theme_color_override("font_color", color)
	return l


static func dim_layer(alpha: float = 0.55) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.03, 0.05, 0.1, alpha)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r


static func center_container(min_size: Vector2) -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", panel_style())
	c.add_child(panel)
	return c
