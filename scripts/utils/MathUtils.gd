class_name MathUtils
extends RefCounted
## Fungsi bantuan matematika umum (tanpa state).


## Interpolasi smoothstep untuk transisi kamera / UI.
static func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t: float = clampf((x - edge0) / maxf(edge1 - edge0, 0.00001), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Pendekatan sudut dengan handling wrap-around (-PI..PI).
static func lerp_angle_stable(from: float, to: float, weight: float) -> float:
	return from + _angle_diff(from, to) * clampf(weight, 0.0, 1.0)


static func _angle_diff(from: float, to: float) -> float:
	var diff: float = fmod(to - from + PI * 3.0, PI * 2.0) - PI
	return diff


## Acak float dalam rentang memakai RNG global.
static func randf_range_seeded(rng: RandomNumberGenerator, low: float, high: float) -> float:
	return low + rng.randf() * (high - low)


## Format detik menjadi "MM:SS" atau "H:MM:SS".
static func format_playtime(seconds: float) -> String:
	var total: int = int(seconds)
	var h: int = total / 3600
	var m: int = (total % 3600) / 60
	var s: int = total % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, s]
	return "%02d:%02d" % [m, s]
