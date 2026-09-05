class_name LocationBase
extends Node3D
## Basis semua lokasi: menerapkan environment, membangun visual prosedural,
## dan memunculkan NPC + objek interaktif dari scenes.json.

const NPCScript := preload("res://scripts/entities/NPC.gd")
const ObjScript := preload("res://scripts/entities/InteractiveObject.gd")

@export var location_id: String = "rumah_nenek"

var layout: Dictionary = {}   # id -> {"pos": Vector3, "yaw": float}
var pf := PropFactory.new()
var _npcs: Array = []
var _objs: Array = []


func _ready() -> void:
	_build_layout()
	_build_visuals()
	_apply_env()
	_spawn_from_data()


## Di-override subclass: isi `layout` (spawn + posisi tiap id).
func _build_layout() -> void:
	layout["spawn:default"] = {"pos": Vector3(0, 0, 6), "yaw": 0.0}


## Di-override subclass: bangun lantai, bangunan, dan properti.
func _build_visuals() -> void:
	pf.plane_ground(self, Vector2(60, 60), Vector3.ZERO, pf.mat(Color(0.35, 0.42, 0.3)))


## Dipanggil Main setelah lokasi ditambahkan ke tree.
func enter(spawn_tag: String) -> void:
	var key: String = "spawn:" + spawn_tag
	if not layout.has(key):
		key = "spawn:default"
	var info: Dictionary = layout[key]
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player and player.has_method("place_at"):
		player.place_at(info["pos"], float(info.get("yaw", 0.0)))
	GameManager.notify_location_loaded(location_id)


func _process(_delta: float) -> void:
	# Batasi pemain di dalam area lokasi (radius 28).
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		var p: Vector3 = player.global_position
		var flat := Vector2(p.x, p.z)
		if flat.length() > 28.0:
			flat = flat.normalized() * 28.0
			player.global_position = Vector3(flat.x, p.y, flat.y)


# ---------- Environment ----------

func _apply_env() -> void:
	var dm := DataManager
	var data: Dictionary = dm.get_scene_data(location_id)
	var env_data: Dictionary = data.get("env", {})
	var world_env := get_tree().get_first_node_in_group("world_env") as WorldEnvironment
	var sun := get_tree().get_first_node_in_group("sun") as DirectionalLight3D
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		env.background_mode = Environment.BG_SKY
		var sky := Sky.new()
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = _color(env_data.get("sky_top", "#2c4a6e"))
		sky_mat.sky_horizon_color = _color(env_data.get("sky_horizon", "#e8b98a"))
		sky_mat.ground_bottom_color = _color(env_data.get("ground_bottom", "#1a2233"))
		sky_mat.ground_horizon_color = _color(env_data.get("ground_horizon", "#c98f5f"))
		sky_mat.sun_angle_max = 30.0
		sky_mat.sun_curve = 0.12
		sky.sky_material = sky_mat
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = float(env_data.get("ambient_energy", 0.7))
		env.fog_enabled = true
		env.fog_light_color = _color(env_data.get("fog_color", "#d8b48f"))
		env.fog_density = float(env_data.get("fog_density", 0.008))
		env.fog_sky_affect = 0.5
		env.tonemap_mode = Environment.TONE_MAP_FILMIC
		env.tonemap_exposure = float(env_data.get("exposure", 1.0))
		env.glow_enabled = true
		env.glow_intensity = 0.25
		env.glow_bloom = 0.08
		env.ssao_enabled = false
	if sun:
		sun.light_color = _color(env_data.get("sun_color", "#ffdcb0"))
		sun.light_energy = float(env_data.get("sun_energy", 1.1))
		var rot: Array = env_data.get("sun_rotation", [-0.9, -0.6])
		sun.rotation = Vector3(float(rot[0]), float(rot[1]), 0)


func _color(v: Variant) -> Color:
	if v is Color:
		return v
	return Color(str(v))


# ---------- Spawning dari data ----------

func _spawn_from_data() -> void:
	var dm := DataManager
	var data: Dictionary = dm.get_scene_data(location_id)
	for npc_cfg in data.get("npcs", []):
		var nid: String = str((npc_cfg as Dictionary).get("slot", (npc_cfg as Dictionary).get("character_id", "warga")))
		var info: Dictionary = layout.get("npc:" + nid, {"pos": Vector3(2, 0, 2), "yaw": 0.0})
		add_npc(npc_cfg, info["pos"], float(info.get("yaw", 0.0)))
	for obj_cfg in data.get("interactables", []):
		var oid: String = str((obj_cfg as Dictionary).get("object_id", "obj"))
		var oinfo: Dictionary = layout.get("obj:" + oid, {"pos": Vector3(-2, 0, 2), "yaw": 0.0})
		add_interactable(obj_cfg, oinfo["pos"])


func add_npc(cfg: Dictionary, pos: Vector3, yaw: float) -> Node:
	var npc: CharacterBody3D = NPCScript.new()
	npc.set("character_id", str(cfg.get("character_id", "warga")))
	npc.set("display_name", str(cfg.get("display_name", "Warga")))
	npc.set("dialogue_id", str(cfg.get("dialogue_id", "")))
	npc.set("dialogue_flag_variants", cfg.get("variants", {}))
	npc.set("gift_options", cfg.get("gifts", {}))
	add_child(npc)
	npc.global_position = pos
	npc.rotation.y = yaw
	_npcs.append(npc)
	return npc


func add_interactable(cfg: Dictionary, pos: Vector3) -> Node:
	var obj: StaticBody3D = ObjScript.new()
	obj.set("object_id", str(cfg.get("object_id", "obj")))
	add_child(obj)
	(obj as Node).call("setup", cfg)
	obj.global_position = pos
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.9
	col.shape = sphere
	col.position = Vector3(0, 1.0, 0)
	obj.add_child(col)
	_objs.append(obj)
	return obj


func spawn_wanderer(display_name: String, pos: Vector3, dialogue_id: String) -> Node:
	return add_npc({"character_id": "warga", "display_name": display_name, "dialogue_id": dialogue_id}, pos, 0.0)


## Posisi layout (fallback aman bila id tak terdaftar).
func P(key: String, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if layout.has(key):
		return (layout[key] as Dictionary)["pos"]
	return fallback
