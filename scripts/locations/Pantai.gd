extends "res://scripts/locations/LocationBase.gd"
## Pantai — senja bittersweet: pasir, palem, perahu tua, dan mercusuar kecil.
## Tempat pengakuan Rara dan kebenaran terakhir sebelum kembali ke rumah.


func _build_layout() -> void:
	layout["spawn:default"] = {"pos": Vector3(0, 0, 10), "yaw": 0.0}
	layout["spawn:jetty"] = {"pos": Vector3(6, 0, 6), "yaw": -PI / 4}
	layout["npc:rara_pantai"] = {"pos": Vector3(-3.0, 0, -2.0), "yaw": PI}
	layout["npc:mira_pantai"] = {"pos": Vector3(5.0, 0, 2.0), "yaw": -PI / 2}
	layout["obj:jalan_pantai"] = {"pos": Vector3(0, 0, 8.5)}
	layout["obj:perahu_tua"] = {"pos": Vector3(-3.5, 0, -0.5)}
	layout["obj:batu_foto"] = {"pos": Vector3(-5.5, 0, -3.5)}
	layout["obj:bunga_liar"] = {"pos": Vector3(2.5, 0, 5.5)}
	layout["obj:mercusuar"] = {"pos": Vector3(9.0, 0, -4.0)}
	layout["obj:dermaga"] = {"pos": Vector3(7.5, 0, -1.0)}
	layout["obj:vista_senja"] = {"pos": Vector3(7.5, 0, 0.5)}
	default_surface = "sand"
	surface_zones = [{"rect": Rect2(6.7, -8.0, 1.6, 8.0), "surface": "plank"}]  # dermaga


