extends "res://scripts/locations/LocationBase.gd"
## Pasar Lama — pasar pagi: deretan kios beratap terpal, kios arsip koran,
## lapak barang antik tempat bros nenek berada.


func _build_layout() -> void:
	layout["spawn:default"] = {"pos": Vector3(0, 0, 10), "yaw": 0.0}
	layout["spawn:gate"] = {"pos": Vector3(0, 0, 8), "yaw": 0.0}
	layout["npc:mira"] = {"pos": Vector3(4.5, 0, -2.0), "yaw": -PI / 2}
	layout["npc:pedagang"] = {"pos": Vector3(-4.0, 0, -1.0), "yaw": PI / 2}
	layout["npc:warga_pasar"] = {"pos": Vector3(1.0, 0, 4.0), "yaw": PI}
	layout["obj:gapura"] = {"pos": Vector3(0, 0, 7.5)}
	layout["obj:kios_arsip"] = {"pos": Vector3(4.5, 0, -3.5)}
	layout["obj:lapak_antik"] = {"pos": Vector3(-4.0, 0, -2.6)}
	layout["obj:karcis_jatuh"] = {"pos": Vector3(1.5, 0, -0.5)}
	layout["obj:peti_senter"] = {"pos": Vector3(-1.5, 0, -5.5)}
	layout["obj:papan_pasar"] = {"pos": Vector3(-6.0, 0, 3.0)}
	layout["obj:gerobak"] = {"pos": Vector3(6.5, 0, 4.5)}
	layout["obj:vista_gapura"] = {"pos": Vector3(0, 0, 9.5)}


func _build_visuals() -> void:
	pf.plane_ground(self, Vector2(60, 60), Vector3.ZERO, pf.mat(Color(0.5, 0.46, 0.38)))
	# Gapura selamat datang.
	pf.box(self, Vector3(0.4, 4.0, 0.4), Vector3(-2.5, 2.0, 7.5), pf.mat(Color(0.5, 0.2, 0.15), 0.8), true)
	pf.box(self, Vector3(0.4, 4.0, 0.4), Vector3(2.5, 2.0, 7.5), pf.mat(Color(0.5, 0.2, 0.15), 0.8), true)
	pf.box(self, Vector3(5.8, 0.8, 0.5), Vector3(0, 4.2, 7.5), pf.mat(Color(0.7, 0.25, 0.15), 0.8))
	# Deretan kios.
	_make_stall(Vector3(-4.0, 0, -3.5), Color(0.8, 0.3, 0.25))   # antik
	_make_stall(Vector3(0.0, 0, -4.5), Color(0.25, 0.5, 0.75))    # kain
	_make_stall(Vector3(4.5, 0, -4.5), Color(0.85, 0.65, 0.2))    # arsip/koran
	_make_stall(Vector3(-4.5, 0, 2.0), Color(0.3, 0.6, 0.35))     # sayur
	_make_stall(Vector3(4.0, 0, 2.5), Color(0.7, 0.4, 0.6))       # jajanan
	# Isi kios antik: pernak-pernik + bros berkilau.
	pf.make_crate(self, Vector3(-4.8, 0, -3.0), 0.6)
	pf.box(self, Vector3(0.5, 0.3, 0.35), Vector3(-3.6, 1.15, -3.6), pf.mat(Color(0.55, 0.4, 0.25), 0.7))
	pf.sphere(self, 0.08, Vector3(-4.0, 1.25, -3.4), pf.mat(Color(0.9, 0.65, 0.15), 0.3, Color(0.9, 0.65, 0.15), 1.0))
	# Kios arsip: tumpukan koran.
	for i in 5:
		pf.box(self, Vector3(0.6, 0.12, 0.45), Vector3(4.0 + (i % 3) * 0.5, 1.05 + (i / 3) * 0.13, -4.6), pf.mat(Color(0.85, 0.82, 0.72), 0.95))
	# Karcis jatuh (kertas kecil di tanah).
	pf.box(self, Vector3(0.25, 0.02, 0.12), Vector3(1.5, 0.03, -0.5), pf.mat(Color(0.9, 0.75, 0.5), 0.9))
	# Peti berisi senter di gudang belakang.
	pf.make_crate(self, Vector3(-1.5, 0, -5.5), 0.9)
	pf.box(self, Vector3(3, 2.2, 0.25), Vector3(-1.5, 1.1, -6.5), pf.mat(Color(0.6, 0.5, 0.38), 0.9))
	# Papan pengumuman + gerobak.
	pf.box(self, Vector3(0.15, 1.6, 2.4), Vector3(-6.0, 1.0, 3.0), pf.mat(Color(0.5, 0.38, 0.22), 0.85), true)
	pf.box(self, Vector3(1.6, 0.7, 1.0), Vector3(6.5, 0.6, 4.5), pf.mat(Color(0.55, 0.4, 0.2), 0.85), true)
	pf.cyl(self, 0.35, 0.1, Vector3(6.0, 0.35, 4.5), pf.mat(Color(0.2, 0.2, 0.2), 0.8), false, 10)
	pf.cyl(self, 0.35, 0.1, Vector3(7.0, 0.35, 4.5), pf.mat(Color(0.2, 0.2, 0.2), 0.8), false, 10)
	# Pohon peneduh + lampu jalan.
	pf.make_tree(self, Vector3(-8, 0, -1), 1.3)
	pf.make_tree(self, Vector3(8, 0, -2), 1.1)
	pf.make_streetlamp(self, Vector3(0, 0, 5.5))
	pf.make_streetlamp(self, Vector3(6, 0, -5))


func _make_stall(pos: Vector3, canopy: Color) -> void:
	var stall := Node3D.new()
	stall.position = pos
	add_child(stall)
	# Meja dagangan.
	pf.box(stall, Vector3(2.4, 0.1, 1.4), Vector3(0, 0.9, 0), pf.mat(Color(0.55, 0.4, 0.22), 0.85), true)
	for sx in [-1.1, 1.1]:
		for sz in [-0.6, 0.6]:
			pf.box(stall, Vector3(0.1, 0.9, 0.1), Vector3(sx, 0.45, sz), pf.mat(Color(0.45, 0.32, 0.16), 0.85))
	# Tiang + atap terpal miring.
	for sx in [-1.2, 1.2]:
		for sz in [-0.7, 0.7]:
			pf.cyl(stall, 0.05, 2.2, Vector3(sx, 1.1, sz), pf.mat(Color(0.4, 0.3, 0.18), 0.85), false, 8)
	var roof := pf.box(stall, Vector3(3.0, 0.08, 2.2), Vector3(0, 2.3, 0), pf.mat(canopy, 0.9))
	roof.rotation.x = 0.12
