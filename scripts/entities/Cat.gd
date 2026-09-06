extends CharacterBody3D
## Cat — Kunyit, kucing oranye peninggalan Nenek. Mengikuti Ardi dari jarak
## sopan, duduk dan mengibaskan ekor saat diam, bisa dielus (E). Mengeong
## prosedural. Setiap elusan menaikkan flag "kunyit_pets"; 5 kali → jinak.

const FOLLOW_DIST := 2.2
const STOP_DIST := 1.4
const SPEED := 2.6

var display_name: String = "Kunyit"
var follow: bool = true

var _mesh_root: Node3D
var _tail: Node3D
var _legs: Array = []
var _leg_phase: float = 0.0
var _label: Label3D
var _t: float = 0.0
var _sit: bool = true
var _pet_cd: float = 0.0
var _meow_cd: float = 6.0


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("cat")
	_build()


func _build() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.22
	cap.height = 0.6
	col.shape = cap
	col.position = Vector3(0, 0.3, 0)
	add_child(col)
	_mesh_root = Node3D.new()
	add_child(_mesh_root)
	# Kucing bergaya toon: badan kapsul, kepala bulat besar, telinga segitiga,
	# mata anime hijau, ekor melengkung; material cel-shaded + outline.
	var fur := CharacterFactory.toon(Color(0.93, 0.56, 0.20), 0.9)
	var fur2 := CharacterFactory.toon(Color(0.99, 0.88, 0.66), 0.9)
	var body := _cap(_mesh_root, 0.13, 0.22, Vector3(0, 0.22, -0.02), fur)
	body.rotation.x = PI / 2.0
	_cap(_mesh_root, 0.09, 0.16, Vector3(0, 0.15, 0.0), fur2).rotation.x = PI / 2.0  # perut krem
	var head := _sph(_mesh_root, 0.15, Vector3(0, 0.36, 0.24), fur)
	head.scale = Vector3(1.0, 0.92, 0.95)
	_sph(_mesh_root, 0.07, Vector3(0, 0.30, 0.34), fur2).scale = Vector3(1.3, 0.8, 0.8)  # moncong
	for side in [-1.0, 1.0]:
		var ear := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.005
		cone.bottom_radius = 0.045
		cone.height = 0.1
		cone.radial_segments = 8
		ear.mesh = cone
		ear.material_override = fur
		ear.position = Vector3(side * 0.085, 0.50, 0.22)
		ear.rotation.z = -side * 0.25
		_mesh_root.add_child(ear)
		var inner := _sph(_mesh_root, 0.02, Vector3(side * 0.085, 0.49, 0.25), CharacterFactory.toon(Color(0.98, 0.75, 0.75), 0.8))
		inner.scale = Vector3(0.6, 1.2, 0.4)
	var eye := CharacterFactory.toon(Color(0.35, 0.75, 0.35), 0.3)
	eye.emission_enabled = true
	eye.emission = Color(0.2, 0.5, 0.2)
	eye.emission_energy_multiplier = 0.4
	var pupil := CharacterFactory.toon(Color(0.05, 0.05, 0.06), 0.3)
	for side in [-1.0, 1.0]:
		var e := _sph(_mesh_root, 0.035, Vector3(side * 0.06, 0.39, 0.36), eye)
		e.scale = Vector3(0.9, 1.15, 0.5)
		_sph(_mesh_root, 0.016, Vector3(side * 0.06, 0.39, 0.385), pupil).scale = Vector3(0.5, 1.3, 0.5)
		_sph(_mesh_root, 0.008, Vector3(side * 0.05, 0.405, 0.395), CharacterFactory.toon(Color.WHITE, 0.2))
	_sph(_mesh_root, 0.018, Vector3(0, 0.32, 0.40), CharacterFactory.toon(Color(0.95, 0.55, 0.6), 0.6)).scale = Vector3(1.2, 0.8, 0.8)
	# Kumis.
	var wm := CharacterFactory.toon(Color(0.95, 0.95, 0.95), 0.9)
	for side in [-1.0, 1.0]:
		for k in 2:
			var w := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.002
			cm.bottom_radius = 0.002
			cm.height = 0.12
			cm.radial_segments = 4
			w.mesh = cm
			w.material_override = wm
			w.position = Vector3(side * 0.09, 0.30 + k * 0.015, 0.36)
			w.rotation.z = side * (PI / 2.0 + (0.12 if k == 0 else -0.12))
			_mesh_root.add_child(w)
	_legs.clear()
	for i in 4:
		var lx: float = -0.075 if i % 2 == 0 else 0.075
		var lz: float = 0.12 if i < 2 else -0.14
		var leg := Node3D.new()
		leg.position = Vector3(lx, 0.16, lz)
		_mesh_root.add_child(leg)
		_cap(leg, 0.03, 0.08, Vector3(0, -0.08, 0), fur)
		_sph(leg, 0.035, Vector3(0, -0.15, 0.01), fur2).scale = Vector3(1.0, 0.7, 1.2)
		_legs.append(leg)
	_tail = Node3D.new()
	_tail.position = Vector3(0, 0.3, -0.22)
	_mesh_root.add_child(_tail)
	var seg1 := _cap(_tail, 0.028, 0.16, Vector3(0, 0.06, -0.08), fur)
	seg1.rotation.x = -0.9
	var seg2 := _cap(_tail, 0.024, 0.14, Vector3(0, 0.2, -0.13), fur)
	seg2.rotation.x = -0.2
	_sph(_tail, 0.028, Vector3(0, 0.29, -0.13), fur2)
	_label = Label3D.new()
	_label.text = display_name
	_label.font_size = 48
	_label.pixel_size = 0.008
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 0.95, 0)
	_label.modulate = Color(1, 0.95, 0.8)
	_label.outline_size = 10
	_label.outline_modulate = Color(0.1, 0.15, 0.25, 0.9)
	add_child(_label)


