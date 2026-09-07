class_name Actor2D
extends Node2D
## Actor2D — tokoh sprite anime di panggung 2D. Titik asal = kaki.
## Skala mengikuti kedalaman (y lantai), napas halus, goyang saat berjalan,
## balik arah (flip), bayangan lembut, sorot bicara / redup saat orang lain bicara.

const SPRITE_DIR := "res://assets/art/sprites/"

var character_id: String = "ardi"
var display_name: String = "Ardi"
## Parameter lantai dari stages.json (y_far, y_near, x_min, x_max) + skala sprite.
var floor_far: float = 500.0
var floor_near: float = 700.0
var floor_xmin: float = 40.0
var floor_xmax: float = 1240.0
var sprite_scale: float = 0.35
var far_scale: float = 0.7

var facing_left: bool = false
var moving: bool = false
var running: bool = false
var talking: bool = false
var dimmed: bool = false
var hovered: bool = false

var _sprite: Sprite2D
var _tex: Texture2D = null
var _t: float = 0.0
var _walk_phase: float = 0.0
var _hop: float = 0.0        # lompatan kecil (sapaan) 0..1
var _hop_v: float = 0.0
var _seed: float = 0.0
var _cur_mod: Color = Color.WHITE
## Warna cahaya lingkungan panggung (sprite ikut suasana latar: senja hangat, hujan biru).
var ambient: Color = Color.WHITE
var _height_px: float = 1100.0


func _ready() -> void:
	_seed = randf() * TAU
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.centered = true
	add_child(_sprite)
	load_sprite(character_id)


## Muat sprite tokoh; bila tidak ada (belum digambar) pakai siluet prosedural.
func load_sprite(cid: String) -> void:
	character_id = cid
	_tex = ThemeFactory.art_texture(SPRITE_DIR + cid + ".png")
	if _tex == null and cid != "warga":
		# Tokoh tanpa sprite khusus memakai sprite warga bila ada.
		_tex = ThemeFactory.art_texture(SPRITE_DIR + "warga.png")
	if _tex:
		_sprite.texture = _tex
		_height_px = float(_tex.get_height())
		_sprite.offset = Vector2(0, -_height_px * 0.5)
		_sprite.visible = true
	else:
		_sprite.visible = false
		_height_px = 1100.0
	queue_redraw()


func set_floor(f: Dictionary, sscale: float, fscale: float) -> void:
	floor_far = float(f.get("y_far", 500.0))
	floor_near = float(f.get("y_near", 700.0))
	floor_xmin = float(f.get("x_min", 40.0))
	floor_xmax = float(f.get("x_max", 1240.0))
	sprite_scale = sscale
	far_scale = fscale


## Faktor kedalaman 0 (jauh) .. 1 (dekat) dari posisi y kaki.
func depth_t() -> float:
	if floor_near <= floor_far:
		return 1.0
	return clampf((position.y - floor_far) / (floor_near - floor_far), 0.0, 1.0)


## Skala tampilan sprite sekarang (untuk kecepatan, jangkauan, hit-test).
func view_scale() -> float:
	return sprite_scale * lerpf(far_scale, 1.0, depth_t())


## Tinggi sprite di layar (px desain).
func height() -> float:
	return _height_px * view_scale()


## Persegi hit-test (px desain, ruang panggung) sekitar badan.
func hit_rect() -> Rect2:
	var h: float = height()
	var w: float = maxf(h * 0.34, 40.0)
	return Rect2(position.x - w * 0.5, position.y - h, w, h)


func clamp_to_floor(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, floor_xmin, floor_xmax), clampf(p.y, floor_far, floor_near))


func face_towards(x: float) -> void:
	if absf(x - position.x) > 2.0:
		facing_left = x < position.x


func hop() -> void:
	if _hop_v <= 0.0 and _hop <= 0.0:
		_hop_v = 1.0


func set_talking(on: bool) -> void:
	talking = on


func set_dim(on: bool) -> void:
	dimmed = on


