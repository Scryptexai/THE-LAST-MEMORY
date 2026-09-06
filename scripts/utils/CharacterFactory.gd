class_name CharacterFactory
extends RefCounted
## CharacterFactory — avatar humanoid bergaya anime (cel-shaded) untuk tiap tokoh.
##
## Rig prosedural berjenjang (Hips → Spine → Chest → Neck → Head; Shoulder → Elbow;
## Hip → Knee) dari kapsul/silinder/bola bergaya toon, garis tepi (outline) hitam
## tipis, mata anime bertekstur prosedural, rambut per tokoh, dan pakaian khas.
## Animasi (jalan/idle/lambai/menoleh) dijalankan oleh CharacterAnimator.
##
## Proporsi ~6.5 kepala, tinggi ≈ 1.72 m (nenek/anak lebih pendek).

const OUTLINE := 0.014

const PALETTES := {
	"ardi": {"skin": Color(0.96, 0.80, 0.66), "top": Color(0.16, 0.30, 0.52), "bottom": Color(0.22, 0.22, 0.27), "hair": Color(0.10, 0.09, 0.10), "eye": Color(0.28, 0.17, 0.10), "shoe": Color(0.25, 0.18, 0.12), "height": 1.74, "female": false, "age": "young"},
	"rara": {"skin": Color(0.98, 0.84, 0.72), "top": Color(0.95, 0.56, 0.30), "bottom": Color(0.36, 0.22, 0.30), "hair": Color(0.42, 0.24, 0.12), "eye": Color(0.45, 0.25, 0.12), "shoe": Color(0.6, 0.35, 0.25), "height": 1.62, "female": true, "age": "young"},
	"pak_harto": {"skin": Color(0.88, 0.70, 0.56), "top": Color(0.55, 0.50, 0.40), "bottom": Color(0.28, 0.25, 0.22), "hair": Color(0.78, 0.78, 0.78), "eye": Color(0.25, 0.18, 0.12), "shoe": Color(0.15, 0.1, 0.08), "height": 1.68, "female": false, "age": "old"},
	"mira": {"skin": Color(0.95, 0.78, 0.64), "top": Color(0.16, 0.48, 0.44), "bottom": Color(0.14, 0.17, 0.24), "hair": Color(0.07, 0.07, 0.09), "eye": Color(0.15, 0.12, 0.12), "shoe": Color(0.1, 0.1, 0.12), "height": 1.66, "female": true, "age": "young"},
	"nenek": {"skin": Color(0.88, 0.70, 0.56), "top": Color(0.56, 0.30, 0.46), "bottom": Color(0.30, 0.22, 0.28), "hair": Color(0.82, 0.82, 0.84), "eye": Color(0.3, 0.2, 0.14), "shoe": Color(0.3, 0.2, 0.15), "height": 1.55, "female": true, "age": "old"},
	"darmo": {"skin": Color(0.90, 0.72, 0.58), "top": Color(0.18, 0.22, 0.38), "bottom": Color(0.16, 0.18, 0.28), "hair": Color(0.12, 0.10, 0.09), "eye": Color(0.25, 0.16, 0.1), "shoe": Color(0.12, 0.1, 0.08), "height": 1.72, "female": false, "age": "adult"},
	"bu_rt": {"skin": Color(0.92, 0.75, 0.60), "top": Color(0.62, 0.42, 0.56), "bottom": Color(0.32, 0.24, 0.32), "hair": Color(0.25, 0.2, 0.2), "eye": Color(0.3, 0.2, 0.14), "shoe": Color(0.35, 0.25, 0.2), "height": 1.58, "female": true, "age": "adult"},
	"warga": {"skin": Color(0.86, 0.66, 0.50), "top": Color(0.50, 0.52, 0.56), "bottom": Color(0.30, 0.30, 0.33), "hair": Color(0.18, 0.16, 0.14), "eye": Color(0.22, 0.15, 0.1), "shoe": Color(0.4, 0.3, 0.2), "height": 1.68, "female": false, "age": "adult"},
}

static var _eye_tex_cache: Dictionary = {}


