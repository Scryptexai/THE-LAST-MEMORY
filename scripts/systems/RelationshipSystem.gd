class_name RelationshipSystem
extends RefCounted
## Perhitungan hubungan: clamp, level label, dan cek ambang dialog spesial.


## Label level hubungan berdasarkan nilai dan maksimum karakter.
static func level_label(value: int, maximum: int) -> String:
	if maximum <= 0:
		return "—"
	var ratio: float = float(value) / float(maxi(maximum, 1))
	if ratio <= 0.0:
		return "Asing"
	if ratio < 0.35:
		return "Kenal"
	if ratio < 0.6:
		return "Akrab"
	if ratio < 0.85:
		return "Dekat"
	return "Percaya"


## Terapkan delta dengan clamp 0..maks. Kembalikan {old, new}.
static func apply(values: Dictionary, char_id: String, delta: int, maximum: int) -> Dictionary:
	var old: int = int(values.get(char_id, 0))
	var new_val: int = clampi(old + delta, 0, maxi(maximum, 0))
	values[char_id] = new_val
	return {"old": old, "new": new_val}


## Apakah nilai memenuhi ambang (threshold)?
static func meets(values: Dictionary, char_id: String, threshold: int) -> bool:
	return int(values.get(char_id, 0)) >= threshold


## Ringkasan semua hubungan untuk panel jurnal.
static func summary(values: Dictionary, roster: Dictionary) -> Array:
	var out: Array = []
	for char_id in roster.keys():
		var maxv: int = int((roster[char_id] as Dictionary).get("relationship_max", 10))
		var val: int = int(values.get(char_id, 0))
		out.append({
			"id": char_id,
			"name": str((roster[char_id] as Dictionary).get("name", char_id)),
			"value": val, "max": maxv,
			"level": level_label(val, maxv),
		})
	return out