func set_highlight(on: bool) -> void:
	hovered = on
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	var reduce: bool = GameManager.reduce_motion
	var s: float = view_scale()
	# Napas: skala y berdenyut sangat halus; saat bicara sedikit lebih hidup.
	var breathe: float = 0.0 if reduce else sin(_t * 1.7 + _seed) * 0.006
	var talk_bob: float = 0.0
	if talking and not reduce:
		talk_bob = absf(sin(_t * 9.0)) * 3.0
	# Goyang jalan: naik-turun + miring kecil.
	var bob: float = 0.0
	var tilt: float = 0.0
	if moving:
		_walk_phase += delta * (13.0 if running else 9.5)
		if not reduce:
			bob = absf(sin(_walk_phase)) * (7.0 if running else 4.5) * s / 0.35
			tilt = sin(_walk_phase) * (0.035 if running else 0.02)
	else:
		_walk_phase = 0.0
	# Lompatan sapaan.
	if _hop_v > 0.0 or _hop > 0.0:
		_hop += _hop_v * delta * 5.0
		_hop_v -= delta * 10.0
		if _hop <= 0.0:
			_hop = 0.0
			_hop_v = 0.0
	var hop_px: float = sin(clampf(_hop, 0.0, 1.0) * PI) * 22.0 * s / 0.35
	_sprite.scale = Vector2((-1.0 if facing_left else 1.0) * s, s * (1.0 + breathe))
	_sprite.position = Vector2(0, -bob - talk_bob - hop_px)
	_sprite.rotation = tilt
	_sprite.z_index = 0
	# Kedalaman: yang lebih dekat (y besar) digambar di atas.
	z_index = clampi(int(position.y), 0, 4000)
	# Redup/sorot.
	var target_mod: Color = ambient
	if dimmed:
		target_mod = target_mod * Color(0.62, 0.62, 0.68)
	if hovered:
		target_mod = target_mod.lightened(0.18)
	_cur_mod = _cur_mod.lerp(target_mod, minf(delta * 8.0, 1.0))
	_sprite.self_modulate = _cur_mod
	queue_redraw()


func _draw() -> void:
	var s: float = view_scale()
	# Bayangan lembut elips di kaki.
	var w: float = 62.0 * s / 0.35
	var h: float = 14.0 * s / 0.35
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, h / w))
	draw_circle(Vector2.ZERO, w, Color(0.05, 0.03, 0.08, 0.22))
	draw_circle(Vector2.ZERO, w * 0.6, Color(0.05, 0.03, 0.08, 0.18))
	if hovered:
		draw_arc(Vector2.ZERO, w * 1.08, 0.0, TAU, 40, Color(1.0, 0.82, 0.4, 0.75), 2.5, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _tex == null:
		_draw_silhouette(s)


## Siluet sementara untuk tokoh yang sprite-nya belum digambar.
func _draw_silhouette(s: float) -> void:
	var hpx: float = 1100.0 * s
	var col := Color(0.16, 0.14, 0.2, 0.9)
	var rim := Color(0.55, 0.6, 0.75, 0.5)
	var body_w: float = hpx * 0.26
	# Badan.
	var pts := PackedVector2Array([
		Vector2(-body_w * 0.5, 0), Vector2(-body_w * 0.55, -hpx * 0.45), Vector2(-body_w * 0.62, -hpx * 0.7),
		Vector2(-body_w * 0.35, -hpx * 0.78), Vector2(body_w * 0.35, -hpx * 0.78), Vector2(body_w * 0.62, -hpx * 0.7),
		Vector2(body_w * 0.55, -hpx * 0.45), Vector2(body_w * 0.5, 0),
	])
	draw_colored_polygon(pts, col)
	draw_polyline(pts, rim, 2.0, true)
	# Kepala.
	draw_circle(Vector2(0, -hpx * 0.88), hpx * 0.085, col)
	draw_arc(Vector2(0, -hpx * 0.88), hpx * 0.085, 0.0, TAU, 32, rim, 2.0, true)
	# Tanda tanya kecil (belum dikenal).
	draw_circle(Vector2(0, -hpx * 0.6), hpx * 0.025, Color(1.0, 0.85, 0.4, 0.8))
