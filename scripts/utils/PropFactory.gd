class_name PropFactory
extends RefCounted
## PropFactory — membangun geometri low-poly prosedural (rumah, furnitur,
## pepohonan, kereta, dsb.) agar game tampil utuh tanpa file model eksternal.
## Gaya visual: "diorama miniatur" hangat-nostalgis.

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 2026


# ---------- Material & mesh dasar ----------

func mat(color: Color, rough: float = 0.85, emission: Color = Color(0, 0, 0, 1), energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m


func box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, collide: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	if material:
		mi.material_override = material
	parent.add_child(mi)
	if collide:
		_add_static_collision(mi, BoxShape3D.new(), size)
	return mi


func cyl(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material, collide: bool = false, sides: int = 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	mi.mesh = mesh
	mi.position = pos
	if material:
		mi.material_override = material
	parent.add_child(mi)
	if collide:
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		_add_static_collision(mi, shape, Vector3.ZERO)
	return mi


func sphere(parent: Node3D, radius: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mi.mesh = mesh
	mi.position = pos
	if material:
		mi.material_override = material
	parent.add_child(mi)
	return mi


func plane_ground(parent: Node3D, size: Vector2, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	if material:
		mi.material_override = material
	parent.add_child(mi)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var world := WorldBoundaryShape3D.new()
	world.plane = Plane(Vector3.UP, -pos.y)
	shape.shape = world
	body.add_child(shape)
	body.position = pos
	parent.add_child(body)
	return mi


func _add_static_collision(mi: MeshInstance3D, shape: Shape3D, box_size: Vector3) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	if shape is BoxShape3D:
		(shape as BoxShape3D).size = box_size
	col.shape = shape
	mi.add_child(body)
	body.add_child(col)


# ---------- Elemen bangunan ----------

func make_wall(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	return box(parent, size, pos, mat(color), true)


func make_roof_prism(parent: Node3D, width: float, height: float, depth: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(width, height, depth)
	mi.mesh = prism
	mi.position = pos
	mi.material_override = mat(color, 0.7)
	parent.add_child(mi)
	return mi


func make_door_frame(parent: Node3D, pos: Vector3, rot_y: float, w: float = 1.4, h: float = 2.6) -> void:
	var frame := mat(Color(0.35, 0.22, 0.12))
	var pivot := Node3D.new()
	pivot.position = pos
	pivot.rotation.y = rot_y
	parent.add_child(pivot)
	box(pivot, Vector3(0.18, h, 0.3), Vector3(-w / 2, h / 2, 0), frame)
	box(pivot, Vector3(0.18, h, 0.3), Vector3(w / 2, h / 2, 0), frame)
	box(pivot, Vector3(w + 0.36, 0.22, 0.3), Vector3(0, h + 0.1, 0), frame)


func make_window(parent: Node3D, pos: Vector3, rot_y: float, w: float = 1.2, h: float = 1.2, lit: bool = true) -> void:
	var pivot := Node3D.new()
	pivot.position = pos
	pivot.rotation.y = rot_y
	parent.add_child(pivot)
	box(pivot, Vector3(w + 0.2, h + 0.2, 0.12), Vector3.ZERO, mat(Color(0.3, 0.2, 0.12)))
	var glow := Color(1.0, 0.82, 0.5) if lit else Color(0.2, 0.28, 0.36)
	box(pivot, Vector3(w, h, 0.14), Vector3.ZERO, mat(glow, 0.4, glow, 1.2 if lit else 0.0))
	box(pivot, Vector3(0.08, h, 0.16), Vector3.ZERO, mat(Color(0.3, 0.2, 0.12)))
	box(pivot, Vector3(w, 0.08, 0.16), Vector3.ZERO, mat(Color(0.3, 0.2, 0.12)))


# ---------- Furnitur ----------

func make_table(parent: Node3D, pos: Vector3, wood: Color = Color(0.45, 0.3, 0.16)) -> Node3D:
	var t := Node3D.new()
	t.position = pos
	parent.add_child(t)
	var m := mat(wood, 0.7)
	box(t, Vector3(1.6, 0.1, 1.0), Vector3(0, 0.75, 0), m, true)
	for sx in [-0.7, 0.7]:
		for sz in [-0.4, 0.4]:
			box(t, Vector3(0.09, 0.75, 0.09), Vector3(sx, 0.37, sz), m)
	return t


func make_chair(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var c := Node3D.new()
	c.position = pos
	c.rotation.y = rot_y
	parent.add_child(c)
	var m := mat(Color(0.42, 0.28, 0.15), 0.7)
	box(c, Vector3(0.45, 0.07, 0.45), Vector3(0, 0.45, 0), m)
	box(c, Vector3(0.45, 0.55, 0.07), Vector3(0, 0.75, -0.2), m)
	for sx in [-0.18, 0.18]:
		for sz in [-0.18, 0.18]:
			box(c, Vector3(0.06, 0.45, 0.06), Vector3(sx, 0.22, sz), m)
	return c


func make_shelf(parent: Node3D, pos: Vector3, rot_y: float, color: Color = Color(0.4, 0.26, 0.14)) -> Node3D:
	var s := Node3D.new()
	s.position = pos
	s.rotation.y = rot_y
	parent.add_child(s)
	var m := mat(color, 0.75)
	box(s, Vector3(2.2, 2.0, 0.4), Vector3(0, 1.0, 0), m, true)
	# Buku warna-warni.
	var palette := [Color(0.7, 0.25, 0.25), Color(0.25, 0.45, 0.7), Color(0.85, 0.65, 0.2), Color(0.3, 0.55, 0.35), Color(0.6, 0.35, 0.6)]
	for row in 3:
		var y: float = 0.55 + row * 0.55
		for i in 8:
			var bc: Color = palette[_rng.randi() % palette.size()]
			box(s, Vector3(0.16, 0.4, 0.22), Vector3(-0.9 + i * 0.24, y, 0.12), mat(bc, 0.8))
	return s


func make_bed(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var b := Node3D.new()
	b.position = pos
	b.rotation.y = rot_y
	parent.add_child(b)
	var wood := mat(Color(0.4, 0.26, 0.14))
	box(b, Vector3(1.6, 0.35, 2.4), Vector3(0, 0.3, 0), wood, true)
	box(b, Vector3(1.5, 0.22, 2.2), Vector3(0, 0.58, 0), mat(Color(0.92, 0.88, 0.8), 0.9))
	box(b, Vector3(1.2, 0.18, 0.5), Vector3(0, 0.7, -0.8), mat(Color(1, 1, 1), 0.9))
	box(b, Vector3(1.6, 0.9, 0.12), Vector3(0, 0.7, -1.2), wood)
	return b


func make_counter(parent: Node3D, pos: Vector3, rot_y: float, w: float = 3.0) -> Node3D:
	var c := Node3D.new()
	c.position = pos
	c.rotation.y = rot_y
	parent.add_child(c)
	box(c, Vector3(w, 1.0, 0.8), Vector3(0, 0.5, 0), mat(Color(0.45, 0.3, 0.16), 0.7), true)
	box(c, Vector3(w + 0.2, 0.08, 1.0), Vector3(0, 1.04, 0), mat(Color(0.6, 0.42, 0.22), 0.6))
	return c


func make_lamp(parent: Node3D, pos: Vector3, warm: Color = Color(1.0, 0.75, 0.45)) -> OmniLight3D:
	cyl(parent, 0.06, 1.7, pos + Vector3(0, 0.85, 0), mat(Color(0.2, 0.2, 0.22), 0.5))
	sphere(parent, 0.22, pos + Vector3(0, 1.8, 0), mat(warm, 0.4, warm, 2.0))
	var light := FlickerLight.new()
	light.position = pos + Vector3(0, 1.8, 0)
	light.light_color = warm
	light.light_energy = 0.9
	light.omni_range = 7.0
	light.shadow_enabled = false
	parent.add_child(light)
	return light


func make_crate(parent: Node3D, pos: Vector3, size: float = 0.8) -> MeshInstance3D:
	var mi := box(parent, Vector3(size, size, size), pos + Vector3(0, size / 2, 0), mat(Color(0.55, 0.4, 0.22), 0.85), true)
	# Palang.
	box(parent, Vector3(size * 1.02, size * 0.12, size * 1.02), pos + Vector3(0, size / 2, 0), mat(Color(0.45, 0.32, 0.16), 0.85))
	return mi


# ---------- Alam & kota ----------

func make_tree(parent: Node3D, pos: Vector3, s: float = 1.0) -> void:
	cyl(parent, 0.14 * s, 1.8 * s, pos + Vector3(0, 0.9 * s, 0), mat(Color(0.35, 0.22, 0.12)), true)
	var leaf := mat(Color(0.25, 0.45, 0.22), 0.9)
	sphere(parent, 1.0 * s, pos + Vector3(0, 2.2 * s, 0), leaf)
	sphere(parent, 0.7 * s, pos + Vector3(0.6 * s, 1.8 * s, 0.2), leaf)
	sphere(parent, 0.7 * s, pos + Vector3(-0.6 * s, 1.9 * s, -0.1), leaf)


func make_palm(parent: Node3D, pos: Vector3, s: float = 1.0) -> void:
	var trunk := cyl(parent, 0.12 * s, 3.4 * s, pos + Vector3(0, 1.7 * s, 0), mat(Color(0.45, 0.32, 0.2)), true)
	trunk.rotation.z = 0.08
	var leaf := mat(Color(0.3, 0.52, 0.25), 0.9)
	for i in 6:
		var frond := box(parent, Vector3(1.6 * s, 0.06, 0.3 * s), pos + Vector3(0, 3.4 * s, 0), leaf)
		frond.rotation.y = TAU * float(i) / 6.0
		frond.position += Vector3(cos(TAU * i / 6.0) * 0.7 * s, -0.15, sin(TAU * i / 6.0) * 0.7 * s)
		frond.rotation.z = -0.25


func make_streetlamp(parent: Node3D, pos: Vector3) -> void:
	cyl(parent, 0.08, 3.6, pos + Vector3(0, 1.8, 0), mat(Color(0.15, 0.15, 0.18), 0.5), true)
	box(parent, Vector3(0.5, 0.35, 0.5), pos + Vector3(0, 3.7, 0), mat(Color(1.0, 0.8, 0.5), 0.4, Color(1.0, 0.8, 0.5), 2.5))
	var light := FlickerLight.new()
	light.position = pos + Vector3(0, 3.6, 0)
	light.light_color = Color(1.0, 0.8, 0.55)
	light.light_energy = 1.2
	light.omni_range = 10.0
	parent.add_child(light)


func make_fence(parent: Node3D, from: Vector3, to: Vector3, h: float = 1.0) -> void:
	var dir: Vector3 = to - from
	var length: float = dir.length()
	var pivot := Node3D.new()
	pivot.position = (from + to) / 2
	pivot.rotation.y = atan2(-dir.x, -dir.z) + PI / 2
	parent.add_child(pivot)
	var m := mat(Color(0.5, 0.36, 0.2), 0.85)
	box(pivot, Vector3(length, 0.08, 0.06), Vector3(0, h, 0), m)
	box(pivot, Vector3(length, 0.08, 0.06), Vector3(0, h * 0.55, 0), m)
	var posts: int = int(length / 1.5) + 1
	for i in posts:
		box(pivot, Vector3(0.09, h + 0.1, 0.09), Vector3(-length / 2 + i * 1.5, (h + 0.1) / 2, 0), m)


# ---------- Kereta & rel ----------

func make_rails(parent: Node3D, from: Vector3, to: Vector3) -> void:
	var dir: Vector3 = to - from
	var length: float = Vector3(dir.x, 0, dir.z).length()
	var pivot := Node3D.new()
	pivot.position = (from + to) / 2
	pivot.rotation.y = atan2(-dir.x, -dir.z) + PI / 2
	parent.add_child(pivot)
	var steel := mat(Color(0.5, 0.52, 0.55), 0.35)
	box(pivot, Vector3(length, 0.12, 0.08), Vector3(0, 0.06, -0.75), steel)
	box(pivot, Vector3(length, 0.12, 0.08), Vector3(0, 0.06, 0.75), steel)
	var ties: int = int(length / 0.9)
	for i in ties:
		box(pivot, Vector3(0.3, 0.08, 2.0), Vector3(-length / 2 + i * 0.9, 0.0, 0), mat(Color(0.35, 0.24, 0.14), 0.9))


func make_train_car(parent: Node3D, pos: Vector3, rot_y: float, body_color: Color = Color(0.5, 0.16, 0.12)) -> Node3D:
	var car := Node3D.new()
	car.position = pos
	car.rotation.y = rot_y
	parent.add_child(car)
	box(car, Vector3(7.0, 2.2, 2.4), Vector3(0, 1.7, 0), mat(body_color, 0.6), true)
	box(car, Vector3(7.2, 0.25, 2.5), Vector3(0, 2.9, 0), mat(Color(0.25, 0.25, 0.28), 0.7))
	box(car, Vector3(7.0, 0.5, 2.2), Vector3(0, 0.45, 0), mat(Color(0.18, 0.18, 0.2), 0.8))
	for i in 5:
		box(car, Vector3(0.9, 0.9, 2.44), Vector3(-2.6 + i * 1.3, 1.9, 0), mat(Color(0.75, 0.85, 0.9), 0.25))
	for wx in [-2.2, 2.2]:
		for wz in [-0.9, 0.9]:
			var wheel := cyl(car, 0.4, 0.15, Vector3(wx, 0.4, wz), mat(Color(0.12, 0.12, 0.14), 0.6))
			wheel.rotation.x = PI / 2
	return car


# ---------- Dekorasi kecil ----------

func make_photo_frame(parent: Node3D, pos: Vector3, rot_y: float, w: float = 0.5, h: float = 0.65) -> void:
	var pivot := Node3D.new()
	pivot.position = pos
	pivot.rotation.y = rot_y
	parent.add_child(pivot)
	box(pivot, Vector3(w + 0.08, h + 0.08, 0.05), Vector3.ZERO, mat(Color(0.62, 0.45, 0.2), 0.5))
	box(pivot, Vector3(w, h, 0.06), Vector3.ZERO, mat(Color(0.82, 0.78, 0.68), 0.9))
	# Siluet "foto": lingkaran kepala + badan.
	var inner := box(pivot, Vector3(w * 0.7, h * 0.45, 0.065), Vector3(0, -0.05, 0), mat(Color(0.45, 0.42, 0.38), 0.9))
	inner.rotation.z = 0.0
	sphere(pivot, w * 0.16, Vector3(0, h * 0.18, 0.04), mat(Color(0.6, 0.58, 0.52), 0.9))


func make_cup(parent: Node3D, pos: Vector3, color: Color = Color(0.9, 0.85, 0.75)) -> void:
	cyl(parent, 0.06, 0.1, pos + Vector3(0, 0.05, 0), mat(color, 0.6), false, 8)


func make_book_stack(parent: Node3D, pos: Vector3) -> void:
	var palette := [Color(0.7, 0.25, 0.25), Color(0.25, 0.45, 0.7), Color(0.85, 0.65, 0.2)]
	for i in 3:
		var b := box(parent, Vector3(0.4, 0.07, 0.3), pos + Vector3(0, 0.035 + i * 0.07, 0), mat(palette[i], 0.8))
		b.rotation.y = _rng.randf() * 0.6 - 0.3


func make_rug(parent: Node3D, pos: Vector3, size: Vector2, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos + Vector3(0, 0.02, 0)
	mi.material_override = mat(color, 0.95)
	parent.add_child(mi)


## Partikel debu melayang (untuk loteng / ruangan bernostalgia).
func make_dust_motes(parent: Node3D, center: Vector3, extents: Vector3, tint: Color = Color(1.0, 0.92, 0.75, 0.45)) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 48
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.position = center
	var mat_proc := ParticleProcessMaterial.new()
	mat_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat_proc.emission_box_extents = extents
	mat_proc.gravity = Vector3.ZERO
	mat_proc.initial_velocity_min = 0.05
	mat_proc.initial_velocity_max = 0.18
	mat_proc.direction = Vector3(0, 1, 0)
	mat_proc.spread = 35.0
	mat_proc.scale_min = 0.02
	mat_proc.scale_max = 0.05
	mat_proc.color = Color(tint.r, tint.g, tint.b, 0.5)
	p.process_material = mat_proc
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	var qmat := StandardMaterial3D.new()
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.albedo_color = tint
	qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = qmat
	p.draw_pass_1 = quad
	parent.add_child(p)
	return p
