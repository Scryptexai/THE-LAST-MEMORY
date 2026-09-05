extends "res://scripts/locations/LocationBase.gd"
## Kafe Rara — kafe cozy sudut kota: bar, meja-meja, foto dinding, teras.


func _build_layout() -> void:
	layout["spawn:default"] = {"pos": Vector3(0, 0, 8), "yaw": 0.0}
	layout["spawn:door"] = {"pos": Vector3(0, 0, 6.5), "yaw": 0.0}
	layout["npc:rara"] = {"pos": Vector3(-1.5, 0, -4.0), "yaw": 0.0}
	layout["npc:pak_harto"] = {"pos": Vector3(3.6, 0, 0.5), "yaw": -PI / 2}
	layout["obj:pintu_kafe"] = {"pos": Vector3(0, 0, 5.8)}
	layout["obj:foto_dinding"] = {"pos": Vector3(-4.9, 0, -1.0)}
	layout["obj:menu_kafe"] = {"pos": Vector3(0.5, 0, -4.0)}
	layout["obj:teh_counter"] = {"pos": Vector3(-2.8, 0, -3.6)}
	layout["obj:meja_harto"] = {"pos": Vector3(3.6, 0, 1.8)}
	layout["obj:papan_kafe"] = {"pos": Vector3(4.9, 0, -3.5)}
	layout["obj:teras_bunga"] = {"pos": Vector3(-4.0, 0, 6.5)}
	layout["obj:vista_etalase"] = {"pos": Vector3(0, 0, 8.2)}


func _build_visuals() -> void:
	pf.plane_ground(self, Vector2(60, 60), Vector3.ZERO, pf.mat(Color(0.45, 0.42, 0.38)))
	# Lantai kafe.
	pf.box(self, Vector3(12, 0.25, 11), Vector3(0, 0.12, 0), pf.mat(Color(0.6, 0.47, 0.32), 0.8))
	var wall := Color(0.93, 0.72, 0.5)
	pf.make_wall(self, Vector3(12, 2.6, 0.3), Vector3(0, 1.3, -5.5), wall)
	pf.make_wall(self, Vector3(0.3, 2.6, 11), Vector3(-6, 1.3, 0), wall)
	pf.make_wall(self, Vector3(0.3, 2.6, 11), Vector3(6, 1.3, 0), wall)
	pf.make_wall(self, Vector3(4.6, 2.6, 0.3), Vector3(-3.7, 1.3, 5.5), wall)
	pf.make_wall(self, Vector3(4.6, 2.6, 0.3), Vector3(3.7, 1.3, 5.5), wall)
	pf.make_door_frame(self, Vector3(0, 0.2, 5.5), 0.0)
	pf.box(self, Vector3(13, 0.25, 12), Vector3(0, 3.1, 0), pf.mat(Color(0.45, 0.2, 0.12), 0.8))
	# Etalase kaca depan (panel bening).
	pf.box(self, Vector3(3.4, 1.4, 0.1), Vector3(-3.7, 1.5, 5.5), pf.mat(Color(0.75, 0.87, 0.92, 0.45), 0.2))
	pf.box(self, Vector3(3.4, 1.4, 0.1), Vector3(3.7, 1.5, 5.5), pf.mat(Color(0.75, 0.87, 0.92, 0.45), 0.2))
	# Bar + rak.
	pf.make_counter(self, Vector3(-1.0, 0.25, -4.2), 0.0, 4.5)
	pf.make_shelf(self, Vector3(-1.0, 0.25, -5.1), 0.0)
	pf.make_cup(self, Vector3(-2.0, 1.3, -4.0))
	pf.make_cup(self, Vector3(-1.6, 1.3, -4.1))
	pf.make_cup(self, Vector3(-0.4, 1.3, -4.0), Color(0.85, 0.5, 0.4))
	# Papan menu.
	pf.box(self, Vector3(1.6, 1.0, 0.1), Vector3(0.5, 1.9, -5.3), pf.mat(Color(0.2, 0.18, 0.16), 0.9))
	# Meja pelanggan.
	for mx in [-3.5, 0.5, 3.5]:
		pf.make_table(self, Vector3(mx, 0.25, 1.0))
		pf.make_chair(self, Vector3(mx - 1.1, 0.25, 1.0), PI / 2)
		pf.make_chair(self, Vector3(mx + 1.1, 0.25, 1.0), -PI / 2)
		pf.make_cup(self, Vector3(mx + 0.3, 1.1, 0.8))
	pf.make_table(self, Vector3(3.6, 0.25, -2.5))
	pf.make_chair(self, Vector3(2.5, 0.25, -2.5), PI / 2)
	pf.make_book_stack(self, Vector3(3.4, 1.1, -2.6))
	# Foto dinding legendaris.
	for i in 4:
		pf.make_photo_frame(self, Vector3(-5.8, 1.7, -2.5 + i * 1.2), PI / 2, 0.45, 0.6)
	pf.make_photo_frame(self, Vector3(5.8, 1.7, -3.5), -PI / 2, 0.6, 0.75)
	# Papan pengumuman + lampu gantung.
	pf.box(self, Vector3(0.1, 1.2, 1.8), Vector3(5.85, 1.6, -1.0), pf.mat(Color(0.5, 0.38, 0.22), 0.85))
	pf.make_lamp(self, Vector3(-3.0, 0.25, 1.0))
	pf.make_lamp(self, Vector3(0.5, 0.25, -1.5))
	pf.make_lamp(self, Vector3(3.5, 0.25, 1.0))
	# Teras: pot bunga + kursi santai.
	for i in 3:
		pf.cyl(self, 0.25, 0.4, Vector3(-5.0 + i * 1.0, 0.45, 6.5), pf.mat(Color(0.7, 0.35, 0.2), 0.8), false, 10)
		pf.sphere(self, 0.3, Vector3(-5.0 + i * 1.0, 0.85, 6.5), pf.mat(Color(0.9, 0.4, 0.5), 0.8))
	pf.make_chair(self, Vector3(-3.0, 0, 6.8), PI)
	pf.make_streetlamp(self, Vector3(4.5, 0, 7.5))
	pf.make_streetlamp(self, Vector3(-6.5, 0, 3.0))
	# Jalan.
	pf.box(self, Vector3(60, 0.04, 5), Vector3(0, 0.02, 11), pf.mat(Color(0.3, 0.3, 0.32), 0.95))
