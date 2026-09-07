class_name Cat2D
extends Node2D
## Cat2D — Kunyit versi panggung 2D: kucing oranye digambar vektor bergaya
## anime-chibi (badan bulat, mata besar, ekor melengkung beranimasi), mengikuti
## Ardi dari jarak sopan, duduk saat diam, bisa dielus. Logika = Cat 3D.

const FOLLOW_DIST := 150.0
const STOP_DIST := 95.0
const SPEED := 190.0

var display_name: String = "Kunyit"
var follow: bool = true
var floor_far: float = 500.0
var floor_near: float = 700.0
var floor_xmin: float = 40.0
var floor_xmax: float = 1240.0
var far_scale: float = 0.7
var base_scale: float = 1.0

var _t: float = 0.0
var _sit: bool = true
var _pet_cd: float = 0.0
var _meow_cd: float = 6.0
var _facing_left: bool = false
var _walk_phase: float = 0.0
var _hover: bool = false


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("cat")


func set_floor(f: Dictionary, fscale: float) -> void:
	floor_far = float(f.get("y_far", 500.0))
	floor_near = float(f.get("y_near", 700.0))
	floor_xmin = float(f.get("x_min", 40.0))
	floor_xmax = float(f.get("x_max", 1240.0))
	far_scale = fscale


func _depth_scale() -> float:
	if floor_near <= floor_far:
		return base_scale
	var t: float = clampf((position.y - floor_far) / (floor_near - floor_far), 0.0, 1.0)
	return base_scale * lerpf(far_scale, 1.0, t)


func hit_rect() -> Rect2:
	var s: float = _depth_scale()
	return Rect2(position.x - 40.0 * s, position.y - 60.0 * s, 80.0 * s, 62.0 * s)


func _process(delta: float) -> void:
	_t += delta
	_pet_cd = maxf(_pet_cd - delta, 0.0)
	_meow_cd -= delta
	z_index = clampi(int(position.y), 0, 4000)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and follow and GameManager.is_gameplay_input_active():
		var to: Vector2 = player.position - position
		var d: float = to.length()
		if d > FOLLOW_DIST:
			_sit = false
			var step: Vector2 = to.normalized() * SPEED * delta
			position += step
			position = Vector2(clampf(position.x, floor_xmin, floor_xmax), clampf(position.y, floor_far, floor_near))
			_facing_left = to.x < 0.0
			_walk_phase += delta * 16.0
		elif d < STOP_DIST or _sit:
			_sit = true
		if _meow_cd <= 0.0 and d < 300.0:
			_meow_cd = randf_range(9.0, 20.0)
			SignalBus.sfx_requested.emit("sfx_meow")
	queue_redraw()


func get_prompt() -> String:
	return DataManager.tr_key("prompt_pet").format({"name": display_name})


func set_highlight(on: bool) -> void:
	_hover = on


func interact(_from: Node = null) -> void:
	var gm := GameManager
	if not gm.is_gameplay_input_active() or _pet_cd > 0.0:
		return
	_pet_cd = 4.0
	var n: int = int(gm.get_flag("kunyit_pets", 0)) + 1
	gm.set_flag("kunyit_pets", n)
	SignalBus.sfx_requested.emit("sfx_purr")
	if n == 1:
		DialogueManager.start_dialogue("dlg_kunyit_1")
	elif n == 5:
		gm.set_flag("kunyit_jinak", true)
		DialogueManager.start_dialogue("dlg_kunyit_jinak")
	else:
		SignalBus.toast_requested.emit(DataManager.tr_key("toast_purr"), "system")


