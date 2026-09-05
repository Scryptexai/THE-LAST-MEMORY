class_name DialogueParser
extends RefCounted
## Parser & validator data dialog dari JSON menjadi struktur node yang siap dipakai.
##
## Format node yang didukung:
## {
##   "id": "dlg_...", "speaker": "Ardi", "text": "...", "text_en": "...",
##   "next": "dlg_...",                    # lanjutan linear (opsional)
##   "memory": true,                        # tampil sebagai kilas balik 1983
##   "choices": [ { "text":..., "text_en":..., "next":...,
##                  "flags":{...}, "relationship":{"rara":2},
##                  "requires_flags":{...}, "requires_clues":[...],
##                  "requires_deduction":"...", "requires_relationship":{"rara":10},
##                  "locked_hint":"..." } ],
##   "effects": { "flags":{...}, "add_clues":[...], "add_items":[...],
##                "relationship":{...}, "journal":"...", "timeline":"...",
##                "deduction_reveal":"...", "chapter":"...", "move_to":"...",
##                "objective":"...", "sfx":"...", "ending_choice":"..." }
## }


## Parse array mentah dialogues.json menjadi Dictionary id -> node ternormalisasi.
static func parse(raw: Array) -> Dictionary:
	var out: Dictionary = {}
	for entry in raw:
		if not (entry is Dictionary):
			continue
		var node: Dictionary = (entry as Dictionary).duplicate(true)
		if not node.has("id") or str(node["id"]).is_empty():
			Logger.warn("DialogueParser: node tanpa id dilewati.")
			continue
		node["speaker"] = str(node.get("speaker", "???"))
		node["text"] = str(node.get("text", "..."))
		node["choices"] = _normalize_choices(node.get("choices", []))
		node["effects"] = node.get("effects", {})
		if not (node["effects"] is Dictionary):
			node["effects"] = {}
		node["memory"] = bool(node.get("memory", false))
		out[str(node["id"])] = node
	return out


static func _normalize_choices(raw: Variant) -> Array:
	var out: Array = []
	if not (raw is Array):
		return out
	for c in (raw as Array):
		if not (c is Dictionary):
			continue
		var choice: Dictionary = (c as Dictionary).duplicate(true)
		choice["text"] = str(choice.get("text", "..."))
		choice["next"] = str(choice.get("next", ""))
		out.append(choice)
	return out


## Cek apakah sebuah choice memenuhi syarat untuk dipilih.
static func is_choice_available(choice: Dictionary, ctx: Dictionary) -> Dictionary:
	# ctx: { flags:Dictionary, clues:Array, deductions:Array, relationships:Dictionary }
	var req_flags: Dictionary = choice.get("requires_flags", {})
	for k in req_flags.keys():
		var have: Variant = (ctx.get("flags", {}) as Dictionary).get(k, null)
		if str(have) != str(req_flags[k]):
			return {"ok": false, "reason": str(choice.get("locked_hint", "Belum memenuhi syarat."))}
	for clue_id in choice.get("requires_clues", []):
		if not (str(clue_id) in (ctx.get("clues", []) as Array).map(func(c: Variant) -> String: return str(c))):
			return {"ok": false, "reason": str(choice.get("locked_hint", "Butuh petunjuk tertentu."))}
	var req_ded: String = str(choice.get("requires_deduction", ""))
	if req_ded != "" and not (req_ded in (ctx.get("deductions", []) as Array)):
		return {"ok": false, "reason": str(choice.get("locked_hint", "Butuh deduksi tertentu."))}
	for item_id in choice.get("requires_items", []):
		if not (str(item_id) in (ctx.get("items", []) as Array).map(func(c: Variant) -> String: return str(c))):
			return {"ok": false, "reason": str(choice.get("locked_hint", "Butuh barang tertentu."))}
	var req_rel: Dictionary = choice.get("requires_relationship", {})
	for k in req_rel.keys():
		var val: int = int((ctx.get("relationships", {}) as Dictionary).get(k, 0))
		if val < int(req_rel[k]):
			return {"ok": false, "reason": str(choice.get("locked_hint", "Hubungan belum cukup dekat."))}
	return {"ok": true, "reason": ""}
