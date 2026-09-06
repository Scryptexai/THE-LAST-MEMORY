class_name CharacterAnimator
extends RefCounted
## CharacterAnimator — animasi prosedural untuk rig CharacterFactory:
## siklus jalan (ayun lengan/kaki berlawanan, tekuk lutut/siku, goyang pinggul,
## bob badan), idle bernapas + gestur kecil, menoleh ke target, lambaian tangan.
##
## Pakai:
##   var anim := CharacterAnimator.new(avatar)
##   anim.update(delta, speed_normalized)  # 0 = diam, 1 = jalan, 2 = lari
##   anim.look_at_point(world_pos)         # opsional, kepala menoleh
##   anim.wave(1.4)                        # lambaian 1.4 detik

var _b: Dictionary = {}
var _root: Node3D
var _phase: float = 0.0
var _t: float = 0.0
var _wave_left: float = 0.0
var _look_target: Vector3 = Vector3.INF
var _look_yaw: float = 0.0
var _look_pitch: float = 0.0
var _blink_t: float = 2.5
var _blink_left: float = 0.0
var _eyes: Array = []
var _hips_y0: float = 0.0
var _valid: bool = false
var _idle_seed: float = 0.0


func _init(avatar: Node3D) -> void:
	_root = avatar
	if avatar == null or not avatar.has_meta("bones"):
		return
	_b = avatar.get_meta("bones")
	_valid = _b.has("hips") and _b.has("head")
	if _valid:
		_hips_y0 = (_b["hips"] as Node3D).position.y
		var head: Node3D = _b["head"]
		for c in head.get_children():
			if c.name.begins_with("Eye"):
				_eyes.append(c)
	_idle_seed = randf() * TAU


func is_valid() -> bool:
	return _valid


