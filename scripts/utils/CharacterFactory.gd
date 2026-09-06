class_name CharacterFactory
extends RefCounted
## CharacterFactory — avatar low-poly stylized untuk tiap karakter.
## Kapsul badan + kepala + rambut/aksesori khas + warna identitas.

const PALETTES := {
	"ardi": {"skin": Color(0.96, 0.78, 0.62), "top": Color(0.16, 0.32, 0.52), "bottom": Color(0.2, 0.2, 0.24), "hair": Color(0.12, 0.1, 0.1)},
	"rara": {"skin": Color(0.97, 0.8, 0.64), "top": Color(0.95, 0.55, 0.3), "bottom": Color(0.35, 0.2, 0.3), "hair": Color(0.3, 0.15, 0.08)},
	"pak_harto": {"skin": Color(0.9, 0.7, 0.55), "top": Color(0.45, 0.42, 0.35), "bottom": Color(0.25, 0.22, 0.2), "hair": Color(0.75, 0.75, 0.75)},
	"mira": {"skin": Color(0.95, 0.76, 0.6), "top": Color(0.2, 0.5, 0.45), "bottom": Color(0.15, 0.2, 0.28), "hair": Color(0.08, 0.08, 0.1)},
	"nenek": {"skin": Color(0.88, 0.68, 0.52), "top": Color(0.55, 0.3, 0.45), "bottom": Color(0.3, 0.25, 0.3), "hair": Color(0.8, 0.8, 0.82)},
	"darmo": {"skin": Color(0.9, 0.7, 0.55), "top": Color(0.3, 0.3, 0.35), "bottom": Color(0.2, 0.2, 0.22), "hair": Color(0.15, 0.12, 0.1)},
	"bu_rt": {"skin": Color(0.9, 0.72, 0.56), "top": Color(0.62, 0.42, 0.55), "bottom": Color(0.3, 0.22, 0.3), "hair": Color(0.25, 0.2, 0.2)},
	"warga": {"skin": Color(0.93, 0.74, 0.58), "top": Color(0.5, 0.5, 0.55), "bottom": Color(0.3, 0.3, 0.32), "hair": Color(0.2, 0.18, 0.16)},
}


func build_character(char_id: String) -> Node3D:
	var key: String = char_id if PALETTES.has(char_id) else "warga"
	var pal: Dictionary = PALETTES[key]
	var root := Node3D.new()
	root.name = "Avatar_" + key
	var pf := PropFactory.new()
	var m_skin := pf.mat(pal["skin"], 0.7)
	var m_top := pf.mat(pal["top"], 0.8)
	var m_bottom := pf.mat(pal["bottom"], 0.8)
	var m_hair := pf.mat(pal["hair"], 0.85)
	# Kaki & badan.
	pf.box(root, Vector3(0.16, 0.55, 0.18), Vector3(-0.11, 0.28, 0), m_bottom)
	pf.box(root, Vector3(0.16, 0.55, 0.18), Vector3(0.11, 0.28, 0), m_bottom)
	pf.box(root, Vector3(0.46, 0.62, 0.28), Vector3(0, 0.86, 0), m_top)
	# Lengan.
	pf.box(root, Vector3(0.12, 0.5, 0.14), Vector3(-0.31, 0.85, 0), m_top)
	pf.box(root, Vector3(0.12, 0.5, 0.14), Vector3(0.31, 0.85, 0), m_top)
	pf.sphere(root, 0.07, Vector3(-0.31, 0.58, 0), m_skin)
	pf.sphere(root, 0.07, Vector3(0.31, 0.58, 0), m_skin)
	# Kepala + rambut.
	pf.sphere(root, 0.21, Vector3(0, 1.38, 0), m_skin)
	pf.sphere(root, 0.215, Vector3(0, 1.45, -0.04), m_hair)
	# Mata (dua titik gelap).
	var m_eye := pf.mat(Color(0.1, 0.1, 0.12), 0.5)
	pf.sphere(root, 0.028, Vector3(-0.075, 1.4, 0.185), m_eye)
	pf.sphere(root, 0.028, Vector3(0.075, 1.4, 0.185), m_eye)
	_apply_signature(pf, root, key, pal)
	return root


