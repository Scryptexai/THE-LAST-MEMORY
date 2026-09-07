class_name Stage2D
extends Node2D
## Stage2D — panggung 2D anime satu lokasi: latar lukisan, lapisan cahaya &
## partikel (debu/kelopak/gerimis), hotspot dari scenes.json diposisikan oleh
## stages.json, NPC/Kunyit sebagai sprite, Ardi sebagai Player2D, kamera
## parallax halus, dan gradasi suasana per bab (chapter_env) sebagai tint.
##
## Ruang desain 1280×720; Main menempatkannya di SubViewport / CanvasLayer
## dengan stretch canvas_items sehingga otomatis mengikuti ukuran jendela.

const DESIGN := Vector2(1280, 720)

@export var location_id: String = "rumah_nenek"

var stage: Dictionary = {}
var data: Dictionary = {}
var player: Player2D = null

var _bg: Sprite2D
var _tint: ColorRect
var _tint_target: Color = Color(1, 1, 1, 0)
var _light_layer: Node2D
var _lights: Array = []  # {node, energy, flicker, seed}
var _particles: CPUParticles2D = null
var _rain: CPUParticles2D = null
var _hotspots: Array = []
var _npcs: Array = []
var _cat: Cat2D = null
var _t: float = 0.0
var _flash_left: float = 0.0
var _flash_timer: float = 12.0
var _thunder_delay: float = 0.0
var _weather: String = ""
var _cam_offset: Vector2 = Vector2.ZERO
var _hover_node: Node = null
var _sound_nodes: Array = []  # {player, x, y, range}
var _flash_rect: ColorRect
var _memory_tint: float = 0.0
var _memory_on: bool = false


func _ready() -> void:
	add_to_group("location")
	var dm := DataManager
	data = dm.get_scene_data(location_id)
	stage = dm.get_stage(location_id)
	if stage.is_empty():
		GameLog.warn("Stage2D: tidak ada entri stages.json untuk %s" % location_id)
	_build_background()
	_build_lights()
	_build_particles()
	_apply_env_tint()
	_spawn_hotspots()
	_spawn_npcs()
	_spawn_cat()
	_spawn_player()
	_spawn_sounds()
	SignalBus.flag_changed.connect(_on_flag_changed)
	SignalBus.memory_flashback_started.connect(_on_memory_start)
	SignalBus.memory_flashback_ended.connect(_on_memory_end)


func _on_memory_start(_node_id: String) -> void:
	_memory_on = true


func _on_memory_end(_node_id: String) -> void:
	_memory_on = false


# ---------- Latar & suasana ----------

func _build_background() -> void:
	_bg = Sprite2D.new()
	_bg.name = "Background"
	_bg.centered = false
	var tex: Texture2D = ThemeFactory.art_texture(str(stage.get("bg", "")))
	if tex:
		_bg.texture = tex
		var ts: Vector2 = tex.get_size()
		# Sedikit lebih besar dari layar agar parallax kamera tidak memperlihatkan tepi.
		var k: float = maxf(DESIGN.x / ts.x, DESIGN.y / ts.y) * 1.04
		_bg.scale = Vector2(k, k)
		_bg.position = (DESIGN - ts * k) * 0.5
	else:
		# Fallback: gradasi langit dari env scenes.json.
		var env: Dictionary = data.get("env", {})
		var top := Color(str(env.get("sky_top", "#2c4a6e")))
		var hor := Color(str(env.get("sky_horizon", "#e8b98a")))
		var grad := Gradient.new()
		grad.colors = PackedColorArray([top, hor, hor.darkened(0.55)])
		grad.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
		var gt := GradientTexture2D.new()
		gt.gradient = grad
		gt.fill_from = Vector2(0, 0)
		gt.fill_to = Vector2(0, 1)
		gt.width = 64
		gt.height = 64
		_bg.texture = gt
		_bg.scale = DESIGN / 64.0
	_bg.z_index = -100
	add_child(_bg)
	# Tint suasana (per bab / kilas balik) di atas segalanya kecuali UI.
	_tint = ColorRect.new()
	_tint.name = "Tint"
	_tint.position = Vector2(-80, -80)
	_tint.size = DESIGN + Vector2(160, 160)
	_tint.color = Color(1, 1, 1, 0)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.z_index = 4080
	add_child(_tint)
	# Kilat (gerimis).
	_flash_rect = ColorRect.new()
	_flash_rect.position = Vector2(-80, -80)
	_flash_rect.size = DESIGN + Vector2(160, 160)
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.z_index = 4090
	add_child(_flash_rect)


