extends "res://scripts/locations/LocationBase.gd"
## Rumah Nenek — rumah kolonial hangat: ruang tamu, kamar, dapur, dan loteng.
## Tanpa langit-langit agar kamera third-person leluasa (gaya diorama).


func _build_layout() -> void:
	layout["spawn:default"] = {"pos": Vector3(0, 0, 9), "yaw": 0.0}
	layout["spawn:intro"] = {"pos": Vector3(0, 0, 12), "yaw": 0.0}
	layout["spawn:door"] = {"pos": Vector3(0, 0, 7.5), "yaw": 0.0}
	layout["npc:bu_rt"] = {"pos": Vector3(4.6, 0, 9.2), "yaw": PI / 2}
	layout["obj:pintu_depan"] = {"pos": Vector3(0, 0, 6.2)}
	layout["obj:surat_loteng"] = {"pos": Vector3(-4.5, 0, -4.5)}
	layout["obj:kotak_kayu"] = {"pos": Vector3(-5.5, 0, -3.5)}
	layout["obj:laci_dapur"] = {"pos": Vector3(5.0, 0, -3.0)}
	layout["obj:album_foto"] = {"pos": Vector3(2.8, 0, 1.5)}
	layout["obj:foto_kamar"] = {"pos": Vector3(4.8, 0, 2.5)}
	layout["obj:laci_tulis"] = {"pos": Vector3(-2.5, 0, 1.5)}
	layout["obj:rak_buku"] = {"pos": Vector3(-3.0, 0, 3.5)}
	layout["obj:radio_tua"] = {"pos": Vector3(0.5, 0, -4.8)}
	layout["obj:tempat_tidur"] = {"pos": Vector3(4.8, 0, 4.2)}
	layout["obj:vista_teras"] = {"pos": Vector3(0, 0, 10.5)}
	default_surface = "grass"
	surface_zones = [
		{"rect": Rect2(-7.0, -6.0, 14.0, 12.0), "surface": "wood"},   # lantai rumah
		{"rect": Rect2(-1.0, 6.5, 2.0, 6.0), "surface": "stone"},     # jalan setapak teras
	]


