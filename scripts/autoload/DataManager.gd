extends Node
## DataManager — memuat & menyediakan semua data JSON game (dialog, karakter,
## clue, item, lokasi, deduksi, ending, string UI, objektif).

const PATH_DIALOGUES := "res://assets/data/dialogues.json"
const PATH_CHARACTERS := "res://assets/data/characters.json"
const PATH_CLUES := "res://assets/data/clues.json"
const PATH_ITEMS := "res://assets/data/items.json"
const PATH_SCENES := "res://assets/data/scenes.json"
const PATH_DEDUCTIONS := "res://assets/data/deductions.json"
const PATH_ENDINGS := "res://assets/data/endings.json"
const PATH_STRINGS := "res://assets/data/ui_strings.json"
const PATH_OBJECTIVES := "res://assets/data/objectives.json"
const PATH_MOMENTS := "res://assets/data/moments.json"
const PATH_ACHIEVEMENTS := "res://assets/data/achievements.json"
const PATH_EPILOGUES := "res://assets/data/epilogues.json"
const PATH_QUESTS := "res://assets/data/quests.json"

var dialogues: Dictionary = {}      # id -> node
var characters: Dictionary = {}     # id -> data
var clues: Dictionary = {}          # id -> data
var items: Dictionary = {}          # id -> data
var scenes: Dictionary = {}         # id -> data
var deductions: Dictionary = {}     # id -> data
var endings: Dictionary = {}        # id -> data
var ui_strings: Dictionary = {}     # lang -> { key -> text }
var objectives: Dictionary = {}     # objective_id -> {text, text_en}
var moments: Dictionary = {}        # moment_id -> data
var achievements: Dictionary = {}   # ach_id -> data
var epilogues: Array = []           # Array[Dictionary] {id, character, icon, tiers[]}
var quests: Array = []              # Array[Dictionary] tugas sampingan (quests.json)

var language: String = "id"


func _ready() -> void:
	load_all()


## Muat ulang seluruh data dari disk.
func load_all() -> void:
	var dlg_raw: Array = _load_array(PATH_DIALOGUES, "dialogues")
	dialogues = DialogueParser.parse(dlg_raw)
	characters = _index(_load_array(PATH_CHARACTERS, "characters"))
	clues = ClueSystem.build_index(_load_array(PATH_CLUES, "clues"))
	items = _index(_load_array(PATH_ITEMS, "items"))
	scenes = _index(_load_array(PATH_SCENES, "scenes"))
	deductions = DeductionSystem.build_index(_load_array(PATH_DEDUCTIONS, "deductions"))
	endings = _index(_load_array(PATH_ENDINGS, "endings"))
	ui_strings = _load_dict(PATH_STRINGS)
	objectives = _index(_load_array(PATH_OBJECTIVES, "objectives"))
	moments = _index(_load_array(PATH_MOMENTS, "moments"))
	achievements = _index(_load_array(PATH_ACHIEVEMENTS, "achievements"))
	epilogues = _load_array(PATH_EPILOGUES, "epilogues")
	quests = _load_array(PATH_QUESTS, "quests")
	Logger.info("DataManager: %d dialog, %d karakter, %d clue, %d deduksi dimuat." % [
		dialogues.size(), characters.size(), clues.size(), deductions.size()])


func _load_array(path: String, key: String) -> Array:
	var text: String = SaveUtils.read_text_file(path)
	var data: Dictionary = SaveUtils.from_json(text)
	if data.has(key) and data[key] is Array:
		return data[key]
	if data.is_empty():
		Logger.warn("DataManager: gagal memuat %s" % path)
	return []


func _load_dict(path: String) -> Dictionary:
	return SaveUtils.from_json(SaveUtils.read_text_file(path))


func _index(raw: Array) -> Dictionary:
	var out: Dictionary = {}
	for entry in raw:
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) != "":
			out[str((entry as Dictionary)["id"])] = (entry as Dictionary).duplicate(true)
	return out


# ---------- Getters ----------

func get_dialogue(node_id: String) -> Dictionary:
	return dialogues.get(node_id, {})


func has_dialogue(node_id: String) -> bool:
	return dialogues.has(node_id)


func get_character(char_id: String) -> Dictionary:
	return characters.get(char_id, {})