## Bangun avatar. Mengembalikan Node3D root; tulang tersedia lewat metadata "bones"
## (Dictionary nama → Node3D) untuk CharacterAnimator.
func build_character(char_id: String) -> Node3D:
	var key: String = char_id if PALETTES.has(char_id) else "warga"
	var pal: Dictionary = PALETTES[key]
	var s: float = float(pal["height"]) / 1.74  # skala relatif Ardi
	var female: bool = bool(pal["female"])
	var root := Node3D.new()
	root.name = "Avatar_" + key
	var bones: Dictionary = {}

	var m_skin := toon(pal["skin"], 0.75)
	var m_top := toon(pal["top"], 0.9)
	var m_bottom := toon(pal["bottom"], 0.9)
	var m_hair := toon(pal["hair"], 0.6)
	var m_shoe := toon(pal["shoe"], 0.85)

	# ---------- Torso ----------
	var hips := _bone(root, "Hips", Vector3(0, 0.98 * s, 0))
	bones["hips"] = hips
	var hip_w: float = (0.15 if female else 0.17) * s
	_capsule(hips, hip_w * 1.05, 0.10 * s, Vector3(0, -0.02 * s, 0), m_bottom, Vector3(1.0, 0.7, 0.75))
	var spine := _bone(hips, "Spine", Vector3(0, 0.10 * s, 0))
	bones["spine"] = spine
	var chest_w: float = (0.155 if female else 0.19) * s
	# Pinggang → dada (kerucut terbalik halus).
	_cyl_tapered(spine, hip_w * 0.95, chest_w, 0.30 * s, Vector3(0, 0.15 * s, 0), m_top, Vector3(1.0, 1.0, 0.68))
	var chest := _bone(spine, "Chest", Vector3(0, 0.30 * s, 0))
	bones["chest"] = chest
	_capsule(chest, chest_w, 0.08 * s, Vector3(0, 0.02 * s, 0), m_top, Vector3(1.0, 0.75, 0.7))
	if female:
		_sphere(chest, 0.062 * s, Vector3(-0.055 * s, -0.02 * s, 0.075 * s), m_top)
		_sphere(chest, 0.062 * s, Vector3(0.055 * s, -0.02 * s, 0.075 * s), m_top)
	# Leher.
	var neck := _bone(chest, "Neck", Vector3(0, 0.09 * s, 0))
	bones["neck"] = neck
	_cyl(neck, 0.042 * s, 0.09 * s, Vector3(0, 0.03 * s, 0), m_skin)

	# ---------- Kepala anime ----------
	var head := _bone(neck, "Head", Vector3(0, 0.08 * s, 0))
	bones["head"] = head
	var hr: float = 0.118 * s  # radius kepala (agak besar, gaya anime)
	var skull := _sphere(head, hr, Vector3(0, hr * 0.95, 0), m_skin)
	skull.scale = Vector3(0.94, 1.0, 0.98)
	# Rahang/dagu runcing khas anime.
	var jaw := _sphere(head, hr * 0.82, Vector3(0, hr * 0.55, hr * 0.08), m_skin)
	jaw.scale = Vector3(0.9, 0.8, 0.86)
	# Telinga.
	_sphere(head, hr * 0.2, Vector3(-hr * 0.98, hr * 0.85, 0), m_skin).scale = Vector3(0.5, 1.0, 0.7)
	_sphere(head, hr * 0.2, Vector3(hr * 0.98, hr * 0.85, 0), m_skin).scale = Vector3(0.5, 1.0, 0.7)
	# Mata anime (quad bertekstur), hidung kecil, mulut.
	_eyes(head, hr, pal["eye"], female)
	_sphere(head, hr * 0.07, Vector3(0, hr * 0.62, hr * 0.98), toon(pal["skin"].darkened(0.12), 0.7))
	var mouth := _box(head, Vector3(hr * 0.22, hr * 0.035, 0.004), Vector3(0, hr * 0.38, hr * 0.96), toon(Color(0.55, 0.25, 0.25), 0.7))
	mouth.name = "Mouth"
	# Rona pipi.
	var blush := toon(Color(1.0, 0.6, 0.6, 0.35), 0.9)
	blush.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sphere(head, hr * 0.16, Vector3(-hr * 0.55, hr * 0.62, hr * 0.78), blush).scale = Vector3(1.0, 0.6, 0.3)
	_sphere(head, hr * 0.16, Vector3(hr * 0.55, hr * 0.62, hr * 0.78), blush).scale = Vector3(1.0, 0.6, 0.3)
	_hair(head, hr, key, m_hair, female, str(pal["age"]))

	# ---------- Lengan ----------
	var sh_x: float = chest_w + 0.03 * s
	var upper_len: float = 0.28 * s
	var fore_len: float = 0.26 * s
	var arm_r: float = (0.038 if female else 0.046) * s
	for side in [-1.0, 1.0]:
		var nm: String = "L" if side < 0 else "R"
		var shoulder := _bone(chest, "Shoulder" + nm, Vector3(side * sh_x, 0.05 * s, 0))
		bones["shoulder_" + nm.to_lower()] = shoulder
		_sphere(shoulder, arm_r * 1.35, Vector3.ZERO, m_top)
		_capsule(shoulder, arm_r * 1.05, upper_len - arm_r * 2.0, Vector3(0, -upper_len * 0.5, 0), m_top)
		var elbow := _bone(shoulder, "Elbow" + nm, Vector3(0, -upper_len, 0))
		bones["elbow_" + nm.to_lower()] = elbow
		_capsule(elbow, arm_r * 0.9, fore_len - arm_r * 1.6, Vector3(0, -fore_len * 0.5, 0), m_skin)
		var hand := _sphere(elbow, arm_r * 1.15, Vector3(0, -fore_len - arm_r * 0.4, 0), m_skin)
		hand.scale = Vector3(0.8, 1.15, 0.55)
		hand.name = "Hand" + nm
		bones["hand_" + nm.to_lower()] = hand

	# ---------- Kaki ----------
	var leg_x: float = hip_w * 0.5
	var thigh_len: float = 0.44 * s
	var shin_len: float = 0.42 * s
	var leg_r: float = (0.062 if female else 0.068) * s
	for side in [-1.0, 1.0]:
		var nm: String = "L" if side < 0 else "R"
		var upleg := _bone(hips, "UpLeg" + nm, Vector3(side * leg_x, -0.06 * s, 0))
		bones["upleg_" + nm.to_lower()] = upleg
		_cyl_tapered(upleg, leg_r, leg_r * 0.78, thigh_len, Vector3(0, -thigh_len * 0.5, 0), m_bottom)
		var knee := _bone(upleg, "Knee" + nm, Vector3(0, -thigh_len, 0))
		bones["knee_" + nm.to_lower()] = knee
		_sphere(knee, leg_r * 0.8, Vector3.ZERO, m_bottom)
		_cyl_tapered(knee, leg_r * 0.78, leg_r * 0.55, shin_len, Vector3(0, -shin_len * 0.5, 0), m_bottom)
		var foot := _box(knee, Vector3(leg_r * 1.7, leg_r * 0.9, leg_r * 3.2), Vector3(0, -shin_len - leg_r * 0.3, leg_r * 0.9), m_shoe)
		foot.name = "Foot" + nm

	_outfit(bones, key, pal, s, female)
	root.set_meta("bones", bones)
	root.set_meta("scale_factor", s)
	return root