func _build_visuals() -> void:
	# Tanah + halaman.
	pf.plane_ground(self, Vector2(60, 60), Vector3.ZERO, pf.mat(Color(0.32, 0.4, 0.26)))
	pf.box(self, Vector3(14, 0.25, 12), Vector3(0, 0.12, 0), pf.mat(Color(0.55, 0.42, 0.28), 0.8))
	# Dinding (setinggi 2.2, tanpa atap penuh — hanya lis atap di sisi).
	var wall := Color(0.88, 0.8, 0.68)
	pf.make_wall(self, Vector3(14, 2.6, 0.3), Vector3(0, 1.3, -6), wall)
	pf.make_wall(self, Vector3(0.3, 2.6, 12), Vector3(-7, 1.3, 0), wall)
	pf.make_wall(self, Vector3(0.3, 2.6, 12), Vector3(7, 1.3, 0), wall)
	pf.make_wall(self, Vector3(5.4, 2.6, 0.3), Vector3(-4.3, 1.3, 6), wall)
	pf.make_wall(self, Vector3(5.4, 2.6, 0.3), Vector3(4.3, 1.3, 6), wall)
	pf.make_door_frame(self, Vector3(0, 0.2, 6), 0.0)
	# Sekat ruangan.
	pf.make_wall(self, Vector3(0.25, 2.4, 7), Vector3(2.0, 1.2, 2.0), Color(0.85, 0.76, 0.62))
	pf.make_wall(self, Vector3(9, 2.4, 0.25), Vector3(-2.5, 1.2, -1.5), Color(0.85, 0.76, 0.62))
	# Atap lis (pinggiran) + jendela.
	pf.box(self, Vector3(15, 0.25, 13), Vector3(0, 3.1, 0), pf.mat(Color(0.5, 0.25, 0.15), 0.8))
	pf.make_window(self, Vector3(-7, 1.6, 2), PI / 2)
	pf.make_window(self, Vector3(7, 1.6, -3), -PI / 2)
	pf.make_window(self, Vector3(-3, 1.6, -6), 0.0)
	# Ruang tamu.
	pf.make_table(self, Vector3(-2.5, 0.25, 2.0))
	pf.make_chair(self, Vector3(-3.5, 0.25, 2.0), PI / 2)
	pf.make_chair(self, Vector3(-1.5, 0.25, 2.0), -PI / 2)
	pf.make_shelf(self, Vector3(-3.0, 0.25, 3.5), PI)
	pf.make_rug(self, Vector3(-1.0, 0.25, 2.0), Vector2(3, 2), Color(0.7, 0.3, 0.3))
	pf.make_cup(self, Vector3(-2.2, 0.85, 1.8))
	pf.make_photo_frame(self, Vector3(1.85, 1.7, 2.5), -PI / 2)
	# Meja tulis + laci.
	pf.make_table(self, Vector3(-2.5, 0.25, 1.5))
	pf.make_book_stack(self, Vector3(-2.8, 1.1, 1.4))
	pf.make_lamp(self, Vector3(-5.5, 0.25, 4.5))
	# Kamar (kanan).
	pf.make_bed(self, Vector3(4.8, 0.25, 4.2))
	pf.make_photo_frame(self, Vector3(4.8, 1.7, 5.85), PI)
	pf.box(self, Vector3(1.2, 1.8, 0.6), Vector3(6.2, 1.1, 4.5), pf.mat(Color(0.4, 0.26, 0.14), 0.8), true)
	# Dapur (kanan belakang).
	pf.make_counter(self, Vector3(5.0, 0.25, -3.0), PI)
	pf.make_crate(self, Vector3(6.0, 0.25, -4.5))
	pf.make_crate(self, Vector3(5.2, 0.25, -4.8), 0.6)
	# Loteng (kiri belakang): peti + tumpukan kardus + tangga.
	pf.make_crate(self, Vector3(-5.5, 0.25, -3.5), 1.1)
	pf.make_crate(self, Vector3(-4.3, 0.25, -4.8), 0.8)
	pf.make_crate(self, Vector3(-4.4, 1.05, -4.8), 0.6)
	pf.box(self, Vector3(1.4, 0.12, 0.9), Vector3(-4.5, 0.9, -4.5), pf.mat(Color(0.75, 0.68, 0.55), 0.9))
	pf.box(self, Vector3(1.2, 0.1, 0.8), Vector3(-4.5, 1.0, -4.5), pf.mat(Color(0.82, 0.76, 0.62), 0.9))
	for i in 5:  # anak tangga dekoratif ke "loteng"
		pf.box(self, Vector3(1.0, 0.12, 0.35), Vector3(-6.2, 0.4 + i * 0.35, -1.5 - i * 0.3), pf.mat(Color(0.5, 0.36, 0.2), 0.85))
	# Radio + lampu.
	pf.box(self, Vector3(0.7, 0.4, 0.3), Vector3(0.5, 0.6, -4.8), pf.mat(Color(0.3, 0.2, 0.12), 0.7))
	pf.make_lamp(self, Vector3(4.5, 0.25, 0.5))
	pf.make_lamp(self, Vector3(-4.5, 0.25, -2.5))
	pf.make_dust_motes(self, Vector3(-2.0, 1.5, -2.0), Vector3(4.0, 1.2, 3.0))
	pf.make_dust_motes(self, Vector3(3.0, 1.5, 2.0), Vector3(3.0, 1.2, 3.0))
	# Halaman: pohon + pagar + jalan setapak.
	pf.make_tree(self, Vector3(-9, 0, 4), 1.2)
	pf.make_tree(self, Vector3(9, 0, 2), 1.0)
	pf.make_fence(self, Vector3(-8, 0, 8), Vector3(-1.5, 0, 8))
	pf.make_fence(self, Vector3(1.5, 0, 8), Vector3(8, 0, 8))
	pf.box(self, Vector3(2, 0.05, 6), Vector3(0, 0.03, 9.5), pf.mat(Color(0.6, 0.55, 0.5), 0.95))