## Warna suasana dari scenes.json env + chapter_env → tint tipis (bukan langit 3D lagi).
func _apply_env_tint() -> void:
	var env: Dictionary = (data.get("env", {}) as Dictionary).duplicate(true)
	var overrides: Dictionary = data.get("chapter_env", {})
	var changed: bool = false
	for ch in ["prolog", "bab1", "bab2", "bab3", "bab4", "final"]:
		if overrides.has(ch) and GameManager.flag_on("chseen_" + ch):
			for k in (overrides[ch] as Dictionary).keys():
				env[k] = (overrides[ch] as Dictionary)[k]
			changed = true
	_weather = str(env.get("weather", ""))
	if changed:
		var fog := Color(str(env.get("fog_color", "#d8b48f")))
		var expo: float = float(env.get("exposure", 1.0))
		# Bab lanjut lebih gelap/dingin: tint warna kabut dengan alpha kecil + gelap bila exposure < 1.
		var a: float = clampf(0.10 + (1.0 - expo) * 0.5, 0.08, 0.42)
		_tint_target = Color(fog.r * 0.5, fog.g * 0.5, fog.b * 0.7, a)
	else:
		_tint_target = Color(1, 1, 1, 0)
	_tint.color = _tint_target
	_setup_weather()


func _setup_weather() -> void:
	if _rain:
		_rain.queue_free()
		_rain = null
	if _weather == "drizzle":
		_rain = CPUParticles2D.new()
		_rain.amount = 260
		_rain.lifetime = 0.9
		_rain.preprocess = 1.0
		_rain.position = Vector2(DESIGN.x * 0.5, -40)
		_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_rain.emission_rect_extents = Vector2(DESIGN.x * 0.7, 10)
		_rain.direction = Vector2(-0.15, 1)
		_rain.spread = 3.0
		_rain.gravity = Vector2(0, 1400)
		_rain.initial_velocity_min = 700
		_rain.initial_velocity_max = 900
		_rain.scale_amount_min = 0.6
		_rain.scale_amount_max = 1.0
		_rain.color = Color(0.85, 0.9, 1.0, 0.35)
		var m := ImageTexture.create_from_image(_streak_image())
		_rain.texture = m
		_rain.z_index = 4060
		add_child(_rain)


static func _streak_image() -> Image:
	var img := Image.create(2, 18, false, Image.FORMAT_RGBA8)
	for y in 18:
		var a: float = 1.0 - absf(float(y) / 17.0 - 0.5) * 1.6
		img.set_pixel(0, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
		img.set_pixel(1, y, Color(1, 1, 1, clampf(a, 0.0, 1.0) * 0.6))
	return img


static func _soft_dot(size: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: float = float(size) * 0.5
	for y in size:
		for x in size:
			var d: float = Vector2(x - c + 0.5, y - c + 0.5).length() / c
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) ** 1.8))
	return img


func _build_particles() -> void:
	var kind: String = str(stage.get("particles", "none"))
	if kind == "none":
		return
	_particles = CPUParticles2D.new()
	_particles.position = DESIGN * 0.5
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = DESIGN * 0.55
	_particles.preprocess = 4.0
	_particles.z_index = 4050
	match kind:
		"dust":
			_particles.amount = 70
			_particles.lifetime = 7.0
			_particles.direction = Vector2(1, -0.2)
			_particles.spread = 60.0
			_particles.gravity = Vector2(4, -6)
			_particles.initial_velocity_min = 4
			_particles.initial_velocity_max = 14
			_particles.scale_amount_min = 0.25
			_particles.scale_amount_max = 0.7
			_particles.color = Color(1.0, 0.9, 0.7, 0.55)
			_particles.texture = ImageTexture.create_from_image(_soft_dot(12))
		"petals":
			_particles.amount = 26
			_particles.lifetime = 8.0
			_particles.position = Vector2(DESIGN.x * 0.6, 40)
			_particles.emission_rect_extents = Vector2(DESIGN.x * 0.5, 30)
			_particles.direction = Vector2(-0.35, 1)
			_particles.spread = 25.0
			_particles.gravity = Vector2(-18, 22)
			_particles.initial_velocity_min = 10
			_particles.initial_velocity_max = 30
			_particles.angular_velocity_min = -90
			_particles.angular_velocity_max = 90
			_particles.scale_amount_min = 0.5
			_particles.scale_amount_max = 0.9
			_particles.color = Color(1.0, 0.97, 0.9, 0.85)
			_particles.texture = ImageTexture.create_from_image(_soft_dot(10))
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	_particles.color_ramp = ramp
	add_child(_particles)


