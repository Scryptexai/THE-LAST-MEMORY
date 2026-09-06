class_name GullFlock
extends Node3D
## GullFlock — kawanan camar low-poly yang berputar pelan di langit pantai.
## Tiap camar = dua sayap quad yang mengepak; orbit + naik-turun halus.

@export var count: int = 5
@export var radius: float = 9.0
@export var height: float = 7.0
@export var speed: float = 0.35

var _birds: Array = []
var _t: float = 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1983
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 0.97)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in count:
		var b := Node3D.new()
		add_child(b)
		for side in [-1.0, 1.0]:
			var w := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(0.55, 0.16)
			w.mesh = q
			w.material_override = mat
			w.position = Vector3(side * 0.27, 0, 0)
			w.rotation.x = -PI / 2
			w.name = "WingL" if side < 0.0 else "WingR"
			b.add_child(w)
		_birds.append({
			"node": b,
			"phase": rng.randf() * TAU,
			"r": radius * rng.randf_range(0.7, 1.2),
			"h": height + rng.randf_range(-1.0, 1.5),
			"flap": rng.randf_range(4.0, 6.0),
		})


func _process(delta: float) -> void:
	_t += delta
	for info in _birds:
		var b: Node3D = info["node"]
		var ph: float = float(info["phase"])
		var a: float = _t * speed + ph
		var r: float = float(info["r"])
		b.position = Vector3(cos(a) * r, float(info["h"]) + sin(_t * 0.8 + ph) * 0.4, sin(a) * r)
		b.rotation.y = -a
		var flap: float = sin(_t * float(info["flap"]) + ph) * 0.6
		var wl := b.get_node_or_null("WingL") as Node3D
		var wr := b.get_node_or_null("WingR") as Node3D
		if wl:
			wl.rotation.z = flap
		if wr:
			wr.rotation.z = -flap