# ---------- Material toon ----------

## Material cel-shaded + garis tepi (outline) via "grow" back-face.
static func toon(color: Color, rough: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = 0.0
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.6
	# Outline: pass berikutnya menggambar sisi belakang yang "digemukkan" dengan warna gelap.
	var o := StandardMaterial3D.new()
	o.albedo_color = Color(0.06, 0.05, 0.08)
	o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	o.cull_mode = BaseMaterial3D.CULL_FRONT
	o.grow = true
	o.grow_amount = OUTLINE
	m.next_pass = o
	return m


# ---------- Primitif berjenjang ----------

func _bone(parent: Node3D, bone_name: String, pos: Vector3) -> Node3D:
	var b := Node3D.new()
	b.name = bone_name
	b.position = pos
	parent.add_child(b)
	return b


func _mi(parent: Node3D, mesh: Mesh, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi


func _sphere(parent: Node3D, r: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 24
	m.rings = 12
	return _mi(parent, m, pos, material)


func _capsule(parent: Node3D, r: float, mid_h: float, pos: Vector3, material: Material, sc: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(mid_h + r * 2.0, r * 2.0)
	m.radial_segments = 20
	var mi := _mi(parent, m, pos, material)
	mi.scale = sc
	return mi


func _cyl(parent: Node3D, r: float, h: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = h
	m.radial_segments = 18
	return _mi(parent, m, pos, material)


func _cyl_tapered(parent: Node3D, r_bottom: float, r_top: float, h: float, pos: Vector3, material: Material, sc: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bottom
	m.height = h
	m.radial_segments = 18
	var mi := _mi(parent, m, pos, material)
	mi.scale = sc
	return mi


func _box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _mi(parent, m, pos, material)


# ---------- Mata anime (tekstur prosedural) ----------

func _eyes(head: Node3D, hr: float, iris: Color, female: bool) -> void:
	var tex: ImageTexture = _eye_texture(iris, female)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var w: float = hr * (0.46 if female else 0.42)
	var h: float = hr * (0.34 if female else 0.28)
	for side in [-1.0, 1.0]:
		var q := QuadMesh.new()
		q.size = Vector2(w, h)
		var mi := _mi(head, q, Vector3(side * hr * 0.42, hr * 0.78, hr * 0.90), m)
		mi.rotation.y = side * 0.32
		mi.name = "EyeL" if side < 0 else "EyeR"
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if side > 0:
			mi.scale.x = -1.0  # cerminkan agar sorot mata simetris
	# Alis.
	var brow := toon(Color(0.12, 0.09, 0.08), 0.8)
	for side in [-1.0, 1.0]:
		var b := _box(head, Vector3(hr * 0.36, hr * 0.045, 0.004), Vector3(side * hr * 0.42, hr * 1.02, hr * 0.93), brow)
		b.rotation.z = side * -0.12
		b.rotation.y = side * 0.32


static func _eye_texture(iris: Color, female: bool) -> ImageTexture:
	var key: String = iris.to_html(false) + ("f" if female else "m")
	if _eye_tex_cache.has(key):
		return _eye_tex_cache[key]
	var W := 64
	var H := 48
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := W * 0.5
	var cy := H * 0.55
	var rx := W * 0.46
	var ry := H * (0.46 if female else 0.40)
	for y in H:
		for x in W:
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			var d := dx * dx + dy * dy
			if d > 1.0:
				continue
			# Sklera putih hangat; kelopak atas (garis tebal) gelap.
			var col := Color(0.98, 0.98, 0.97)
			var idx := (x - cx) / (W * 0.19)
			var idy := (y - (cy + H * 0.04)) / (H * 0.30)
			var di := idx * idx + idy * idy
			if di <= 1.0:
				# Iris bergradasi: gelap di atas, terang di bawah (gaya anime).
				var t := clampf((idy + 1.0) * 0.5, 0.0, 1.0)
				col = iris.darkened(0.45 - t * 0.5).lightened(t * 0.25)
				if di <= 0.28:
					col = Color(0.05, 0.04, 0.05)  # pupil
				# Sorot cahaya.
				var hx := (x - (cx - W * 0.06)) / (W * 0.05)
				var hy := (y - (cy - H * 0.10)) / (H * 0.07)
				if hx * hx + hy * hy <= 1.0:
					col = Color(1, 1, 1)
				var hx2 := (x - (cx + W * 0.07)) / (W * 0.025)
				var hy2 := (y - (cy + H * 0.14)) / (H * 0.035)
				if hx2 * hx2 + hy2 * hy2 <= 1.0:
					col = Color(1, 1, 1, 0.9)
			# Garis kelopak atas.
			if dy < -0.62 or (dy < -0.45 and absf(dx) > 0.55):
				col = Color(0.10, 0.07, 0.07)
			if female and dx > 0.72 and dy < -0.2:
				col = Color(0.10, 0.07, 0.07)  # bulu mata luar
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_eye_tex_cache[key] = tex
	return tex


# ---------- Rambut per tokoh ----------

func _hair(head: Node3D, hr: float, key: String, m_hair: StandardMaterial3D, female: bool, _age: String) -> void:
	var cap := _sphere(head, hr * 1.06, Vector3(0, hr * 1.02, -hr * 0.05), m_hair)
	cap.scale = Vector3(1.0, 0.95, 1.0)
	# Poni: beberapa "helai" tebal bergaya anime.
	var bang_n: int = 5
	match key:
		"ardi":
			_bangs(head, hr, m_hair, 6, 0.55, 0.28, -0.10)
			_tuft(head, hr, m_hair, Vector3(0.35, 1.85, -0.2), Vector3(0.5, 0.35, 0.5), 0.5)
		"rara":
			_bangs(head, hr, m_hair, 5, 0.5, 0.36, 0.0)
			# Kuncir kuda tinggi + pita merah.
			var tail := _capsule(head, hr * 0.28, hr * 0.9, Vector3(0, hr * 1.25, -hr * 1.05), m_hair)
			tail.rotation.x = 0.85
			tail.name = "Ponytail"
			_box(head, Vector3(hr * 0.42, hr * 0.14, hr * 0.14), Vector3(0, hr * 1.55, -hr * 0.85), toon(Color(0.88, 0.25, 0.3), 0.6))
			_side_locks(head, hr, m_hair, 1.15)
		"mira":
			# Bob lurus dengan poni rata.
			var bob := _capsule(head, hr * 1.08, hr * 0.7, Vector3(0, hr * 0.62, -hr * 0.08), m_hair, Vector3(1.0, 1.0, 0.92))
			bob.name = "Bob"
			_box(head, Vector3(hr * 1.5, hr * 0.5, hr * 0.5), Vector3(0, hr * 1.42, hr * 0.62), m_hair)
		"pak_harto":
			cap.scale = Vector3(1.0, 0.82, 1.0)
			cap.position.y = hr * 1.1
			# Kumis abu-abu.
			_box(head, Vector3(hr * 0.42, hr * 0.09, hr * 0.12), Vector3(0, hr * 0.48, hr * 0.92), m_hair)
		"nenek":
			cap.scale = Vector3(1.0, 0.9, 1.0)
			# Sanggul.
			_sphere(head, hr * 0.42, Vector3(0, hr * 1.1, -hr * 1.05), m_hair)
			_bangs(head, hr, m_hair, 4, 0.45, 0.2, 0.0)
		"darmo":
			_bangs(head, hr, m_hair, 5, 0.5, 0.25, -0.05)
		"bu_rt":
			# Kerudung menutupi rambut.
			cap.visible = false
			var hijab := toon(Color(0.86, 0.72, 0.45), 0.9)
			var h1 := _sphere(head, hr * 1.14, Vector3(0, hr * 0.95, -hr * 0.05), hijab)
			h1.scale = Vector3(1.0, 1.02, 1.0)
			var drape := _cyl_tapered(head, hr * 1.55, hr * 0.9, hr * 1.3, Vector3(0, hr * 0.05, -hr * 0.1), hijab)
			drape.name = "HijabDrape"
		_:
			_bangs(head, hr, m_hair, bang_n, 0.5, 0.25, 0.0)
	if female and key != "bu_rt" and key != "mira":
		_side_locks(head, hr, m_hair, 1.0)


func _bangs(head: Node3D, hr: float, m: Material, n: int, width: float, length: float, tilt: float) -> void:
	for i in n:
		var t: float = (float(i) / float(n - 1)) * 2.0 - 1.0
		var strand := _capsule(head, hr * width / float(n) * 0.9, hr * length, Vector3(t * hr * width * 0.85, hr * (1.35 - absf(t) * 0.12), hr * 0.86), m)
		strand.rotation.x = 0.35 + tilt
		strand.rotation.z = -t * 0.35
		strand.scale = Vector3(1.0, 1.0, 0.55)


func _tuft(head: Node3D, hr: float, m: Material, pos: Vector3, rot: Vector3, len_k: float) -> void:
	var t := _capsule(head, hr * 0.11, hr * len_k, pos * hr, m)
	t.rotation = rot


func _side_locks(head: Node3D, hr: float, m: Material, len_k: float) -> void:
	for side in [-1.0, 1.0]:
		var lock := _capsule(head, hr * 0.14, hr * 0.9 * len_k, Vector3(side * hr * 0.98, hr * 0.55, hr * 0.15), m)
		lock.scale = Vector3(0.7, 1.0, 0.9)


# ---------- Pakaian & aksesori khas ----------

func _outfit(b: Dictionary, key: String, pal: Dictionary, s: float, _female: bool) -> void:
	var chest: Node3D = b["chest"]
	var spine: Node3D = b["spine"]
	var hips: Node3D = b["hips"]
	var head: Node3D = b["head"]
	var hr: float = 0.118 * s
	# Kerah baju (semua tokoh).
	var collar := toon(pal["top"].lightened(0.18), 0.9)
	_cyl_tapered(chest, 0.05 * s, 0.075 * s, 0.05 * s, Vector3(0, 0.085 * s, 0.005 * s), collar)
	match key:
		"ardi":
			# Tali tas selempang + tas di pinggul.
			var strap := _box(spine, Vector3(0.06 * s, 0.5 * s, 0.012), Vector3(0.0, 0.12 * s, 0.11 * s), toon(Color(0.42, 0.28, 0.16), 0.8))
			strap.rotation.z = 0.55
			_box(hips, Vector3(0.24 * s, 0.2 * s, 0.09 * s), Vector3(-0.2 * s, -0.02 * s, -0.04 * s), toon(Color(0.5, 0.35, 0.2), 0.8))
		"rara":
			# Celemek krem + tali leher.
			var apron := toon(Color(0.98, 0.93, 0.80), 0.9)
			_box(spine, Vector3(0.24 * s, 0.34 * s, 0.01), Vector3(0, 0.12 * s, 0.105 * s), apron)
			_box(hips, Vector3(0.30 * s, 0.30 * s, 0.01), Vector3(0, -0.14 * s, 0.13 * s), apron)
			_box(chest, Vector3(0.015, 0.14 * s, 0.01), Vector3(-0.05 * s, 0.09 * s, 0.13 * s), apron)
			_box(chest, Vector3(0.015, 0.14 * s, 0.01), Vector3(0.05 * s, 0.09 * s, 0.13 * s), apron)
		"pak_harto":
			# Fedora + tongkat di tangan kanan.
			var felt := toon(Color(0.36, 0.28, 0.18), 0.85)
			_cyl(head, hr * 1.55, hr * 0.12, Vector3(0, hr * 1.72, 0), felt)
			var crown := _cyl_tapered(head, hr * 1.02, hr * 0.85, hr * 0.7, Vector3(0, hr * 2.05, 0), felt)
			crown.scale = Vector3(1.0, 1.0, 1.1)
			_box(head, Vector3(hr * 2.2, hr * 0.14, hr * 2.2), Vector3(0, hr * 1.8, 0), toon(Color(0.2, 0.15, 0.1), 0.8))
			var hand_r: Node3D = b["hand_r"]
			var cane := _cyl(hand_r, 0.014 * s, 0.85 * s, Vector3(0, -0.36 * s, 0.02 * s), toon(Color(0.38, 0.26, 0.14), 0.7))
			cane.name = "Cane"
			_sphere(hand_r, 0.03 * s, Vector3(0, 0.05 * s, 0.02 * s), toon(Color(0.7, 0.6, 0.3), 0.4))
		"mira":
			# Syal merah + kamera di dada + jaket.
			var scarf := toon(Color(0.82, 0.26, 0.24), 0.9)
			_capsule(chest, 0.075 * s, 0.05 * s, Vector3(0, 0.1 * s, 0.03 * s), scarf, Vector3(1.4, 0.7, 1.2))
			_box(chest, Vector3(0.07 * s, 0.22 * s, 0.03 * s), Vector3(0.09 * s, -0.08 * s, 0.14 * s), scarf)
			_box(spine, Vector3(0.14 * s, 0.09 * s, 0.07 * s), Vector3(0, 0.1 * s, 0.14 * s), toon(Color(0.12, 0.12, 0.14), 0.5))
			var lens := _cyl(spine, 0.03 * s, 0.05 * s, Vector3(0, 0.1 * s, 0.19 * s), toon(Color(0.2, 0.25, 0.35), 0.3))
			lens.rotation.x = PI / 2.0
		"nenek":
			# Kebaya + selendang batik + bros melati emas.
			var selendang := toon(Color(0.72, 0.56, 0.30), 0.9)
			var sd := _box(spine, Vector3(0.12 * s, 0.55 * s, 0.015), Vector3(-0.06 * s, 0.05 * s, 0.12 * s), selendang)
			sd.rotation.z = -0.25
			_box(spine, Vector3(0.12 * s, 0.4 * s, 0.015), Vector3(-0.1 * s, 0.05 * s, -0.12 * s), selendang)
			_sphere(chest, 0.028 * s, Vector3(0.06 * s, 0.02 * s, 0.13 * s), toon(Color(0.9, 0.7, 0.15), 0.3))
			# Kain panjang (rok) menutup kaki.
			var kain := toon(pal["bottom"], 0.9)
			_cyl_tapered(hips, 0.16 * s, 0.2 * s, 0.85 * s, Vector3(0, -0.5 * s, 0), kain)
		"darmo":
			# Topi masinis + garis merah dada + kancing kuningan + peluit.
			var navy := toon(Color(0.16, 0.2, 0.36), 0.85)
			_cyl(head, hr * 1.1, hr * 0.5, Vector3(0, hr * 1.95, 0), navy)
			var brim := _box(head, Vector3(hr * 1.4, hr * 0.08, hr * 0.7), Vector3(0, hr * 1.72, hr * 0.85), toon(Color(0.08, 0.08, 0.1), 0.5))
			brim.rotation.x = 0.15
			_sphere(head, hr * 0.14, Vector3(0, hr * 2.0, hr * 1.08), toon(Color(0.85, 0.7, 0.25), 0.3))
			_box(spine, Vector3(0.32 * s, 0.03 * s, 0.24 * s), Vector3(0, 0.22 * s, 0), toon(Color(0.75, 0.2, 0.2), 0.8))
			for i in 3:
				_sphere(spine, 0.012 * s, Vector3(0, (0.05 + i * 0.07) * s, 0.12 * s), toon(Color(0.85, 0.7, 0.25), 0.3))
			_cyl(chest, 0.012 * s, 0.05 * s, Vector3(0.05 * s, -0.03 * s, 0.13 * s), toon(Color(0.85, 0.7, 0.25), 0.3))
		"bu_rt":
			# Blus bermotif + sapu lidi di tangan kiri.
			var hand_l: Node3D = b["hand_l"]
			var broom := _cyl(hand_l, 0.012 * s, 1.1 * s, Vector3(0, -0.3 * s, 0.03 * s), toon(Color(0.55, 0.42, 0.25), 0.9))
			broom.name = "Broom"
			_cyl_tapered(hand_l, 0.02 * s, 0.07 * s, 0.28 * s, Vector3(0, -0.95 * s, 0.03 * s), toon(Color(0.72, 0.6, 0.35), 0.95))
			var kain := toon(pal["bottom"], 0.9)
			_cyl_tapered(hips, 0.16 * s, 0.21 * s, 0.85 * s, Vector3(0, -0.5 * s, 0), kain)
		_:
			# Warga: caping bambu.
			var cone := CylinderMesh.new()
			cone.top_radius = 0.01
			cone.bottom_radius = hr * 2.6
			cone.height = hr * 1.1
			cone.radial_segments = 16
			_mi(head, cone, Vector3(0, hr * 2.15, 0), toon(Color(0.80, 0.68, 0.40), 0.9))
	# Rok pendek untuk Rara (bukan celana).
	if key == "rara":
		_cyl_tapered(hips, 0.155 * s, 0.24 * s, 0.34 * s, Vector3(0, -0.2 * s, 0), toon(pal["bottom"], 0.9))