## Cahaya lokal (lampu loket, api unggun, radio): lingkaran lembut aditif + kedip.
func _build_lights() -> void:
	_light_layer = Node2D.new()
	_light_layer.name = "Lights"
	_light_layer.z_index = 4000
	add_child(_light_layer)
	var tex := ImageTexture.create_from_image(_soft_dot(128))
	for l in stage.get("lights", []):
		var cfg: Dictionary = l
		var s := Sprite2D.new()
		s.texture = tex
		s.position = Vector2(float(cfg.get("x", 0)), float(cfg.get("y", 0)))
		var radius: float = float(cfg.get("radius", 150.0))
		s.scale = Vector2.ONE * (radius * 2.0 / 128.0)
		var col := Color(str(cfg.get("color", "#ffc070")))
		s.modulate = Color(col.r, col.g, col.b, 0.0)
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		s.material = mat
		_light_layer.add_child(s)
		_lights.append({"node": s, "energy": float(cfg.get("energy", 0.6)), "flicker": float(cfg.get("flicker", 0.0)), "seed": randf() * TAU, "flag": str(cfg.get("flag", ""))})
	_refresh_lights()


func _refresh_lights() -> void:
	for l in _lights:
		var flag: String = str(l["flag"])
		(l["node"] as Sprite2D).visible = flag == "" or GameManager.flag_on(flag)


# ---------- Entitas ----------

## Warna cahaya lingkungan untuk sprite (stages.json "ambient"), putih bila kosong.
func _ambient() -> Color:
	var a: String = str(stage.get("ambient", ""))
	return Color(a) if a != "" else Color.WHITE


func _floor() -> Dictionary:
	return stage.get("floor", {"y_far": 500, "y_near": 700, "x_min": 40, "x_max": 1240})


func _cond_ok(cond: String) -> bool:
	var c: String = cond.strip_edges()
	if "&" in c:
		for part in c.split("&"):
			if not _cond_ok(str(part)):
				return false
		return true
	if c.begins_with("!"):
		return not _cond_ok(c.substr(1))
	if "=" in c:
		var parts: PackedStringArray = c.split("=", true, 1)
		return str(GameManager.get_flag(parts[0].strip_edges(), "")) == parts[1].strip_edges()
	return GameManager.flag_on(c)


func _npc_present(cfg: Dictionary) -> bool:
	for c in cfg.get("present_if", []):
		if not _cond_ok(str(c)):
			return false
	for c in cfg.get("absent_if", []):
		if _cond_ok(str(c)):
			return false
	return true


func _spawn_hotspots() -> void:
	var spots: Dictionary = stage.get("hotspots", {})
	var i: int = 0
	for obj_cfg in data.get("interactables", []):
		var cfg: Dictionary = obj_cfg
		var oid: String = str(cfg.get("object_id", "obj"))
		var h := Hotspot2D.new()
		h.name = "Hotspot_" + oid
		h.setup(cfg)
		var hs: Dictionary = spots.get(oid, {})
		if hs.is_empty():
			# Tidak dipetakan: sebar di lantai agar tetap bisa dicapai.
			hs = {"x": 160 + (i % 6) * 190, "y": 560 + (i / 6) * 60, "w": 90, "h": 90}
			GameLog.warn("Stage2D: hotspot %s/%s belum dipetakan di stages.json" % [location_id, oid])
		h.position = Vector2(float(hs.get("x", 640)), float(hs.get("y", 600)))
		var w: float = float(hs.get("w", 90))
		var hh: float = float(hs.get("h", 90))
		h.area = Rect2(-w * 0.5, -hh * 0.5, w, hh)
		var st: Array = hs.get("stand", [h.position.x, 660])
		h.stand = Vector2(float(st[0]), float(st[1]))
		add_child(h)
		_hotspots.append(h)
		i += 1


func _spawn_npcs() -> void:
	var slots: Dictionary = stage.get("npcs", {})
	for npc_cfg in data.get("npcs", []):
		var cfg: Dictionary = npc_cfg
		if not _npc_present(cfg):
			continue
		var nid: String = str(cfg.get("slot", cfg.get("character_id", "warga")))
		var info: Dictionary = slots.get(nid, {})
		var spots: Dictionary = cfg.get("spots", {})
		for f in spots.keys():
			if _cond_ok(str(f)) and slots.has(str(spots[f])):
				info = slots[str(spots[f])]
				break
		if info.is_empty():
			info = {"x": 900, "y": 640, "flip": true}
		add_npc(cfg, Vector2(float(info.get("x", 900)), float(info.get("y", 640))), bool(info.get("flip", false)))


