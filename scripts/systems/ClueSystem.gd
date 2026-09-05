class_name ClueSystem
extends RefCounted
## Logika murni untuk koleksi clue: validasi, relasi, dan statistik.


## Bangun index id -> data clue dari array mentah JSON.
static func build_index(raw: Array) -> Dictionary:
	var out: Dictionary = {}
	for entry in raw:
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) != "":
			var c: Dictionary = (entry as Dictionary).duplicate(true)
			c["name"] = str(c.get("name", "Clue"))
			c["type"] = str(c.get("type", "document"))
			c["description"] = str(c.get("description", ""))
			c["related_to"] = c.get("related_to", [])
			out[str(c["id"])] = c
	return out


## Daftar clue yang berhubungan dengan topik tertentu.
static func related_clues(index: Dictionary, topic: String) -> Array:
	var out: Array = []
	for k in index.keys():
		var rel: Array = (index[k] as Dictionary).get("related_to", [])
		if topic in rel:
			out.append(k)
	return out


## Hitung progres: {found:int, total:int, percent:float}.
static func progress(index: Dictionary, found: Array) -> Dictionary:
	var total: int = index.size()
	var n: int = 0
	for f in found:
		if index.has(str(f)):
			n += 1
	var pct: float = 0.0
	if total > 0:
		pct = float(n) / float(total) * 100.0
	return {"found": n, "total": total, "percent": pct}


## Kelompokkan clue yang ditemukan berdasarkan lokasi "found_in".
static func group_by_location(index: Dictionary, found: Array) -> Dictionary:
	var groups: Dictionary = {}
	for f in found:
		var key: String = str(f)
		if not index.has(key):
			continue
		var loc: String = str((index[key] as Dictionary).get("found_in", "unknown"))
		if not groups.has(loc):
			groups[loc] = []
		(groups[loc] as Array).append(key)
	return groups
