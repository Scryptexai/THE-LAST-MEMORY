extends Control
class_name TownMap
## TownMap — peta kota prosedural (digambar dengan _draw): node lokasi dari
## scenes.json "map_pos" (0..1), jalur antar lokasi, penanda posisi & tujuan.
## Klik node untuk memilih; memancarkan location_picked(scene_id).

signal location_picked(scene_id: String)

const ROADS := [
	["rumah_nenek", "kafe_rara"], ["kafe_rara", "pasar_lama"], ["pasar_lama", "stasiun"],
	["kafe_rara", "pantai"], ["rumah_nenek", "makam_bukit"], ["stasiun", "pantai"],
]

var _hover: String = ""
var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(300, 300)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	if is_visible_in_tree():
		queue_redraw()


func _node_pos(data: Dictionary) -> Vector2:
	var mp: Array = data.get("map_pos", [0.5, 0.5])
	return Vector2(float(mp[0]) * size.x, float(mp[1]) * size.y)


func _locked(data: Dictionary) -> bool:
	var f: String = str(data.get("unlock_flag", ""))
	return f != "" and not bool(GameManager.get_flag(f, false))


func _draw() -> void:
	var dm := DataManager
	var gm := GameManager
	# Kertas tua.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.93, 0.87, 0.72, 1.0))
	for i in 9:
		var y: float = size.y * float(i + 1) / 10.0
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.6, 0.5, 0.35, 0.12), 1.0)
	# Laut di bawah, bukit di kiri atas.
	var sea := PackedVector2Array([Vector2(0, size.y * 0.93), Vector2(size.x * 0.6, size.y * 0.9), Vector2(size.x, size.y * 0.95), Vector2(size.x, size.y), Vector2(0, size.y)])
	draw_colored_polygon(sea, Color(0.55, 0.7, 0.8, 0.8))
	for i in 3:
		var yy: float = size.y * (0.95 + 0.015 * float(i))
		draw_line(Vector2(size.x * 0.1 * float(i), yy), Vector2(size.x * (0.5 + 0.15 * float(i)), yy - 4.0), Color(1, 1, 1, 0.5), 1.0)
	draw_arc(Vector2(size.x * 0.2, size.y * 0.24), size.x * 0.14, PI, TAU, 24, Color(0.55, 0.62, 0.42, 0.8), 3.0)
	draw_arc(Vector2(size.x * 0.32, size.y * 0.24), size.x * 0.09, PI, TAU, 18, Color(0.55, 0.62, 0.42, 0.7), 2.0)
	# Rel kereta (stasiun ke kanan luar).
	var st: Dictionary = dm.scenes.get("stasiun", {})
	if not st.is_empty():
		var sp := _node_pos(st)
		draw_line(sp, Vector2(size.x, sp.y + 10.0), Color(0.3, 0.3, 0.3, 0.8), 2.0)
		for i in 8:
			var x: float = sp.x + float(i) * (size.x - sp.x) / 8.0
			draw_line(Vector2(x, sp.y - 4.0 + float(i) * 1.2), Vector2(x, sp.y + 4.0 + float(i) * 1.2), Color(0.3, 0.3, 0.3, 0.8), 2.0)
	# Jalan.
	for r in ROADS:
		var a: Dictionary = dm.scenes.get(r[0], {})
		var b: Dictionary = dm.scenes.get(r[1], {})
		if a.is_empty() or b.is_empty():
			continue
		var pa := _node_pos(a)
		var pb := _node_pos(b)
		var dashed: bool = _locked(a) or _locked(b)
		if dashed:
			var n: int = 12
			for i in n:
				if i % 2 == 0:
					draw_line(pa.lerp(pb, float(i) / n), pa.lerp(pb, float(i + 1) / n), Color(0.45, 0.35, 0.25, 0.5), 2.0)
		else:
			draw_line(pa, pb, Color(0.45, 0.35, 0.25, 0.85), 3.0)
	# Node lokasi.
	var target: String = dm.get_objective_location(gm.current_objective)
	var font := ThemeFactory.body_font(12)
	for sid in dm.scenes.keys():
		var data: Dictionary = dm.scenes[sid]
		var p := _node_pos(data)
		var locked: bool = _locked(data)
		var here: bool = str(sid) == gm.current_location
		var visited: bool = str(sid) in gm.visited_locations
		var col := Color(0.55, 0.55, 0.55) if locked else (Color(0.85, 0.45, 0.1) if visited else Color(0.3, 0.45, 0.7))
		if str(sid) == _hover and not locked:
			draw_circle(p, 14.0, Color(1.0, 0.9, 0.5, 0.5))
		if str(sid) == target and not here and not gm.hard_mode:
			var pulse: float = 12.0 + 3.0 * sin(_t * 4.0)
			draw_arc(p, pulse, 0.0, TAU, 24, Color(0.99, 0.85, 0.3, 0.9), 2.0)
		draw_circle(p, 8.0, Color(0.2, 0.15, 0.1))
		draw_circle(p, 6.5, col)
		if here:
			draw_circle(p, 3.0, Color.WHITE)
			draw_arc(p, 11.0, 0.0, TAU, 20, Color(0.2, 0.7, 0.3, 0.95), 2.0)
		var label: String = "???" if locked else str(data.get("name", sid))
		var w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, p + Vector2(-w / 2.0 + 1.0, 21.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 0.15, 0.1))
	# Kompas kecil.
	var c := Vector2(size.x - 26.0, 26.0)
	draw_circle(c, 14.0, Color(0.93, 0.87, 0.72))
	draw_arc(c, 14.0, 0.0, TAU, 20, Color(0.3, 0.25, 0.2), 1.5)
	draw_line(c + Vector2(0, 10), c + Vector2(0, -10), Color(0.7, 0.2, 0.15), 2.0)
	draw_string(font, c + Vector2(-4.0, -14.0), "U", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.3, 0.25, 0.2))


func _pick(at: Vector2) -> String:
	var dm := DataManager
	var best: String = ""
	var best_d: float = 18.0
	for sid in dm.scenes.keys():
		var d: float = _node_pos(dm.scenes[sid]).distance_to(at)
		if d < best_d:
			best_d = d
			best = str(sid)
	return best


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h: String = _pick((event as InputEventMouseMotion).position)
		if h != _hover:
			_hover = h
			queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var sid: String = _pick((event as InputEventMouseButton).position)
		if sid == "":
			return
		var data: Dictionary = DataManager.scenes[sid]
		if _locked(data) or sid == GameManager.current_location:
			SignalBus.sfx_requested.emit("sfx_deduction_wrong")
			return
		location_picked.emit(sid)
		accept_event()
