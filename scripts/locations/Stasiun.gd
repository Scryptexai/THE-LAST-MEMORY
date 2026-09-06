extends "res://scripts/locations/LocationBase.gd"
## Stasiun Kota Tua — stasiun mati yang suram: peron retak, loket kosong,
## papan jadwal 1983, dan gerbong tua yang menyimpan surat perintah.


func _build_layout() -> void:
	layout["spawn:default"] = {"pos": Vector3(0, 0, 8), "yaw": 0.0}
	layout["spawn:gate"] = {"pos": Vector3(-6, 0, 6), "yaw": PI / 4}
	layout["npc:penjaga"] = {"pos": Vector3(-5.5, 0, 1.0), "yaw": PI / 2}
	layout["obj:gerbang_stasiun"] = {"pos": Vector3(-6, 0, 7.5)}
	layout["obj:loket"] = {"pos": Vector3(-6.5, 0, -2.0)}
	layout["obj:kait_lampu"] = {"pos": Vector3(-5.0, 0, -2.6)}
	default_surface = "gravel"
	surface_zones = [{"rect": Rect2(-9.0, -1.5, 18.0, 6.0), "surface": "stone"}]  # peron beton
	layout["obj:papan_jadwal"] = {"pos": Vector3(5.5, 0, -1.5)}
	layout["obj:gerbong_gelap"] = {"pos": Vector3(2.0, 0, -5.5)}
	layout["obj:peluit_rel"] = {"pos": Vector3(-2.5, 0, -4.6)}
	layout["obj:plakat"] = {"pos": Vector3(0, 0, -0.5)}
	layout["obj:bangku_peron"] = {"pos": Vector3(-2.0, 0, 1.5)}
	layout["obj:vista_peron"] = {"pos": Vector3(0, 0, 6.5)}


var _loket_lamp: FlickerLight = null


func _ready() -> void:
	super()
	SignalBus.flag_changed.connect(_on_flag)
	_refresh_loket_lamp()


func _on_flag(flag_name: String, _v: Variant) -> void:
	if flag_name == "loket_terang":
		_refresh_loket_lamp()


## Lampu minyak loket menyala bila side-quest penjaga selesai.
func _refresh_loket_lamp() -> void:
	var on: bool = GameManager.flag_on("loket_terang")
	if on and _loket_lamp == null:
		pf.cyl(self, 0.09, 0.22, Vector3(-5.0, 1.9, -2.6), pf.mat(Color(0.3, 0.25, 0.2), 0.7), false, 8)
		pf.sphere(self, 0.07, Vector3(-5.0, 1.95, -2.6), pf.mat(Color(1.0, 0.75, 0.3), 0.4, Color(1.0, 0.75, 0.3), 3.0))
		_loket_lamp = FlickerLight.new()
		_loket_lamp.position = Vector3(-5.0, 2.0, -2.6)
		_loket_lamp.light_color = Color(1.0, 0.72, 0.35)
		_loket_lamp.light_energy = 1.6
		_loket_lamp.omni_range = 9.0
		_loket_lamp.flicker_amount = 0.2
		add_child(_loket_lamp)
		add_sound_source(Vector3(-5.0, 1.9, -2.6), "snd_lamp", 6.0, -10.0)


