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
	var pf := PropFactory.new()
	var fur := pf.mat(Color(0.93, 0.55, 0.2), 0.9)
	var fur2 := pf.mat(Color(0.98, 0.85, 0.6), 0.9)
	pf.box(_mesh_root, Vector3(0.24, 0.22, 0.46), Vector3(0, 0.22, 0), fur)
	pf.box(_mesh_root, Vector3(0.16, 0.08, 0.3), Vector3(0, 0.12, 0.02), fur2)
	pf.sphere(_mesh_root, 0.15, Vector3(0, 0.36, 0.26), fur)
	pf.box(_mesh_root, Vector3(0.06, 0.09, 0.03), Vector3(-0.08, 0.5, 0.24), fur)
	pf.box(_mesh_root, Vector3(0.06, 0.09, 0.03), Vector3(0.08, 0.5, 0.24), fur)
	var eye := pf.mat(Color(0.2, 0.5, 0.25), 0.4, Color(0.2, 0.5, 0.25), 0.6)
	pf.sphere(_mesh_root, 0.025, Vector3(-0.055, 0.38, 0.39), eye)
	pf.sphere(_mesh_root, 0.025, Vector3(0.055, 0.38, 0.39), eye)
	pf.sphere(_mesh_root, 0.02, Vector3(0, 0.33, 0.41), pf.mat(Color(0.95, 0.6, 0.6), 0.6))
	for i in 4:
		var lx: float = -0.08 if i % 2 == 0 else 0.08
		var lz: float = 0.15 if i < 2 else -0.15
		pf.box(_mesh_root, Vector3(0.06, 0.14, 0.06), Vector3(lx, 0.07, lz), fur)
	_tail = Node3D.new()
	_tail.position = Vector3(0, 0.3, -0.23)
	_mesh_root.add_child(_tail)
	var seg := pf.box(_tail, Vector3(0.05, 0.05, 0.3), Vector3(0, 0.08, -0.14), fur)
	seg.rotation.x = -0.5
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
		_mesh_root.position.y = absf(sin(_t * 14.0)) * 0.04
		_mesh_root.rotation.x = 0.0
	elif d < STOP_DIST or _sit:
		velocity = Vector3.ZERO
		_sit = true
		_mesh_root.position.y = lerpf(_mesh_root.position.y, 0.0, delta * 8.0)
		_mesh_root.rotation.x = lerpf(_mesh_root.rotation.x, -0.25, delta * 4.0)  # duduk: badan sedikit menengadah
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