func get_clue(clue_id: String) -> Dictionary:
	return clues.get(clue_id, {})


func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func get_moment(moment_id: String) -> Dictionary:
	return moments.get(moment_id, {})


func get_achievement(ach_id: String) -> Dictionary:
	return achievements.get(ach_id, {})


func get_scene_data(scene_id: String) -> Dictionary:
	return scenes.get(scene_id, {})


func get_deduction(ded_id: String) -> Dictionary:
	return deductions.get(ded_id, {})


func get_ending(ending_id: String) -> Dictionary:
	return endings.get(ending_id, {})


## Teks dialog sesuai bahasa aktif (fallback ke Indonesia).
func localized(node_or_choice: Dictionary) -> String:
	if language == "en" and str(node_or_choice.get("text_en", "")).strip_edges() != "":
		return str(node_or_choice["text_en"])
	return str(node_or_choice.get("text", "..."))


## String UI sesuai bahasa aktif.
func tr_key(key: String) -> String:
	var table: Dictionary = ui_strings.get(language, {})
	if table.has(key):
		return str(table[key])
	var fallback: Dictionary = ui_strings.get("id", {})
	return str(fallback.get(key, key))


func set_language(lang: String) -> void:
	if lang != "id" and lang != "en":
		return
	language = lang


## Epilog per tokoh berdasarkan nilai hubungan akhir: Array[{icon, name, text}].
func epilogue_lines() -> Array:
	var rm := RelationshipManager
	var im := InvestigationManager
	var out: Array = []
	var gm := GameManager
	for ep in epilogues:
		var e: Dictionary = ep
		var cid: String = str(e.get("character", ""))
		# Epilog berbasis flag (kota/warga): tier pertama yang semua flag-nya terpenuhi.
		if cid == "":
			for tier in e.get("tiers", []):
				var ft: Dictionary = tier
				var ok: bool = true
				var met_req: String = str(ft.get("met", ""))
				if met_req != "" and not (met_req in (im.characters_met as Array)):
					ok = false
				for f in ft.get("flags", []):
					if not bool(gm.get_flag(str(f), false)):
						ok = false
						break
				if ok:
					var ftxt: String = str(ft.get("text_en", "")) if language == "en" and str(ft.get("text_en", "")) != "" else str(ft.get("text", ""))
					if ftxt != "":
						out.append({"icon": str(e.get("icon", "•")), "name": tr_key(str(e.get("name_key", "epilogue_town"))), "text": ftxt})
					break
			continue
		if not (cid in (im.characters_met as Array)):
			continue
		var val: int = rm.get_value(cid)
		for tier in e.get("tiers", []):
			var t: Dictionary = tier
			if val >= int(t.get("min", 0)):
				var txt: String = str(t.get("text_en", "")) if language == "en" and str(t.get("text_en", "")) != "" else str(t.get("text", ""))
				out.append({"icon": str(e.get("icon", "•")), "name": str((get_character(cid) as Dictionary).get("name", cid)), "text": txt})
				break
	return out


## Node kilas balik yang bisa diputar ulang: node memory yang bukan lanjutan
## node memory lain, dan bukan bagian rangkaian final (berujung pilihan ending).
func memory_roots() -> Array:
	var continuations: Dictionary = {}
	for nid in dialogues.keys():
		var n: Dictionary = dialogues[nid]
		if bool(n.get("memory", false)):
			var nx: String = str(n.get("next", ""))
			if nx != "" and nx != "END":
				continuations[nx] = true
	var out: Array = []
	for nid in dialogues.keys():
		var n: Dictionary = dialogues[nid]
		if not bool(n.get("memory", false)):
			continue
		if continuations.has(nid) or str(nid).begins_with("dlg_final"):
			continue
		out.append(str(nid))
	out.sort()
	return out


## Lokasi tujuan objektif ("" bila tidak terikat lokasi, mis. papan deduksi).
func get_objective_location(objective_id: String) -> String:
	return str((objectives.get(objective_id, {}) as Dictionary).get("location", ""))


func get_objective(objective_id: String) -> String:
	var o: Dictionary = objectives.get(objective_id, {})
	if o.is_empty():
		return ""
	if language == "en" and str(o.get("text_en", "")).strip_edges() != "":
		return str(o["text_en"])
	return str(o.get("text", ""))