func _physics_process(delta: float) -> void:
	_t += delta
	_pet_cd = maxf(_pet_cd - delta, 0.0)
	_meow_cd -= delta
	var player := get_tree().get_first_node_in_group("player") as Node3D
	# Ekor selalu bergerak; lebih cepat saat senang (baru dielus).
	_tail.rotation.y = sin(_t * (6.0 if _pet_cd > 0.0 else 2.2)) * 0.6
	if player == null or not follow or not GameManager.is_gameplay_input_active():
		velocity = Vector3.ZERO
		return
	var to: Vector3 = player.global_position - global_position
	to.y = 0.0
	var d: float = to.length()
	if d > FOLLOW_DIST:
		_sit = false
		var dir: Vector3 = to.normalized()
		velocity = Vector3(dir.x * SPEED, -2.0, dir.z * SPEED)
		move_and_slide()
		_mesh_root.rotation.y = MathUtils.lerp_angle_stable(_mesh_root.rotation.y, atan2(dir.x, dir.z), delta * 6.0)
		_mesh_root.position.y = absf(sin(_t * 14.0)) * 0.025
		_mesh_root.rotation.x = 0.0
		_leg_phase += delta * 14.0
		for i in _legs.size():
			var ph: float = _leg_phase + (0.0 if (i == 0 or i == 3) else PI)
			(_legs[i] as Node3D).rotation.x = sin(ph) * 0.7
	elif d < STOP_DIST or _sit:
		velocity = Vector3.ZERO
		_sit = true
		_mesh_root.position.y = lerpf(_mesh_root.position.y, 0.0, delta * 8.0)
		_mesh_root.rotation.x = lerpf(_mesh_root.rotation.x, -0.25, delta * 4.0)  # duduk: badan sedikit menengadah
		for i in _legs.size():
			(_legs[i] as Node3D).rotation.x = lerpf((_legs[i] as Node3D).rotation.x, (0.9 if i >= 2 else -0.3), delta * 5.0)
		if d > 0.3:
			_mesh_root.rotation.y = MathUtils.lerp_angle_stable(_mesh_root.rotation.y, atan2(to.x, to.z), delta * 3.0)
	else:
		velocity = Vector3.ZERO
	if _meow_cd <= 0.0 and d < 4.0:
		_meow_cd = randf_range(9.0, 20.0)
		SignalBus.sfx_requested.emit("sfx_meow")


func get_prompt() -> String:
	return DataManager.tr_key("prompt_pet").format({"name": display_name})


func set_highlight(on: bool) -> void:
	if _label:
		_label.modulate = Color(1.0, 0.85, 0.4) if on else Color(1, 0.95, 0.8)


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


func _sph(parent: Node3D, r: float, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	mesh.radial_segments = 20
	mesh.rings = 10
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = m
	parent.add_child(mi)
	return mi


func _cap(parent: Node3D, r: float, mid: float, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = r
	mesh.height = mid + r * 2.0
	mesh.radial_segments = 16
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = m
	parent.add_child(mi)
	return mi