func _build_visuals() -> void:
	# Pasir + laut (dua bidang).
	pf.plane_ground(self, Vector2(60, 60), Vector3.ZERO, pf.mat(Color(0.85, 0.75, 0.55)))
	var sea := MeshInstance3D.new()
	var sea_mesh := PlaneMesh.new()
	sea_mesh.size = Vector2(60, 24)
	sea_mesh.subdivide_width = 48
	sea_mesh.subdivide_depth = 20
	sea.mesh = sea_mesh
	sea.position = Vector3(0, -0.25, -20)
	var sea_shader := Shader.new()
	sea_shader.code = """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 col_deep : source_color = vec4(0.08, 0.25, 0.38, 1.0);
uniform vec4 col_foam : source_color = vec4(0.55, 0.8, 0.85, 1.0);
void vertex() {
\tVERTEX.y += sin(VERTEX.x * 0.6 + TIME * 1.2) * 0.12 + cos(VERTEX.z * 0.8 + TIME * 0.9) * 0.12;
}
void fragment() {
\tfloat band = 0.5 + 0.5 * sin(UV.y * 24.0 - TIME * 1.5);
\tALBEDO = mix(col_deep.rgb, col_foam.rgb, band * 0.25);
\tROUGHNESS = 0.25;
\tSPECULAR = 0.6;
}
"""
	var sea_mat := ShaderMaterial.new()
	sea_mat.shader = sea_shader
	sea.material_override = sea_mat
	add_child(sea)
	# Garis buih.
	pf.box(self, Vector3(60, 0.03, 0.8), Vector3(0, -0.05, -8.5), pf.mat(Color(0.95, 0.95, 0.9, 0.8), 0.6))
	# Palem berjajar.
	for x in [-8, -5, 8, 11, -11]:
		pf.make_palm(self, Vector3(x, 0, 4.0 + (x % 3)), 1.0 + (abs(x) % 2) * 0.2)
	pf.make_palm(self, Vector3(4, 0, -3), 1.1)
	# Perahu tua terbalik.
	var boat := Node3D.new()
	boat.position = Vector3(-3.5, 0, -0.5)
	boat.rotation.y = 0.5
	add_child(boat)
	pf.box(boat, Vector3(1.6, 0.5, 3.6), Vector3(0, 0.35, 0), pf.mat(Color(0.5, 0.35, 0.2), 0.85), true)
	pf.box(boat, Vector3(1.2, 0.15, 3.0), Vector3(0, 0.65, 0), pf.mat(Color(0.35, 0.24, 0.14), 0.9))
	# Batu + foto terselip.
	pf.sphere(self, 0.8, Vector3(-5.5, 0.2, -3.5), pf.mat(Color(0.45, 0.44, 0.42), 0.95))
	pf.box(self, Vector3(0.3, 0.02, 0.4), Vector3(-5.1, 0.75, -3.2), pf.mat(Color(0.88, 0.84, 0.72), 0.9))
	# Rumpun bunga liar.
	for i in 5:
		var bx: float = 2.0 + (i % 3) * 0.4
		var bz: float = 5.2 + (i / 3) * 0.5
		pf.cyl(self, 0.02, 0.4, Vector3(bx, 0.2, bz), pf.mat(Color(0.25, 0.45, 0.2), 0.9), false, 6)
		pf.sphere(self, 0.09, Vector3(bx, 0.45, bz), pf.mat(Color(0.95, 0.75, 0.3), 0.8))
	# Dermaga kayu + mercusuar mini.
	pf.box(self, Vector3(1.6, 0.15, 8.0), Vector3(7.5, 0.1, -4.0), pf.mat(Color(0.5, 0.38, 0.22), 0.9))
	for i in 4:
		pf.cyl(self, 0.08, 1.2, Vector3(6.9, -0.3, -1.0 - i * 1.8), pf.mat(Color(0.4, 0.3, 0.16), 0.9), false, 8)
		pf.cyl(self, 0.08, 1.2, Vector3(8.1, -0.3, -1.0 - i * 1.8), pf.mat(Color(0.4, 0.3, 0.16), 0.9), false, 8)
	pf.cyl(self, 0.9, 4.5, Vector3(9.0, 2.25, -4.0), pf.mat(Color(0.85, 0.82, 0.75), 0.8), true, 12)
	pf.cyl(self, 0.95, 0.6, Vector3(9.0, 1.2, -4.0), pf.mat(Color(0.8, 0.3, 0.2), 0.8), false, 12)
	pf.cyl(self, 0.95, 0.6, Vector3(9.0, 3.2, -4.0), pf.mat(Color(0.8, 0.3, 0.2), 0.8), false, 12)
	pf.sphere(self, 0.5, Vector3(9.0, 4.9, -4.0), pf.mat(Color(1.0, 0.9, 0.6), 0.4, Color(1.0, 0.9, 0.6), 2.0))
	var beacon := OmniLight3D.new()
	beacon.position = Vector3(9.0, 4.9, -4.0)
	beacon.light_color = Color(1.0, 0.9, 0.6)
	beacon.light_energy = 1.5
	beacon.omni_range = 14.0
	add_child(beacon)
	# Api unggun kecil (dekorasi).
	pf.cyl(self, 0.3, 0.25, Vector3(1.0, 0.12, -1.0), pf.mat(Color(0.3, 0.3, 0.3), 0.9), false, 10)
	pf.sphere(self, 0.18, Vector3(1.0, 0.35, -1.0), pf.mat(Color(1.0, 0.55, 0.15), 0.5, Color(1.0, 0.55, 0.15), 2.5))
	var fire := FlickerLight.new()
	fire.flicker_amount = 0.3
	fire.flicker_speed = 9.0
	fire.position = Vector3(1.0, 0.6, -1.0)
	fire.light_color = Color(1.0, 0.6, 0.25)
	fire.light_energy = 1.0
	fire.omni_range = 8.0
	add_child(fire)
	# Kunang-kunang senja di antara palem.
	pf.make_dust_motes(self, Vector3(-6.0, 1.0, 3.0), Vector3(3.0, 0.8, 2.0), Color(0.75, 1.0, 0.4, 0.6))
	pf.make_dust_motes(self, Vector3(3.0, 1.0, 6.0), Vector3(3.0, 0.8, 2.0), Color(0.75, 1.0, 0.4, 0.6))
