extends "res://scripts/locations/LocationBase.gd"
## Makam Bukit — pemakaman kecil di lereng bukit di atas Kota Tua. Nisan Nenek
## Lastri & Kakek Darmo bersebelahan; dari sini terlihat laut dan stasiun.
## Terbuka setelah bab 3. Tempat berpamitan, bukan tempat menyelidik.


func _build_layout() -> void:
	layout["spawn:default"] = {"pos": Vector3(0, 0, 7.0), "yaw": 0.0}
	layout["obj:gapura_makam"] = {"pos": Vector3(0, 0, 8.5)}
	layout["obj:nisan_nenek"] = {"pos": Vector3(-1.1, 0, -2.0)}
	layout["obj:nisan_kakek"] = {"pos": Vector3(1.1, 0, -2.0)}
	layout["obj:pohon_kamboja"] = {"pos": Vector3(-5.0, 0, -4.0)}
	layout["obj:nisan_korban"] = {"pos": Vector3(6.0, 0, -1.0)}
	layout["obj:vista_bukit"] = {"pos": Vector3(0.0, 0, -8.0)}
	layout["npc:juru_kunci"] = {"pos": Vector3(3.5, 0, 4.0), "yaw": -0.8}


func _build_visuals() -> void:
	# Lereng: tanah rumput dengan teras rendah.
	pf.plane_ground(self, Vector2(60, 60), Vector3.ZERO, pf.mat(Color(0.32, 0.42, 0.26)))
	pf.box(self, Vector3(22, 0.3, 16), Vector3(0, 0.15, -1.0), pf.mat(Color(0.36, 0.44, 0.28), 0.95))
	pf.box(self, Vector3(3.0, 0.02, 30), Vector3(0, 0.31, 3.0), pf.mat(Color(0.55, 0.5, 0.42), 0.95))
	# Gapura & pagar.
	var gm := pf.mat(Color(0.75, 0.74, 0.7), 0.85)
	pf.box(self, Vector3(0.35, 2.6, 0.35), Vector3(-1.6, 1.3, 8.5), gm, true)
	pf.box(self, Vector3(0.35, 2.6, 0.35), Vector3(1.6, 1.3, 8.5), gm, true)
	pf.box(self, Vector3(3.9, 0.35, 0.4), Vector3(0, 2.7, 8.5), gm)
	pf.make_fence(self, Vector3(-11, 0.3, 8.5), Vector3(-1.9, 0.3, 8.5), 0.9)
	pf.make_fence(self, Vector3(1.9, 0.3, 8.5), Vector3(11, 0.3, 8.5), 0.9)
	pf.make_fence(self, Vector3(-11, 0.3, 8.5), Vector3(-11, 0.3, -9.0), 0.9)
	pf.make_fence(self, Vector3(11, 0.3, 8.5), Vector3(11, 0.3, -9.0), 0.9)
	# Nisan Nenek & Kakek (lebih terawat, ada payung nisan kecil).
	_make_grave(Vector3(-1.1, 0.3, -2.0), Color(0.9, 0.88, 0.82), true)
	_make_grave(Vector3(1.1, 0.3, -2.0), Color(0.9, 0.88, 0.82), true)
	pf.box(self, Vector3(3.2, 0.06, 0.06), Vector3(0, 2.1, -2.7), pf.mat(Color(0.4, 0.28, 0.16), 0.9))
	# Barisan nisan korban 1983 (12).
	for i in 12:
		var gx: float = 4.2 + float(i % 4) * 1.1
		var gz: float = -0.4 - float(i / 4) * 1.6
		_make_grave(Vector3(gx, 0.3, gz), Color(0.62, 0.62, 0.6), false)
	# Nisan tua acak di sisi barat.
	for i in 7:
		var gx: float = -4.0 - float(i % 3) * 1.3
		var gz: float = 1.5 - float(i / 3) * 1.7
		var stone := pf.box(self, Vector3(0.45, 0.7, 0.12), Vector3(gx, 0.65, gz), pf.mat(Color(0.5, 0.52, 0.48), 0.95), true)
		stone.rotation.z = 0.06 * float((i % 3) - 1)
	# Pohon kamboja & pinus.
	pf.make_tree(self, Vector3(-5.0, 0.3, -4.0), 1.1)
	pf.make_tree(self, Vector3(7.5, 0.3, 5.5), 0.9)
	pf.make_tree(self, Vector3(-8.5, 0.3, 6.0), 1.3)
	for i in 14:
		var px: float = -3.0 + float(i % 7) * 0.5 - 4.0
		var pz: float = -3.8 + float(i / 7) * 0.5
		pf.sphere(self, 0.06, Vector3(px, 0.34, pz), pf.mat(Color(0.98, 0.95, 0.8), 0.6))
	# Gubuk juru kunci.
	pf.box(self, Vector3(2.6, 2.0, 2.2), Vector3(5.5, 1.3, 5.0), pf.mat(Color(0.45, 0.35, 0.22), 0.9), true)
	pf.box(self, Vector3(3.0, 0.15, 2.6), Vector3(5.5, 2.35, 5.0), pf.mat(Color(0.3, 0.18, 0.12), 0.9))
	pf.make_lamp(self, Vector3(4.0, 0.3, 6.2))
	# Bangku pandang di tepi bukit + lampu kecil.
	pf.box(self, Vector3(1.8, 0.1, 0.4), Vector3(0, 0.75, -7.8), pf.mat(Color(0.5, 0.38, 0.22), 0.9))
	pf.box(self, Vector3(0.1, 0.45, 0.4), Vector3(-0.8, 0.5, -7.8), pf.mat(Color(0.35, 0.26, 0.15), 0.9))
	pf.box(self, Vector3(0.1, 0.45, 0.4), Vector3(0.8, 0.5, -7.8), pf.mat(Color(0.35, 0.26, 0.15), 0.9))
	# Tepi bukit menurun + "kota" di kejauhan (siluet).
	pf.box(self, Vector3(60, 0.4, 8), Vector3(0, -0.6, -13.0), pf.mat(Color(0.28, 0.36, 0.22), 0.95))
	for i in 9:
		var bx: float = -16.0 + float(i) * 4.0
		var bh: float = 1.2 + float((i * 7) % 5) * 0.5
		pf.box(self, Vector3(2.4, bh, 2.0), Vector3(bx, -1.0 + bh / 2.0, -20.0 - float(i % 3) * 2.0), pf.mat(Color(0.18, 0.2, 0.24), 0.95))
	# Laut jauh.
	pf.box(self, Vector3(80, 0.05, 20), Vector3(0, -1.6, -36.0), pf.mat(Color(0.15, 0.3, 0.42), 0.3))


func _make_grave(pos: Vector3, col: Color, kept: bool) -> void:
	pf.box(self, Vector3(0.8, 0.25, 1.6), pos + Vector3(0, 0.12, 0.3), pf.mat(col.darkened(0.15), 0.95))
	pf.box(self, Vector3(0.6, 0.8, 0.12), pos + Vector3(0, 0.55, -0.5), pf.mat(col, 0.9), true)
	if kept:
		pf.box(self, Vector3(0.5, 0.04, 0.3), pos + Vector3(0, 0.27, 0.5), pf.mat(Color(0.9, 0.6, 0.2), 0.7))
		pf.sphere(self, 0.08, pos + Vector3(-0.12, 0.34, 0.5), pf.mat(Color(0.98, 0.7, 0.75), 0.7))
		pf.sphere(self, 0.08, pos + Vector3(0.12, 0.34, 0.55), pf.mat(Color(0.98, 0.95, 0.8), 0.7))