## speed: 0 diam, ~1 jalan, ~2 lari. grounded: menyentuh tanah.
func update(delta: float, speed: float, grounded: bool = true) -> void:
	if not _valid:
		return
	_t += delta
	var moving: bool = speed > 0.05 and grounded
	var k: float = clampf(speed, 0.0, 2.0)
	if moving:
		_phase += delta * (6.5 + 4.5 * k)
	else:
		# Kembalikan fase ke kelipatan π agar kaki menutup rapi.
		var target: float = roundf(_phase / PI) * PI
		_phase = lerpf(_phase, target, delta * 10.0)
	var sw: float = sin(_phase)
	var cw: float = cos(_phase)
	var amp: float = (0.55 + 0.35 * k) if moving else 0.0
	var blend: float = clampf(k, 0.0, 1.0) if moving else 0.0

	# ---- Kaki ----
	_rot_x(_b.get("upleg_l"), sw * amp, delta)
	_rot_x(_b.get("upleg_r"), -sw * amp, delta)
	# Lutut menekuk saat kaki di belakang/ayun ke depan.
	_rot_x(_b.get("knee_l"), maxf(0.0, -sw) * amp * 1.4 + 0.05, delta)
	_rot_x(_b.get("knee_r"), maxf(0.0, sw) * amp * 1.4 + 0.05, delta)

	# ---- Lengan ----
	var arm_amp: float = amp * 0.75
	var sh_l: Node3D = _b.get("shoulder_l")
	var sh_r: Node3D = _b.get("shoulder_r")
	var idle_sway: float = sin(_t * 1.3 + _idle_seed) * 0.03
	if _wave_left > 0.0:
		_wave_left -= delta
		# Tangan kanan terangkat & melambai; siku menekuk.
		_lerp_rot(sh_r, Vector3(-2.5, 0.0, -0.9 + sin(_t * 13.0) * 0.3), delta * 10.0)
		_lerp_rot(_b.get("elbow_r"), Vector3(-0.6, 0.0, sin(_t * 13.0) * 0.5), delta * 10.0)
	else:
		_lerp_rot(sh_r, Vector3(sw * arm_amp, 0.0, -0.12 + idle_sway), delta * 8.0)
		_lerp_rot(_b.get("elbow_r"), Vector3(-0.25 - maxf(0.0, sw) * amp * 0.6, 0.0, 0.0), delta * 8.0)
	_lerp_rot(sh_l, Vector3(-sw * arm_amp, 0.0, 0.12 - idle_sway), delta * 8.0)
	_lerp_rot(_b.get("elbow_l"), Vector3(-0.25 - maxf(0.0, -sw) * amp * 0.6, 0.0, 0.0), delta * 8.0)

	# ---- Pinggul / badan ----
	var hips: Node3D = _b["hips"]
	var bob: float = absf(cw) * (0.035 + 0.03 * k) * blend
	var breathe: float = sin(_t * 1.6 + _idle_seed) * 0.004
	hips.position.y = lerpf(hips.position.y, _hips_y0 + bob + breathe, delta * 12.0)
	hips.rotation.z = lerpf(hips.rotation.z, sw * 0.06 * blend, delta * 8.0)
	hips.rotation.y = lerpf(hips.rotation.y, -sw * 0.10 * blend, delta * 8.0)
	var spine: Node3D = _b.get("spine")
	if spine:
		spine.rotation.y = lerpf(spine.rotation.y, sw * 0.12 * blend, delta * 8.0)
		spine.rotation.x = lerpf(spine.rotation.x, 0.06 * blend * k + sin(_t * 1.6 + _idle_seed) * 0.01, delta * 6.0)
	var chest: Node3D = _b.get("chest")
	if chest:
		chest.rotation.x = lerpf(chest.rotation.x, sin(_t * 1.6 + _idle_seed + 0.6) * 0.015, delta * 6.0)

	# ---- Kepala: menoleh + gestur idle kecil ----
	var head: Node3D = _b["head"]
	var want_yaw: float = sin(_t * 0.45 + _idle_seed) * 0.08
	var want_pitch: float = sin(_t * 0.7 + _idle_seed * 0.5) * 0.03
	if _look_target != Vector3.INF:
		var local: Vector3 = head.get_parent().to_local(_look_target) - head.position
		var yaw: float = atan2(local.x, local.z)
		var pitch: float = -atan2(local.y, Vector2(local.x, local.z).length())
		# Batasi agar leher tidak patah.
		want_yaw = clampf(wrapf(yaw, -PI, PI), -1.1, 1.1)
		want_pitch = clampf(pitch, -0.45, 0.35)
	_look_yaw = lerp_angle(_look_yaw, want_yaw, delta * 4.0)
	_look_pitch = lerpf(_look_pitch, want_pitch, delta * 4.0)
	head.rotation = Vector3(_look_pitch, _look_yaw, sin(_t * 0.6 + _idle_seed) * 0.02)
	var neck: Node3D = _b.get("neck")
	if neck:
		neck.rotation.y = _look_yaw * 0.35

	# ---- Kedip ----
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink_t = randf_range(2.2, 5.5)
		_blink_left = 0.14
	if _blink_left > 0.0:
		_blink_left -= delta
		var sy: float = 0.08 if _blink_left > 0.04 else 0.6
		for e in _eyes:
			(e as Node3D).scale.y = sy
	else:
		for e in _eyes:
			(e as Node3D).scale.y = lerpf((e as Node3D).scale.y, 1.0, delta * 20.0)


## Kepala (dan sedikit leher) menoleh ke titik dunia; Vector3.INF = bebas.
func look_at_point(world_pos: Vector3) -> void:
	_look_target = world_pos


func clear_look() -> void:
	_look_target = Vector3.INF


func wave(duration: float = 1.4) -> void:
	_wave_left = duration


func is_waving() -> bool:
	return _wave_left > 0.0


## Pose duduk sederhana (untuk NPC yang duduk): paha 90°, lutut 90°.
func sit_pose() -> void:
	if not _valid:
		return
	for nm in ["upleg_l", "upleg_r"]:
		(_b[nm] as Node3D).rotation.x = -1.5
	for nm in ["knee_l", "knee_r"]:
		(_b[nm] as Node3D).rotation.x = 1.5
	(_b["hips"] as Node3D).position.y = _hips_y0 - 0.42


func _rot_x(n: Node3D, target: float, delta: float) -> void:
	if n == null:
		return
	n.rotation.x = lerpf(n.rotation.x, target, delta * 10.0)


func _lerp_rot(n: Node3D, target: Vector3, w: float) -> void:
	if n == null:
		return
	var k: float = clampf(w, 0.0, 1.0)
	n.rotation = Vector3(lerpf(n.rotation.x, target.x, k), lerp_angle(n.rotation.y, target.y, k), lerpf(n.rotation.z, target.z, k))
