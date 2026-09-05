class_name FlickerLight
extends OmniLight3D
## FlickerLight — lampu dengan kedip organik halus (lampu meja, lampu jalan,
## mercusuar, api unggun). Kombinasi tiga gelombang sinus agar hidup.


@export var flicker_amount: float = 0.12
@export var flicker_speed: float = 7.0

var base_energy: float = 1.0
var _t: float = 0.0
var _seed: float = 0.0


func _ready() -> void:
	_seed = float(get_instance_id() % 1000) / 100.0
	base_energy = light_energy


func _process(delta: float) -> void:
	_t += delta
	var n: float = sin(_t * flicker_speed + _seed) * 0.5 \
		+ sin(_t * flicker_speed * 2.7 + _seed * 1.7) * 0.3 \
		+ sin(_t * flicker_speed * 6.1 + _seed * 0.6) * 0.2
	light_energy = base_energy * (1.0 + n * flicker_amount)