func add_npc(cfg: Dictionary, pos: Vector2, flip: bool) -> NPC2D:
	var npc := NPC2D.new()
	npc.character_id = str(cfg.get("character_id", "warga"))
	npc.position = pos
	npc.set_floor(_floor(), float(stage.get("sprite_scale", 0.35)), float(stage.get("far_scale", 0.7)))
	npc.ambient = _ambient()
	add_child(npc)
	npc.configure(cfg)
	npc.facing_left = flip
	_npcs.append(npc)
	return npc


func _spawn_cat() -> void:
	var c: Dictionary = stage.get("cat", {})
	if c.is_empty():
		return
	var only_if: String = str(c.get("only_if", ""))
	if only_if != "" and not _cond_ok(only_if):
		return
	_cat = Cat2D.new()
	_cat.position = Vector2(float(c.get("x", 600)), float(c.get("y", 690)))
	_cat.set_floor(_floor(), float(stage.get("far_scale", 0.7)))
	var follow_default: bool = GameManager.flag_on("chseen_bab1")
	_cat.follow = bool(c.get("follow", follow_default))
	add_child(_cat)


func _spawn_player() -> void:
	player = Player2D.new()
	player.set_floor(_floor(), float(stage.get("sprite_scale", 0.35)), float(stage.get("far_scale", 0.7)))
	player.set_surface(str(stage.get("surface", "wood")))
	player.ambient = _ambient()
	add_child(player)


func _spawn_sounds() -> void:
	for s in stage.get("sounds", []):
		var cfg: Dictionary = s
		var flag: String = str(cfg.get("flag", ""))
		if flag != "" and not GameManager.flag_on(flag):
			continue
		_add_sound(cfg)


func _add_sound(cfg: Dictionary) -> void:
	var p := AudioStreamPlayer2D.new()
	p.stream = AudioManager.spatial_stream(str(cfg.get("id", "snd_sea")))
	p.position = Vector2(float(cfg.get("x", 640)), float(cfg.get("y", 400)))
	p.max_distance = float(cfg.get("range", 600.0))
	p.attenuation = 1.4
	p.autoplay = true
	add_child(p)
	AudioManager.register_spatial2d(p, float(cfg.get("db", 0.0)))
	p.play(randf_range(0.0, 3.0))
	_sound_nodes.append({"cfg": cfg, "player": p})


func _on_flag_changed(_flag: String, _v: Variant) -> void:
	_refresh_lights()
	# Sumber suara yang menunggu flag (radio, lampu loket).
	for s in stage.get("sounds", []):
		var cfg: Dictionary = s
		var flag: String = str(cfg.get("flag", ""))
		if flag == "" or not GameManager.flag_on(flag):
			continue
		var exists: bool = false
		for sn in _sound_nodes:
			if (sn["cfg"] as Dictionary).get("id") == cfg.get("id"):
				exists = true
		if not exists:
			_add_sound(cfg)


# ---------- Masuk lokasi ----------

## Dipanggil Main setelah panggung ditambahkan ke tree.
func enter(spawn_tag: String) -> void:
	var spawns: Dictionary = stage.get("spawns", {})
	var sp: Dictionary = spawns.get(spawn_tag, spawns.get("default", {"x": 640, "y": 680, "flip": false}))
	player.place_at(Vector2(float(sp.get("x", 640)), float(sp.get("y", 680))), bool(sp.get("flip", false)))
	if _cat and _cat.follow:
		_cat.position = player.position + Vector2(-70 if not player.facing_left else 70, 6)
	if _cat:
		_cat.modulate = _ambient()
	# Pendengar audio 2D mengikuti Ardi.
	var listener := AudioListener2D.new()
	player.add_child(listener)
	listener.make_current()
	GameManager.notify_location_loaded(location_id)


# ---------- Proses: kamera parallax, hover mouse, kilat, tint kilas balik ----------

