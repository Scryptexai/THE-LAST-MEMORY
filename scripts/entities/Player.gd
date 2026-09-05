extends CharacterBody3D
## Player — Ardi. Gerakan third-person + kamera follow + interaksi.
## WASD/joystick kiri bergerak, Shift lari, mouse putar kamera, E interaksi.

@export var walk_speed: float = 3.2
@export var run_speed: float = 6.0
@export var turn_speed: float = 12.0
@export var mouse_sensitivity: float = 0.0032
@export var gravity: float = 22.0

var cam_yaw: float = 0.0
var cam_pitch: float = -0.32
var current_interactable: Node = null
var footstep_timer: float = 0.0
var _mesh_root: Node3D
var _cam_pivot: Node3D
var _cam: Camera3D
var _spring: SpringArm3D
var _anim: AnimationPlayer
var _moving: bool = false
var _running: bool = false


func _ready() -> void:
	add_to_group("player")
	_build_nodes()
	# Bangun avatar Ardi (stylized low-poly).
	var factory := CharacterFactory.new()
	_mesh_root.add_child(factory.build_character("ardi"))


func _build_nodes() -> void:
	# Collision kapsul.
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.5
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)
	# Root mesh + animasi idle buatan kode.
	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	add_child(_mesh_root)
	_anim = AnimationPlayer.new()
	_anim.name = "AnimationPlayer"
	add_child(_anim)
	_make_idle_animation()
	# Rig kamera: pivot -> spring arm -> kamera.
	_cam_pivot = Node3D.new()
	_cam_pivot.name = "CamPivot"
	_cam_pivot.position = Vector3(0, 1.6, 0)
	add_child(_cam_pivot)
	_spring = SpringArm3D.new()
	_spring.name = "SpringArm3D"
	_spring.spring_length = 4.2
	_spring.margin = 0.3
	add_child(_spring)
	_spring.top_level = false
	# Pindahkan spring ke bawah pivot.
	remove_child(_spring)
	_cam_pivot.add_child(_spring)
	_cam = Camera3D.new()
	_cam.name = "Camera3D"
	_cam.fov = 62.0
	_cam.far = 220.0
	_spring.add_child(_cam)
	# Area deteksi interactable.
	var area := Area3D.new()
	area.name = "InteractArea"
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.6
	shape.shape = sphere
	shape.position = Vector3(0, 1.0, 0)
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	floor_snap_length = 0.4


func _make_idle_animation() -> void:
	# Animasi napas: skala Y mesh berdenyut halus.
	var anim := Animation.new()
	anim.resource_name = "idle"
	anim.length = 2.4
	anim.loop_mode = Animation.LOOP_LINEAR
	var track: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, "MeshRoot:scale:y")
	anim.track_insert_key(track, 0.0, 1.0)
	anim.track_insert_key(track, 1.2, 1.035)
	anim.track_insert_key(track, 2.4, 1.0)
	var lib := AnimationLibrary.new()
	lib.add_animation("idle", anim)
	_anim.add_animation_library("default", lib)
	_anim.play("idle")


func _unhandled_input(event: InputEvent) -> void:
	var gm := GameManager
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and gm.is_gameplay_input_active():
		var mm := event as InputEventMouseMotion
		cam_yaw -= mm.relative.x * mouse_sensitivity
		cam_pitch = clampf(cam_pitch - mm.relative.y * mouse_sensitivity, -1.1, 0.45)


func _physics_process(delta: float) -> void:
	var gm := GameManager
	var can_move: bool = gm.is_gameplay_input_active()
	# Gravitasi selalu berlaku.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.5
	var input_dir := Vector2.ZERO
	if can_move:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		_running = Input.is_action_pressed("run") and input_dir.length() > 0.1
	else:
		_running = false
	var speed: float = run_speed if _running else walk_speed
	_moving = input_dir.length() > 0.1
	if _moving:
		var forward: Vector3 = -_cam_pivot.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()
		var right: Vector3 = _cam_pivot.global_transform.basis.x
		right.y = 0
		right = right.normalized()
		var wish: Vector3 = (right * input_dir.x + forward * -input_dir.y)
		if wish.length() > 0.01:
			wish = wish.normalized()
			velocity.x = wish.x * speed
			velocity.z = wish.z * speed
			var target_yaw: float = atan2(wish.x, wish.z)
			_mesh_root.rotation.y = MathUtils.lerp_angle_stable(_mesh_root.rotation.y, target_yaw, delta * turn_speed)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
	move_and_slide()
	_update_camera(delta)
	_update_footsteps(delta)


func _update_camera(_delta: float) -> void:
	_cam_pivot.rotation.y = cam_yaw
	_cam_pivot.rotation.x = cam_pitch


func _update_footsteps(delta: float) -> void:
	if not _moving or not is_on_floor():
		footstep_timer = 0.0
		return
	footstep_timer -= delta
	if footstep_timer <= 0.0:
		footstep_timer = 0.34 if _running else 0.5
		var surface: String = "grass"
		if abs(global_position.y) < 0.6:
			# Di dalam/lok Atas lantai kayu vs luar — pendekatan sederhana:
			# lokasi rumah/kafe/stasiun memakai langkah kayu.
			var loc: String = GameManager.current_location
			if loc in ["rumah_nenek", "kafe_rara", "stasiun"]:
				surface = "wood"
		SignalBus.sfx_requested.emit("sfx_footstep_" + surface)


# ---------- Interaksi ----------

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("interactable") and body.has_method("get_prompt"):
		_set_current(body)


func _on_body_exited(body: Node3D) -> void:
	if body == current_interactable:
		_set_current(null)


func _set_current(body: Node) -> void:
	if current_interactable and is_instance_valid(current_interactable) and current_interactable.has_method("set_highlight"):
		current_interactable.set_highlight(false)
	current_interactable = body
	var bus := SignalBus
	if current_interactable and current_interactable.has_method("set_highlight"):
		current_interactable.set_highlight(true)
		bus.prompt_requested.emit(str(current_interactable.get_prompt()))
	else:
		bus.prompt_cleared.emit()


func _input(event: InputEvent) -> void:
	var gm := GameManager
	if event.is_action_pressed("interact") and gm.is_gameplay_input_active():
		try_interact()
	# Klik untuk mengunci mouse kembali saat lepas di gameplay.
	if event is InputEventMouseButton and gm.is_gameplay_input_active():
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func try_interact() -> void:
	# Pilih interactable terdekat yang valid (pengecekan ulang jarak).
	if current_interactable == null or not is_instance_valid(current_interactable):
		_refresh_nearest()
	if current_interactable and is_instance_valid(current_interactable) and current_interactable.has_method("interact"):
		current_interactable.interact(self)


func _refresh_nearest() -> void:
	var best: Node3D = null
	var best_d: float = 3.0
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is Node3D and (n as Node3D).has_method("get_prompt"):
			var d: float = global_position.distance_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n
	if best:
		_set_current(best)


## Teleportasi ke spawn point lokasi (dipakai saat pindah lokasi).
func place_at(pos: Vector3, yaw: float) -> void:
	global_position = pos
	cam_yaw = yaw
	_mesh_root.rotation.y = yaw
	velocity = Vector3.ZERO
	_set_current(null)