func _build_visuals() -> void:
	pf.plane_ground(self, Vector2(60, 60), Vector3.ZERO, pf.mat(Color(0.3, 0.3, 0.28)))
	# Peron.
	pf.box(self, Vector3(18, 0.5, 6), Vector3(0, 0.25, 1.5), pf.mat(Color(0.5, 0.48, 0.44), 0.9))
	pf.box(self, Vector3(18, 0.06, 0.4), Vector3(0, 0.53, -1.2), pf.mat(Color(0.8, 0.7, 0.3), 0.9))
	# Rel + kerikil.
	pf.box(self, Vector3(40, 0.1, 3.4), Vector3(0, 0.05, -4.5), pf.mat(Color(0.25, 0.24, 0.22), 0.95))
	pf.make_rails(self, Vector3(-20, 0.1, -4.5), Vector3(20, 0.1, -4.5))
	# Gerbong tua (terbengkalai) + satu gerbong utuh.
	pf.make_train_car(self, Vector3(2.0, 0.1, -4.5), 0.0, Color(0.45, 0.15, 0.12))
	pf.make_train_car(self, Vector3(-7.5, 0.1, -4.5), 0.0, Color(0.3, 0.32, 0.35))
	# Kanopi peron.
	for x in [-6, 0, 6]:
		pf.cyl(self, 0.09, 3.4, Vector3(x, 2.2, 3.5), pf.mat(Color(0.2, 0.2, 0.22), 0.6), true, 8)
	pf.box(self, Vector3(18, 0.15, 4), Vector3(0, 3.9, 2.5), pf.mat(Color(0.35, 0.3, 0.32), 0.8))
	# Gedung loket.
	pf.box(self, Vector3(4, 2.8, 3), Vector3(-7.5, 1.4, -1.0), pf.mat(Color(0.75, 0.68, 0.55), 0.9), true)
	pf.box(self, Vector3(4.6, 0.25, 3.6), Vector3(-7.5, 2.9, -1.0), pf.mat(Color(0.4, 0.2, 0.12), 0.85))
	pf.box(self, Vector3(1.4, 1.0, 0.15), Vector3(-5.45, 1.5, -1.0), pf.mat(Color(0.15, 0.18, 0.22), 0.6))
	# Papan jadwal raksasa.
	pf.box(self, Vector3(0.2, 1.8, 3.2), Vector3(5.5, 2.0, -1.5), pf.mat(Color(0.12, 0.14, 0.16), 0.9), true)
	pf.box(self, Vector3(0.22, 0.3, 3.0), Vector3(5.5, 2.6, -1.5), pf.mat(Color(0.85, 0.75, 0.5), 0.8))
	pf.cyl(self, 0.08, 1.2, Vector3(5.5, 0.6, -2.8), pf.mat(Color(0.2, 0.2, 0.22), 0.6), false, 8)
	pf.cyl(self, 0.08, 1.2, Vector3(5.5, 0.6, -0.2), pf.mat(Color(0.2, 0.2, 0.22), 0.6), false, 8)
	# Plakat peringatan.
	pf.box(self, Vector3(1.2, 0.9, 0.15), Vector3(0, 1.0, -0.5), pf.mat(Color(0.55, 0.5, 0.42), 0.7), true)
	pf.box(self, Vector3(0.9, 0.6, 0.17), Vector3(0, 1.05, -0.5), pf.mat(Color(0.7, 0.6, 0.35), 0.5, Color(0.7, 0.6, 0.35), 0.3))
	# Bangku + lampu redup + peluit kecil di rel.
	pf.box(self, Vector3(2.0, 0.1, 0.5), Vector3(-2.0, 0.95, 1.5), pf.mat(Color(0.4, 0.3, 0.18), 0.85), true)
	pf.make_streetlamp(self, Vector3(-4, 0.5, 3.5))
	pf.make_streetlamp(self, Vector3(4, 0.5, 3.5))
	pf.cyl(self, 0.05, 0.18, Vector3(-2.5, 0.2, -4.6), pf.mat(Color(0.8, 0.8, 0.85), 0.4), false, 8)
	# Semak liar + pagar rusak.
	pf.sphere(self, 0.5, Vector3(8, 0.4, 2), pf.mat(Color(0.3, 0.4, 0.24), 0.95))
	pf.sphere(self, 0.4, Vector3(-8.5, 0.35, 3), pf.mat(Color(0.3, 0.4, 0.24), 0.95))
	pf.make_fence(self, Vector3(-9, 0.5, 5), Vector3(-2, 0.5, 5))
	pf.make_dust_motes(self, Vector3(0, 1.5, -3.0), Vector3(6.0, 1.2, 2.5), Color(0.7, 0.7, 0.72, 0.35))
