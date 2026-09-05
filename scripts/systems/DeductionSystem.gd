class_name DeductionSystem
extends RefCounted
## Logika papan deduksi: mencocokkan set clue dengan resep deduksi.


## Bangun index id -> data deduksi dari array mentah JSON.
static func build_index(raw: Array) -> Dictionary:
	var out: Dictionary = {}
	for entry in raw:
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) != "":
			var d: Dictionary = (entry as Dictionary).duplicate(true)
			d["title"] = str(d.get("title", "Deduksi"))
			d["required_clues"] = d.get("required_clues", [])
			d["requires_deductions"] = d.get("requires_deductions", [])
			out[str(d["id"])] = d
	return out


## Coba pecahkan deduksi dari clue terpilih. Kembalikan {solved:bool, deduction_id, reason}.
static func try_solve(index: Dictionary, solved: Array, selected: Array) -> Dictionary:
	var sel: Array = selected.map(func(c: Variant) -> String: return str(c))
	sel.sort()
	for ded_id in index.keys():
		if ded_id in solved:
			continue
		var ded: Dictionary = index[ded_id]
		var req: Array = ((ded.get("required_clues", []) as Array).duplicate() as Array).map(
			func(c: Variant) -> String: return str(c))
		(req as Array).sort()
		if _same_set(sel, req):
			# Cek prasyarat deduksi lain.
			for pre in ded.get("requires_deductions", []):
				if not (str(pre) in solved):
					return {"solved": false, "deduction_id": "", "reason": "Ada kesimpulan awal yang harus ditemukan dulu."}
			return {"solved": true, "deduction_id": str(ded_id), "reason": ""}
	# Beri umpan balik parsial: apakah pilihan mendekati salah satu resep?
	var best: int = 0
	for ded_id in index.keys():
		if ded_id in solved:
			continue
		var req2: Array = (index[ded_id] as Dictionary).get("required_clues", [])
		var overlap: int = 0
		for c in sel:
			if c in req2:
				overlap += 1
		best = maxi(best, overlap)
	if best > 0 and best >= sel.size() - 1 and sel.size() >= 2:
		return {"solved": false, "deduction_id": "", "reason": "Hampir benar — ada satu petunjuk yang kurang pas."}
	return {"solved": false, "deduction_id": "", "reason": "Petunjuk-petunjuk itu belum membentuk kesimpulan."}


static func _same_set(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if str(a[i]) != str(b[i]):
			return false
	return true


## Deduksi mana saja yang resepnya sudah terkumpul lengkap (untuk hint sistem).
static func solvable_with(index: Dictionary, solved: Array, found_clues: Array) -> Array:
	var out: Array = []
	var have: Dictionary = {}
	for c in found_clues:
		have[str(c)] = true
	for ded_id in index.keys():
		if ded_id in solved:
			continue
		var ok: bool = true
		for req in (index[ded_id] as Dictionary).get("required_clues", []):
			if not have.has(str(req)):
				ok = false
				break
		if ok:
			for pre in (index[ded_id] as Dictionary).get("requires_deductions", []):
				if not (str(pre) in solved):
					ok = false
					break
		if ok:
			out.append(ded_id)
	return out