func _draw() -> void:
	var s: float = _depth_scale()
	var happy: bool = _pet_cd > 0.0
	var fur := Color(0.93, 0.56, 0.20)
	var fur2 := Color(0.99, 0.88, 0.66)
	var line := Color(0.35, 0.18, 0.08)
	var flip: float = -1.0 if _facing_left else 1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(flip * s, s))
	# Bayangan.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s * 0.3))
	draw_circle(Vector2.ZERO, 34.0, Color(0, 0, 0, 0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(flip * s, s))
	var bob: float = 0.0 if (_sit or GameManager.reduce_motion) else absf(sin(_walk_phase)) * 3.0
	var body_y: float = -22.0 - bob
	# Ekor melengkung (polyline) mengibas.
	var wag: float = sin(_t * (7.0 if happy else 2.2)) * (0.5 if happy else 0.3)
	var tail := PackedVector2Array()
	for i in 9:
		var k: float = float(i) / 8.0
		var ang: float = -0.4 - k * (1.8 + wag)
		tail.append(Vector2(-22.0 - k * 26.0 * cos(ang * 0.3), body_y - sin(k * PI) * 30.0 - k * 12.0 * wag))
	draw_polyline(tail, fur, 8.0, true)
	draw_polyline(tail, fur2, 3.0, true)
	# Badan (duduk: tegak lonjong; jalan: mendatar).
	if _sit:
		draw_set_transform(Vector2(0, body_y), 0.0, Vector2(flip * s * 0.9, s * 1.15))
		draw_circle(Vector2.ZERO, 22.0, fur)
		draw_circle(Vector2(0, 6.0), 12.0, fur2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(flip * s, s))
		# Kaki depan.
		draw_circle(Vector2(-8.0, -4.0), 5.0, fur2)
		draw_circle(Vector2(8.0, -4.0), 5.0, fur2)
	else:
		draw_set_transform(Vector2(0, body_y + 4.0), 0.0, Vector2(flip * s * 1.3, s * 0.85))
		draw_circle(Vector2.ZERO, 20.0, fur)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(flip * s, s))
		for i in 4:
			var ph: float = _walk_phase + (0.0 if (i == 0 or i == 3) else PI)
			var lx: float = -14.0 + float(i) * 9.0 + sin(ph) * 5.0
			draw_line(Vector2(lx, body_y + 8.0), Vector2(lx + sin(ph) * 3.0, -2.0), fur, 5.0)
			draw_circle(Vector2(lx + sin(ph) * 3.0, -2.0), 3.0, fur2)
	# Kepala + telinga.
	var hy: float = body_y - 26.0 if _sit else body_y - 14.0
	var hx: float = 6.0 if not _sit else 0.0
	var tri_l := PackedVector2Array([Vector2(hx - 16.0, hy - 6.0), Vector2(hx - 12.0, hy - 26.0), Vector2(hx - 2.0, hy - 12.0)])
	var tri_r := PackedVector2Array([Vector2(hx + 16.0, hy - 6.0), Vector2(hx + 12.0, hy - 26.0), Vector2(hx + 2.0, hy - 12.0)])
	draw_colored_polygon(tri_l, fur)
	draw_colored_polygon(tri_r, fur)
	draw_colored_polygon(PackedVector2Array([Vector2(hx - 13.0, hy - 8.0), Vector2(hx - 11.0, hy - 20.0), Vector2(hx - 5.0, hy - 11.0)]), Color(0.98, 0.75, 0.75))
	draw_colored_polygon(PackedVector2Array([Vector2(hx + 13.0, hy - 8.0), Vector2(hx + 11.0, hy - 20.0), Vector2(hx + 5.0, hy - 11.0)]), Color(0.98, 0.75, 0.75))
	draw_set_transform(Vector2(hx * flip * s, hy * s), 0.0, Vector2(flip * s * 1.05, s * 0.95))
	draw_circle(Vector2.ZERO, 17.0, fur)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(flip * s, s))
	# Belang dahi.
	for i in 3:
		draw_line(Vector2(hx - 6.0 + i * 6.0, hy - 14.0), Vector2(hx - 6.0 + i * 6.0, hy - 8.0), Color(0.8, 0.42, 0.14), 2.0)
	# Mata anime (hijau, sorot putih); saat senang jadi lengkung ^ ^.
	for side in [-1.0, 1.0]:
		var ex: float = hx + side * 7.0
		if happy:
			draw_arc(Vector2(ex, hy - 1.0), 4.5, PI + 0.3, TAU - 0.3, 10, line, 2.0, true)
		else:
			draw_set_transform(Vector2(ex * flip * s, (hy - 1.0) * s), 0.0, Vector2(flip * s * 0.8, s * 1.1))
			draw_circle(Vector2.ZERO, 5.0, Color(0.35, 0.75, 0.35))
			draw_circle(Vector2(0, 0.5), 2.2, Color(0.05, 0.05, 0.06))
			draw_circle(Vector2(-1.5, -1.8), 1.3, Color.WHITE)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(flip * s, s))
	# Hidung + mulut + kumis.
	draw_circle(Vector2(hx, hy + 5.0), 2.0, Color(0.95, 0.55, 0.6))
	draw_arc(Vector2(hx - 2.5, hy + 6.5), 2.5, 0.2, PI - 0.2, 8, line, 1.2, true)
	draw_arc(Vector2(hx + 2.5, hy + 6.5), 2.5, 0.2, PI - 0.2, 8, line, 1.2, true)
	for side in [-1.0, 1.0]:
		for k in 2:
			var y0: float = hy + 3.0 + k * 4.0
			draw_line(Vector2(hx + side * 9.0, y0), Vector2(hx + side * 24.0, y0 + (k * 2.0 - 1.0) * 3.0), Color(1, 1, 1, 0.8), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _hover:
		draw_arc(Vector2(0, -20.0 * s), 42.0 * s, 0.0, TAU, 40, Color(1.0, 0.82, 0.4, 0.75), 2.0, true)
	# Hati kecil saat dielus.
	if happy and not GameManager.reduce_motion:
		var k: float = 1.0 - _pet_cd / 4.0
		var hp := Vector2(10.0 * s, (-70.0 - k * 40.0) * s)
		var a: float = clampf(1.2 - k * 1.2, 0.0, 1.0)
		draw_circle(hp + Vector2(-4, 0) * s, 4.5 * s, Color(1.0, 0.4, 0.5, a))
		draw_circle(hp + Vector2(4, 0) * s, 4.5 * s, Color(1.0, 0.4, 0.5, a))
		draw_colored_polygon(PackedVector2Array([hp + Vector2(-8, 2) * s, hp + Vector2(8, 2) * s, hp + Vector2(0, 11) * s]), Color(1.0, 0.4, 0.5, a))
