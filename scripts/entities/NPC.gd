extends CharacterBody3D
## NPC — karakter pendukung (Rara, Pak Harto, Mira, warga).
## Berdiri di lokasi, menoleh ke pemain, dan memicu dialog saat diinteraksi.

@export var character_id: String = "rara"
@export var display_name: String = "Rara"
@export var dialogue_id: String = ""
@export var dialogue_flag_variants: Dictionary = {}
## Contoh: {"bab2": "dlg_rara_bab2"} + flag "rara_variant" = "bab2" -> pakai varian itu.
## Hadiah: {item_id: {"dialogue", "relationship", "flag"}} — diisi LocationBase dari scenes.json.
var gift_options: Dictionary = {}
## Radius berkeliling (0 = diam). Warga generik berjalan santai di sekitar posnya.
var wander_radius: float = 0.0

var _home: Vector3 = Vector3.ZERO
var _wander_target: Vector3 = Vector3.ZERO
var _wander_wait: float = 0.0
var _walk_phase: float = 0.0
var _wave_t: float = 0.0
var _waved: bool = false
var _arm_r: Node3D = null

var _mesh_root: Node3D
var _label: Label3D
var _highlight: bool = false
var _t: float = 0.0
var _meshes: Array = []


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("npc")
	_build()
	GameManager.flags.get("x", null)  # no-op: pastikan GM ada


func setup(char_id: String, npc_name: String, dlg: String, variants: Dictionary = {}) -> void:
	character_id = char_id
	display_name = npc_name
	dialogue_id = dlg
	dialogue_flag_variants = variants


func _build() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.5
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)
	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	add_child(_mesh_root)
	var factory := CharacterFactory.new()
	_mesh_root.add_child(factory.build_character(character_id))
	_label = Label3D.new()
	_label.text = display_name
	_label.font_size = 64
	_label.pixel_size = 0.008
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 2.15, 0)
	_label.modulate = Color(1, 0.95, 0.8)
	_label.outline_size = 12
	_label.outline_modulate = Color(0.1, 0.15, 0.25, 0.9)
	add_child(_label)
	# Kumpulkan mesh untuk highlight.
	_collect_meshes(_mesh_root)
	call_deferred("_init_wander")


func _init_wander() -> void:
	_home = global_position
	_wander_target = _home
	_wander_wait = randf_range(1.0, 4.0)
	if wander_radius <= 0.0 and character_id == "warga":
		wander_radius = 2.5
	# Ambil "lengan kanan" (kotak ketiga yang dibuat CharacterFactory) untuk lambaian.
	var avatar := _mesh_root.get_child(0) as Node3D
	if avatar and avatar.get_child_count() > 4:
		_arm_r = avatar.get_child(4) as Node3D


