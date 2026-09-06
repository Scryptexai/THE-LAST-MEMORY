extends Control
class_name EvidenceBoard
## EvidenceBoard — "papan benang merah": petunjuk yang sudah ditemukan digambar
## sebagai kartu di papan gabus; benang menghubungkan petunjuk yang berbagi
## tema (related_to). Benang deduksi yang sudah terpecahkan menyala emas.
## Klik kartu = pilih petunjuk (diteruskan lewat clue_clicked).

signal clue_clicked(clue_id: String)

var selected: Array = []      # id petunjuk terpilih (disorot)
var _positions: Dictionary = {}  # clue_id -> Vector2
var _hover: String = ""
var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(300, 220)
	resized.connect(_layout_nodes)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	if is_visible_in_tree():
		queue_redraw()


func rebuild() -> void:
	_layout_nodes()
	queue_redraw()


## Tata letak deterministik: petunjuk dikelompokkan per lokasi penemuan
## (kolom), urut ditemukan (baris), plus jitter kecil agar terasa "ditempel".
func _layout_nodes() -> void:
	_positions.clear()
	var dm := DataManager
	var im := InvestigationManager
	var found: Array = im.clues_found
	if found.is_empty() or size.x <= 0.0:
		return
	var cols: Array = []
	var per_col: Dictionary = {}
	for cid in found:
		var loc: String = str((dm.get_clue(str(cid)) as Dictionary).get("found_in", "?"))
		if not (loc in cols):
			cols.append(loc)
			per_col[loc] = []
		(per_col[loc] as Array).append(str(cid))
	var pad: float = 36.0
	var cw: float = (size.x - pad * 2.0) / float(maxi(cols.size(), 1))
	for ci in cols.size():
		var items: Array = per_col[cols[ci]]
		var rh: float = (size.y - pad * 2.0) / float(maxi(items.size(), 1))
		for ri in items.size():
			var cid: String = items[ri]
			var jitter := Vector2(float(hash(cid) % 17) - 8.0, float((hash(cid) / 17) % 11) - 5.0)
			_positions[cid] = Vector2(pad + cw * (float(ci) + 0.5), pad + rh * (float(ri) + 0.5)) + jitter


func _draw() -> void:
	var dm := DataManager
	var im := InvestigationManager
	# Papan gabus.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.55, 0.38, 0.22, 1.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 140:
		draw_circle(Vector2(rng.randf() * size.x, rng.randf() * size.y), rng.randf_range(0.6, 1.6), Color(0.4, 0.27, 0.15, 0.35))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.2, 0.1), false, 6.0)
	if _positions.is_empty():
		var f := ThemeFactory.body_font(14)
		draw_string(f, Vector2(16.0, size.y / 2.0), dm.tr_key("board_empty"), HORIZONTAL_ALIGNMENT_LEFT, size.x - 32.0, 14, Color(1, 0.95, 0.85, 0.8))
		return
	# Benang tema (merah) antar petunjuk yang berbagi related_to.
	var ids: Array = _positions.keys()
	var drawn: Dictionary = {}
	for a in ids:
		var ra: Array = (dm.get_clue(str(a)) as Dictionary).get("related_to", [])
		for b in ids:
			if a == b or drawn.has(str(b) + "|" + str(a)):
				continue
			var rb: Array = (dm.get_clue(str(b)) as Dictionary).get("related_to", [])
			var shared: int = 0
			for r in ra:
				if r in rb:
					shared += 1
			if shared > 0:
				drawn[str(a) + "|" + str(b)] = true
				_thread(_positions[a], _positions[b], Color(0.75, 0.12, 0.1, 0.35 + 0.15 * float(mini(shared, 3))), 1.5)
	# Benang deduksi terpecahkan (emas, berdenyut).
	for did in im.deductions_solved:
		var req: Array = (dm.deductions.get(str(did), {}) as Dictionary).get("required_clues", [])
		var pulse: float = 0.75 + 0.25 * sin(_t * 3.0 + float(hash(did) % 7))
		for i in req.size():
			for j in range(i + 1, req.size()):
				if _positions.has(req[i]) and _positions.has(req[j]):
					_thread(_positions[req[i]], _positions[req[j]], Color(0.99, 0.8, 0.25, pulse), 2.5)
	# Kartu petunjuk.
	var font := ThemeFactory.body_font(11)
	for cid in ids:
		var p: Vector2 = _positions[cid]
		var clue: Dictionary = dm.get_clue(str(cid))
		var card := Rect2(p - Vector2(46.0, 20.0), Vector2(92.0, 40.0))
		var sel: bool = str(cid) in selected
		draw_rect(Rect2(card.position + Vector2(3.0, 4.0), card.size), Color(0, 0, 0, 0.35))
		var paper := Color(1.0, 0.97, 0.88) if str(clue.get("type", "")) != "object" else Color(0.9, 0.95, 1.0)
		if sel:
			paper = Color(1.0, 0.93, 0.6)
		draw_rect(card, paper)
		draw_rect(card, Color(0.99, 0.75, 0.2) if sel else (Color(1, 1, 1, 0.8) if str(cid) == _hover else Color(0.35, 0.25, 0.15, 0.6)), false, 2.0 if sel or str(cid) == _hover else 1.0)
		draw_circle(card.position + Vector2(card.size.x / 2.0, 0.0), 3.5, Color(0.8, 0.15, 0.1))  # paku payung
		var label: String = str(clue.get("name", cid))
		draw_string(font, card.position + Vector2(5.0, 16.0), label, HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 10.0, 11, Color(0.15, 0.1, 0.05))
		var sub: String = str((dm.get_scene_data(str(clue.get("found_in", ""))) as Dictionary).get("name", ""))
		draw_string(font, card.position + Vector2(5.0, 32.0), sub, HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 10.0, 9, Color(0.4, 0.35, 0.3))


## Benang dengan lengkungan gravitasi kecil (Bezier kuadratik).
func _thread(a: Vector2, b: Vector2, col: Color, width: float) -> void:
	var mid: Vector2 = (a + b) / 2.0 + Vector2(0.0, 10.0 + a.distance_to(b) * 0.06)
	var pts := PackedVector2Array()
	for i in 13:
		var t: float = float(i) / 12.0
		pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	draw_polyline(pts, col, width, true)


func _pick(at: Vector2) -> String:
	for cid in _positions.keys():
		if Rect2(_positions[cid] - Vector2(46.0, 20.0), Vector2(92.0, 40.0)).has_point(at):
			return str(cid)
	return ""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h: String = _pick((event as InputEventMouseMotion).position)
		if h != _hover:
			_hover = h
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var cid: String = _pick((event as InputEventMouseButton).position)
		if cid != "":
			clue_clicked.emit(cid)
			accept_event()
