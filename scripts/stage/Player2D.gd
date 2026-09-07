class_name Player2D
extends Actor2D
## Player2D — Ardi di panggung 2D. Gerak dengan A/D (kiri-kanan) + W/S (jauh-dekat)
## atau klik lantai (point-and-click); Shift lari; E / klik hotspot berinteraksi.
## Objek terdekat (dalam jangkauan) disorot dan prompt ditampilkan di HUD.

const WALK_SPEED := 210.0   # px desain/detik pada skala penuh
const RUN_SPEED := 380.0
const REACH := 150.0        # jangkauan interaksi horizontal (px desain)

var current_interactable: Node = null
var _click_target: Vector2 = Vector2.INF
var _click_interact: Node = null
var _footstep_timer: float = 0.0
var _step_parity: bool = false
var _surface: String = "wood"
var _refresh_cd: float = 0.0


func _ready() -> void:
	super()
	add_to_group("player")
	character_id = "ardi"
	display_name = "Ardi"
	load_sprite("ardi")
	z_as_relative = false


func set_surface(s: String) -> void:
	_surface = s


func _process(delta: float) -> void:
	super(delta)
	var gm := GameManager
	var can_move: bool = gm.is_gameplay_input_active()
	var input_dir := Vector2.ZERO
	if can_move:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		running = Input.is_action_pressed("run")
	else:
		running = false
		_click_target = Vector2.INF
		_click_interact = null
	var vel := Vector2.ZERO
	if input_dir.length() > 0.1:
		_click_target = Vector2.INF
		_click_interact = null
		vel = Vector2(input_dir.x, input_dir.y * 0.45).normalized() * input_dir.length()
	elif _click_target != Vector2.INF:
		var to: Vector2 = _click_target - position
		if to.length() < 6.0:
			position = _click_target
			_click_target = Vector2.INF
			if _click_interact and is_instance_valid(_click_interact):
				_set_current(_click_interact)
				try_interact()
			_click_interact = null
		else:
			vel = to.normalized()
			if to.length() < 40.0:
				vel *= maxf(to.length() / 40.0, 0.35)
	moving = vel.length() > 0.05
	if moving:
		var spd: float = (RUN_SPEED if running else WALK_SPEED) * (view_scale() / 0.35)
		var step: Vector2 = vel * spd * delta
		if _click_target != Vector2.INF and step.length() > (_click_target - position).length():
			step = _click_target - position
		position = clamp_to_floor(position + step)
		if absf(vel.x) > 0.05:
			facing_left = vel.x < 0.0
	_update_footsteps(delta)
	_refresh_cd -= delta
	if _refresh_cd <= 0.0:
		_refresh_cd = 0.12
		_refresh_nearest()


func _update_footsteps(delta: float) -> void:
	if not moving:
		_footstep_timer = 0.0
		return
	_footstep_timer -= delta
	if _footstep_timer <= 0.0:
		_footstep_timer = 0.3 if running else 0.46
		_step_parity = not _step_parity
		SignalBus.sfx_requested.emit("sfx_footstep_" + _surface + ("" if _step_parity else "_b"))


## Perintah klik lantai / klik objek dari Stage2D.
func walk_to(p: Vector2, then_interact: Node = null) -> void:
	_click_target = clamp_to_floor(p)
	_click_interact = then_interact


func cancel_walk() -> void:
	_click_target = Vector2.INF
	_click_interact = null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and GameManager.is_gameplay_input_active():
		try_interact()
		get_viewport().set_input_as_handled()


func try_interact() -> void:
	_refresh_nearest()
	if current_interactable and is_instance_valid(current_interactable) and current_interactable.has_method("interact"):
		# Hadap ke objek.
		if current_interactable is Node2D:
			face_towards((current_interactable as Node2D).position.x)
		current_interactable.interact(self)


## Jarak "efektif" ke objek: horizontal penuh, vertikal (kedalaman) diperkecil.
func _dist_to(n: Node2D) -> float:
	var stand: Vector2 = n.position
	if n is Hotspot2D:
		stand = (n as Hotspot2D).stand
	var d := stand - position
	return Vector2(d.x, d.y * 1.6).length()


func _refresh_nearest() -> void:
	var best: Node = null
	var best_d: float = REACH * (view_scale() / 0.35)
	for n in get_tree().get_nodes_in_group("interactable"):
		if n == self or not (n is Node2D) or not n.has_method("interact"):
			continue
		if n.has_method("_is_active") and not GameManager.truthy(n.call("_is_active")):
			continue
		var d: float = _dist_to(n as Node2D)
		if d < best_d:
			best_d = d
			best = n
	if best != current_interactable:
		_set_current(best)


func _set_current(body: Node) -> void:
	if current_interactable and is_instance_valid(current_interactable) and current_interactable.has_method("set_highlight"):
		current_interactable.set_highlight(false)
	current_interactable = body
	var bus := SignalBus
	if current_interactable and is_instance_valid(current_interactable) and current_interactable.has_method("set_highlight"):
		current_interactable.set_highlight(true)
		bus.prompt_requested.emit(str(current_interactable.get_prompt()))
	else:
		bus.prompt_cleared.emit()


## Teleport ke titik spawn (dipakai Stage2D.enter()).
func place_at(p: Vector2, flip: bool) -> void:
	position = clamp_to_floor(p)
	facing_left = flip
	cancel_walk()
	_set_current(null)