func _collect_meshes(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			_meshes.append(c)
		_collect_meshes(c)


func _process(delta: float) -> void:
	_t += delta
	# Idle: napas + menoleh ke pemain bila dekat.
	_mesh_root.scale.y = 1.0 + sin(_t * 1.8 + float(get_instance_id() % 10)) * 0.015
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var near_player: bool = false
	if player:
		var to: Vector3 = player.global_position - global_position
		to.y = 0
		near_player = to.length() < 8.0
		if near_player and to.length() > 0.05:
			var target: float = atan2(-to.x, -to.z)
			_mesh_root.rotation.y = MathUtils.lerp_angle_stable(_mesh_root.rotation.y, target, delta * 3.0)
		# Lambaian sekali saat pemain mendekat (< 4 m), reset saat menjauh.
		if to.length() < 4.0 and not _waved:
			_waved = true
			_wave_t = 1.4
		elif to.length() > 6.0:
			_waved = false
	_update_wave(delta)
	_update_wander(delta, near_player)


func _update_wave(delta: float) -> void:
	if _arm_r == null:
		return
	if _wave_t > 0.0:
		_wave_t -= delta
		_arm_r.rotation.z = -2.6 + sin(_t * 14.0) * 0.35
	else:
		_arm_r.rotation.z = lerpf(_arm_r.rotation.z, 0.0, delta * 6.0)


## Berkeliling santai di sekitar pos; berhenti saat pemain dekat atau dialog aktif.
func _update_wander(delta: float, near_player: bool) -> void:
	if wander_radius <= 0.0:
		return
	if near_player or not GameManager.is_gameplay_input_active():
		velocity = Vector3.ZERO
		_mesh_root.position.y = lerpf(_mesh_root.position.y, 0.0, delta * 8.0)
		return
	var flat: Vector3 = _wander_target - global_position
	flat.y = 0.0
	if flat.length() < 0.25:
		_wander_wait -= delta
		_mesh_root.position.y = lerpf(_mesh_root.position.y, 0.0, delta * 8.0)
		if _wander_wait <= 0.0:
			var ang: float = randf() * TAU
			var r: float = randf_range(0.6, wander_radius)
			_wander_target = _home + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
			_wander_wait = randf_range(2.0, 6.0)
		return
	var dir: Vector3 = flat.normalized()
	velocity = Vector3(dir.x * 0.9, -1.0, dir.z * 0.9)
	move_and_slide()
	_mesh_root.rotation.y = MathUtils.lerp_angle_stable(_mesh_root.rotation.y, atan2(-dir.x, -dir.z), delta * 4.0)
	_walk_phase += delta * 7.0
	_mesh_root.position.y = absf(sin(_walk_phase)) * 0.03


func get_prompt() -> String:
	var dm := DataManager
	return dm.tr_key("prompt_talk").format({"name": display_name})


func set_highlight(on: bool) -> void:
	_highlight = on
	# Highlight via warna label nama + anggukan mesh.
	if _label:
		_label.modulate = Color(1.0, 0.85, 0.4) if on else Color(1, 0.95, 0.8)
	if _mesh_root:
		_mesh_root.scale = Vector3.ONE * (1.04 if on else 1.0)


func interact(_from: Node = null) -> void:
	var gm := GameManager
	if not gm.is_gameplay_input_active():
		return
	InvestigationManager.mark_character_met(character_id)
	# Hadiah: bila pemain membawa item kesukaan NPC, serahkan sekarang (sekali saja).
	var gift_dlg: String = _check_gift()
	if gift_dlg != "":
		DialogueManager.start_dialogue(gift_dlg)
		return
	var dlg: String = _resolve_dialogue()
	if dlg == "":
		var bus := SignalBus
		bus.toast_requested.emit(display_name + " ...", "system")
		return
	DialogueManager.start_dialogue(dlg)


## Serahkan hadiah bila pemain membawa item kesukaan NPC (sekali saja per hadiah).
## Mengembalikan dialogue_id reaksi hadiah, atau "" bila tidak ada yang diserahkan.
func _check_gift() -> String:
	if gift_options.is_empty():
		return ""
	var im := InvestigationManager
	var gm := GameManager
	for item_id in gift_options.keys():
		var g: Dictionary = gift_options[item_id]
		var flag: String = str(g.get("flag", ""))
		if flag != "" and bool(gm.get_flag(flag, false)):
			continue
		if im.has_item(str(item_id)):
			if flag != "":
				gm.set_flag(flag, true)
			var rel: Dictionary = g.get("relationship", {})
			for cid in rel.keys():
				RelationshipManager.add(str(cid), int(rel[cid]))
			im.remove_item(str(item_id))
			return str(g.get("dialogue", ""))
	return ""


## Pilih varian dialog berdasarkan flag (progres cerita).
func _resolve_dialogue() -> String:
	var gm := GameManager
	# Kunci varian: flag "<char>_variant" bernilai nama varian.
	var variant_key: String = str(gm.get_flag(character_id + "_variant", ""))
	if variant_key != "" and dialogue_flag_variants.has(variant_key):
		return str(dialogue_flag_variants[variant_key])
	# Atau cocokkan flag boolean apa pun yang namanya ada di variants.
	for k in dialogue_flag_variants.keys():
		if bool(gm.get_flag(str(k), false)):
			return str(dialogue_flag_variants[k])
	return dialogue_id