## Aksesori khas tiap karakter (topi, syal, kamera, tongkat, ...).
func _apply_signature(pf: PropFactory, root: Node3D, key: String, pal: Dictionary) -> void:
	match key:
		"ardi":
			# Tas selempang arsitek.
			pf.box(root, Vector3(0.3, 0.36, 0.12), Vector3(0.0, 0.9, -0.22), pf.mat(Color(0.5, 0.35, 0.2), 0.8))
			var strap := pf.box(root, Vector3(0.08, 0.7, 0.02), Vector3(0.0, 1.0, 0.16), pf.mat(Color(0.35, 0.24, 0.14), 0.8))
			strap.rotation.z = 0.5
		"rara":
			# Celemek kafe + ikat rambut.
			pf.box(root, Vector3(0.36, 0.5, 0.03), Vector3(0, 0.8, 0.16), pf.mat(Color(0.98, 0.92, 0.78), 0.9))
			pf.sphere(root, 0.09, Vector3(0, 1.62, -0.1), pf.mat(pal["hair"], 0.85))
			pf.box(root, Vector3(0.12, 0.05, 0.05), Vector3(0, 1.6, -0.02), pf.mat(Color(0.9, 0.3, 0.35), 0.7))
		"pak_harto":
			# Topi fedora + kumis + tongkat.
			pf.cyl(root, 0.23, 0.04, Vector3(0, 1.58, 0), pf.mat(Color(0.35, 0.28, 0.18), 0.8), false, 12)
			pf.cyl(root, 0.14, 0.14, Vector3(0, 1.66, 0), pf.mat(Color(0.35, 0.28, 0.18), 0.8), false, 12)
			pf.box(root, Vector3(0.14, 0.035, 0.03), Vector3(0, 1.3, 0.19), pf.mat(Color(0.8, 0.8, 0.8), 0.8))
			pf.cyl(root, 0.025, 1.0, Vector3(0.4, 0.5, 0.1), pf.mat(Color(0.4, 0.28, 0.15), 0.8), false, 8)
		"mira":
			# Kamera jurnalis + syal.
			pf.box(root, Vector3(0.2, 0.14, 0.1), Vector3(0, 1.05, 0.2), pf.mat(Color(0.12, 0.12, 0.14), 0.5))
			pf.cyl(root, 0.045, 0.08, Vector3(0, 1.05, 0.27), pf.mat(Color(0.2, 0.25, 0.35), 0.4), false, 10)
			pf.box(root, Vector3(0.5, 0.12, 0.3), Vector3(0, 1.18, 0), pf.mat(Color(0.85, 0.3, 0.25), 0.8))
		"nenek":
			# Sanggul + selendang + bros emas.
			pf.sphere(root, 0.11, Vector3(0, 1.6, -0.08), pf.mat(pal["hair"], 0.85))
			pf.box(root, Vector3(0.5, 0.5, 0.02), Vector3(-0.1, 0.95, 0.16), pf.mat(Color(0.7, 0.55, 0.3), 0.85))
			pf.sphere(root, 0.04, Vector3(0.08, 1.02, 0.17), pf.mat(Color(0.85, 0.6, 0.1), 0.35, Color(0.85, 0.6, 0.1), 0.6))
		"bu_rt":
			# Kerudung + sapu lidi di tangan.
			pf.sphere(root, 0.235, Vector3(0, 1.42, -0.03), pf.mat(Color(0.85, 0.7, 0.4), 0.9))
			pf.box(root, Vector3(0.5, 0.35, 0.03), Vector3(0, 1.1, 0.14), pf.mat(Color(0.85, 0.7, 0.4), 0.9))
			pf.cyl(root, 0.02, 1.3, Vector3(-0.42, 0.65, 0.08), pf.mat(Color(0.55, 0.42, 0.25), 0.9), false, 6)
			pf.cyl(root, 0.06, 0.3, Vector3(-0.42, 0.15, 0.08), pf.mat(Color(0.7, 0.6, 0.35), 0.95), false, 8)
		"darmo":
			# Topi masinis + seragam bergaris.
			pf.box(root, Vector3(0.34, 0.1, 0.34), Vector3(0, 1.62, 0), pf.mat(Color(0.2, 0.25, 0.4), 0.8))
			pf.box(root, Vector3(0.48, 0.08, 0.3), Vector3(0, 1.0, 0), pf.mat(Color(0.75, 0.2, 0.2), 0.8))
		_:
			# Warga generik: topi caping.
			var cone := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.02
			cm.bottom_radius = 0.34
			cm.height = 0.18
			cone.mesh = cm
			cone.position = Vector3(0, 1.66, 0)
			cone.material_override = pf.mat(Color(0.8, 0.68, 0.4), 0.9)
			root.add_child(cone)
