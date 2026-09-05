extends Node
## DialogueManager — menjalankan dialog branching dari JSON.
## Mendukung efek samping (flags, clue, relasi, jurnal), syarat choice,
## kilas balik memori (psychometry), dan riwayat pilihan untuk save.

var active: bool = false
var dialogue_id: String = ""     # id node awal dialog yang sedang berjalan
var current_node: Dictionary = {}
var history: Array = []          # Array[Dictionary] {node, choice, text, time}
var _memory_open: bool = false


func is_active() -> bool:
	return active


## Mulai dialog dari node tertentu. Kembalikan false bila node tak ada.
func start_dialogue(node_id: String) -> bool:
	var dm := DataManager
	if not dm.has_dialogue(node_id):
		Logger.warn("DialogueManager: node tidak ada: %s" % node_id)
		return false
	active = true
	dialogue_id = node_id
	GameManager.change_state("dialogue")
	SignalBus.dialogue_started.emit(node_id)
	_show_node(node_id)
	return true


## Tampilkan node (terapkan efek on-enter, tandai karakter, dsb).
func _show_node(node_id: String) -> void:
	var dm := DataManager
	var bus := SignalBus
	current_node = dm.get_dialogue(node_id)
	if current_node.is_empty():
		finish()
		return
	# Tandai pembicara sebagai "dikenal".
	_mark_speaker_met(str(current_node.get("speaker_id", current_node.get("speaker", ""))))
	# Efek saat node ditampilkan.
	var effects: Dictionary = current_node.get("effects", {})
	_apply_choice_side_effects({}, true)
	GameManager.apply_effects(effects)
	# Mode memori?
	var is_memory: bool = bool(current_node.get("memory", false))
	if is_memory and not _memory_open:
		_memory_open = true
		bus.memory_flashback_started.emit(node_id)
		bus.ambient_requested.emit("ambient_memory")
		bus.music_requested.emit("music_memory")
	elif not is_memory and _memory_open:
		_memory_open = false
		bus.memory_flashback_ended.emit(node_id)
		GameManager.restore_location_audio()
	bus.dialogue_node_shown.emit(node_id)


func _mark_speaker_met(speaker: String) -> void:
	var key: String = speaker.strip_edges().to_lower().replace(" ", "_")
	var im := InvestigationManager
	var dm := DataManager
	if dm.characters.has(key):
		im.mark_character_met(key)
	# Nama tampilan Indonesia -> id karakter.
	var alias := {"ardi": "ardi", "rara": "rara", "pak harto": "pak_harto", "harto": "pak_harto",
		"mira": "mira", "nenek": "nenek", "lastri": "nenek", "darmo": "darmo", "???": ""}
	if alias.has(key) and str(alias[key]) != "":
		im.mark_character_met(str(alias[key]))


## Lanjut ke node "next" (dialog linear). Jika ada pilihan, abaikan.
func advance() -> void:
	if not active:
		return
	if not (current_node.get("choices", []) as Array).is_empty():
		return  # harus memilih dulu
	var next_id: String = str(current_node.get("next", ""))
	if next_id == "" or next_id == "END":
		finish()
	else:
		_show_node(next_id)


## Pilih salah satu choice (index). Terapkan syarat + efeknya.
func choose(index: int) -> bool:
	if not active:
		return false
	var choices: Array = current_node.get("choices", [])
	if index < 0 or index >= choices.size():
		return false
	var choice: Dictionary = choices[index]
	var avail: Dictionary = choice_availability(choice)
	if not bool(avail.get("ok", false)):
		var bus := SignalBus
		bus.toast_requested.emit(str(avail.get("reason", "")), "system")
		bus.sfx_requested.emit("sfx_deduction_wrong")
		return false
	var dm := DataManager
	var bus2 := SignalBus
	history.append({"node": str(current_node.get("id", "")), "choice": index,
		"text": dm.localized(choice), "time": SaveManager.playtime})
	bus2.dialogue_choice_made.emit(str(current_node.get("id", "")), index, dm.localized(choice))
	bus2.sfx_requested.emit("sfx_dialogue_click")
	_apply_choice_side_effects(choice, false)
	var next_id: String = str(choice.get("next", ""))
	# Efek yang melekat pada choice (setara effects node).
	GameManager.apply_effects(_choice_effects(choice))
	if next_id == "" or next_id == "END":
		finish()
	else:
		_show_node(next_id)
	return true


## Cek ketersediaan choice berdasarkan kondisi game saat ini.
func choice_availability(choice: Dictionary) -> Dictionary:
	var gm := GameManager
	var im := InvestigationManager
	var rm := RelationshipManager
	var ctx := {"flags": gm.flags, "clues": im.clues_found,
		"deductions": im.deductions_solved, "relationships": rm.values,
		"items": im.inventory}
	return DialogueParser.is_choice_available(choice, ctx)


func _choice_effects(choice: Dictionary) -> Dictionary:
	return {
		"flags": choice.get("flags", {}),
		"add_clues": choice.get("add_clues", []),
		"add_items": choice.get("add_items", []),
		"relationship": choice.get("relationship", {}),
		"journal": str(choice.get("journal", "")),
		"timeline": choice.get("timeline", {}),
		"chapter": str(choice.get("chapter", "")),
		"objective": str(choice.get("objective", "")),
		"move_to": str(choice.get("move_to", "")),
		"ending_choice": str(choice.get("ending_choice", "")),
	}


func _apply_choice_side_effects(_choice: Dictionary, _is_node_enter: bool) -> void:
	# (Efek flags/relasi node & choice semuanya lewat GameManager.apply_effects
	# agar konsisten; fungsi ini dipertahankan sebagai hook ekstensi.)
	pass


func finish() -> void:
	if not active:
		return
	var last: String = str(current_node.get("id", ""))
	active = false
	current_node = {}
	if _memory_open:
		_memory_open = false
		SignalBus.memory_flashback_ended.emit(last)
		GameManager.restore_location_audio()
	SignalBus.dialogue_finished.emit(dialogue_id, last)
	dialogue_id = ""
	GameManager.change_state("gameplay")
	SaveManager.autosave()


func cancel() -> void:
	finish()