func _process(delta: float) -> void:
	_t += delta
	# Kamera parallax lembut mengikuti Ardi (latar bergeser sedikit berlawanan).
	if player and not GameManager.reduce_motion:
		var kx: float = (player.position.x - DESIGN.x * 0.5) / (DESIGN.x * 0.5)
		var want := Vector2(-kx * 14.0, 0.0)
		_cam_offset = _cam_offset.lerp(want, minf(delta * 2.5, 1.0))
		_bg.position.x = (DESIGN.x - _bg.texture.get_size().x * _bg.scale.x) * 0.5 + _cam_offset.x
	# Lampu berkedip.
	for l in _lights:
		var s: Sprite2D = l["node"]
		if not s.visible:
			continue
		var e: float = float(l["energy"])
		var f: float = float(l["flicker"])
		var k: float = 1.0 + (sin(_t * 9.0 + float(l["seed"])) * 0.5 + sin(_t * 23.0 + float(l["seed"]) * 2.0) * 0.5) * f
		if _flash_left > 0.0:
			k *= 0.4
		s.modulate.a = clampf(e * k * 0.55, 0.0, 1.0)
	# Kilat + guntur saat gerimis.
	if _weather == "drizzle":
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_flash_timer = randf_range(14.0, 28.0)
			_flash_left = 0.16
			_thunder_delay = 0.9
		if _flash_left > 0.0:
			_flash_left -= delta
			_flash_rect.color.a = 0.35 if not GameManager.reduce_motion else 0.12
		else:
			_flash_rect.color.a = lerpf(_flash_rect.color.a, 0.0, delta * 10.0)
		if _thunder_delay > 0.0:
			_thunder_delay -= delta
			if _thunder_delay <= 0.0:
				SignalBus.sfx_requested.emit("sfx_thunder")
	# Tint kilas balik 1983: sepia hangat memudar masuk/keluar.
	_memory_tint = move_toward(_memory_tint, 1.0 if _memory_on else 0.0, delta * 1.5)
	var base: Color = _tint_target
	var sepia := Color(0.55, 0.38, 0.18, 0.38)
	_tint.color = base.lerp(sepia, _memory_tint) if _memory_tint > 0.0 else base
	# Redupkan tokoh yang tidak bicara saat dialog.
	var talking: bool = DialogueManager.is_active()
	for n in _npcs:
		(n as NPC2D).set_dim(talking and n != player.current_interactable)
	if player:
		player.set_dim(false)
	_update_hover()


## Hover mouse: sorot hotspot/NPC di bawah kursor (tanpa mengubah prompt E).
func _update_hover() -> void:
	if not GameManager.is_gameplay_input_active():
		_set_hover(null)
		return
	var mp: Vector2 = get_local_mouse_position()
	_set_hover(_pick_at(mp))


func _pick_at(p: Vector2) -> Node:
	var best: Node = null
	var best_area: float = INF
	for n in get_tree().get_nodes_in_group("interactable"):
		if n == player or not (n is Node2D):
			continue
		var hit: bool = false
		var a: float = INF
		if n is Hotspot2D:
			hit = (n as Hotspot2D).contains_point(p)
			a = (n as Hotspot2D).area.get_area()
		elif n is Actor2D:
			var r: Rect2 = (n as Actor2D).hit_rect()
			hit = r.has_point(p)
			a = r.get_area()
		elif n is Cat2D:
			var r2: Rect2 = (n as Cat2D).hit_rect()
			hit = r2.has_point(p)
			a = r2.get_area()
		if hit and a < best_area:
			best_area = a
			best = n
	return best


func _set_hover(n: Node) -> void:
	if n == _hover_node:
		return
	if _hover_node and is_instance_valid(_hover_node) and _hover_node != player.current_interactable and _hover_node.has_method("set_highlight"):
		_hover_node.set_highlight(false)
	_hover_node = n
	if _hover_node and _hover_node.has_method("set_highlight"):
		_hover_node.set_highlight(true)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if _hover_node else Input.CURSOR_ARROW)


func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_gameplay_input_active() or player == null:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = get_local_mouse_position()
		var target: Node = _pick_at(p)
		if target:
			var stand: Vector2 = (target as Node2D).position
			if target is Hotspot2D:
				stand = (target as Hotspot2D).stand
			elif target is Actor2D or target is Cat2D:
				var dx: float = 95.0 if player.position.x < (target as Node2D).position.x else -95.0
				stand = (target as Node2D).position + Vector2(dx, 0)
			player.walk_to(stand, target)
		else:
			var f: Dictionary = _floor()
			if p.y >= float(f.get("y_far", 500)) - 40.0:
				player.walk_to(Vector2(p.x, maxf(p.y, float(f.get("y_far", 500)))))
		get_viewport().set_input_as_handled()


## Kompas/HUD: posisi "dunia" pemain dan objek dalam px desain.
func player_position() -> Vector2:
	return player.position if player else Vector2.ZERO
