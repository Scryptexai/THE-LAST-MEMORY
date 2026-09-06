extends Node
## InvestigationManager — koleksi clue, inventory item, papan deduksi,
## catatan jurnal, timeline, dan hint.

var clues_found: Array = []        # Array[String]
var deductions_solved: Array = []  # Array[String]
var inventory: Array = []          # Array[String] item_id
var journal_notes: Array = []      # Array[Dictionary] {id, text, source}
var timeline_events: Array = []    # Array[Dictionary] {id, year, text}
var characters_met: Array = []     # Array[String]
var hints_left: int = 3
var moments_taken: Array = []    # Array[String] id momen yg diabadikan
var _note_counter: int = 0
var _timeline_counter: int = 0


func reset() -> void:
	clues_found.clear()
	deductions_solved.clear()
	inventory.clear()
	journal_notes.clear()
	timeline_events.clear()
	characters_met.clear()
	hints_left = 3
	moments_taken.clear()
	_note_counter = 0
	_timeline_counter = 0


# ---------- Clue ----------

func has_clue(clue_id: String) -> bool:
	return clue_id in clues_found


## Tambah clue; kembalikan false bila sudah dimiliki / tidak dikenal.
func add_clue(clue_id: String) -> bool:
	var dm := DataManager
	var bus := SignalBus
	if (dm.get_clue(clue_id) as Dictionary).is_empty():
		Logger.warn("InvestigationManager: clue tak dikenal: %s" % clue_id)
		return false
	if clue_id in clues_found:
		return false
	clues_found.append(clue_id)
	var clue_name: String = str((dm.get_clue(clue_id) as Dictionary).get("name", clue_id))
	bus.clue_found.emit(clue_id)
	bus.sfx_requested.emit("sfx_clue_found")
	bus.toast_requested.emit("%s: %s" % [dm.tr_key("toast_clue_found"), clue_name], "clue")
	add_journal_note("clue:" + clue_id, "%s — %s" % [clue_name, str((dm.get_clue(clue_id) as Dictionary).get("description", ""))], dm.tr_key("journal_src_clue"))
	AchievementManager.evaluate()
	SaveManager.autosave()
	return true


func clue_progress() -> Dictionary:
	var dm := DataManager
	return ClueSystem.progress(dm.clues, clues_found)


# ---------- Inventory ----------

func has_item(item_id: String) -> bool:
	return item_id in inventory


func add_item(item_id: String) -> bool:
	var dm := DataManager
	var bus := SignalBus
	if (dm.get_item(item_id) as Dictionary).is_empty():
		Logger.warn("InvestigationManager: item tak dikenal: %s" % item_id)
		return false
	if item_id in inventory:
		return false
	inventory.append(item_id)
	bus.item_added.emit(item_id)
	bus.inventory_updated.emit()
	bus.sfx_requested.emit("sfx_clue_found")
	bus.toast_requested.emit("%s: %s" % [dm.tr_key("toast_item_got"), str((dm.get_item(item_id) as Dictionary).get("name", item_id))], "item")
	return true


func remove_item(item_id: String) -> bool:
	if not (item_id in inventory):
		return false
	inventory.erase(item_id)
	var bus := SignalBus
	bus.item_removed.emit(item_id)
	bus.inventory_updated.emit()
	return true


## Pakai item pada target interactable. Dipanggil oleh InteractiveObject.
func use_item_on(item_id: String, target_id: String) -> bool:
	var dm := DataManager
	var bus := SignalBus
	if not (item_id in inventory):
		bus.toast_requested.emit(dm.tr_key("toast_item_missing"), "system")
		return false
	var item: Dictionary = dm.get_item(item_id)
	var usable_on: Array = item.get("usable_on", [])
	if not (target_id in usable_on):
		bus.toast_requested.emit(dm.tr_key("toast_item_noeffect"), "system")
		return false
	bus.item_used.emit(item_id, target_id)
	if bool(item.get("consumable", false)):
		remove_item(item_id)
	return true


# ---------- Deduksi ----------

func is_deduction_solved(ded_id: String) -> bool:
	return ded_id in deductions_solved


## Coba hubungkan clue terpilih menjadi deduksi.
func try_deduction(selected_clues: Array) -> Dictionary:
	var dm := DataManager
	var bus := SignalBus
	var result: Dictionary = DeductionSystem.try_solve(dm.deductions, deductions_solved, selected_clues)
	if bool(result.get("solved", false)):
		var ded_id: String = str(result["deduction_id"])
		deductions_solved.append(ded_id)
		var ded: Dictionary = dm.get_deduction(ded_id)
		bus.deduction_solved.emit(ded_id)
		bus.sfx_requested.emit("sfx_deduction_correct")
		bus.toast_requested.emit("%s: %s" % [dm.tr_key("toast_deduction"), str(ded.get("title", ded_id))], "deduction")
		add_journal_note("ded:" + ded_id, "%s — %s" % [str(ded.get("title", "")), str(ded.get("conclusion", ""))], dm.tr_key("journal_src_deduction"))
		# Terapkan efek deduksi (flags / buka dialog / timeline).
		var effects: Dictionary = ded.get("effects", {})
		GameManager.apply_effects(effects)
		AchievementManager.evaluate()
		SaveManager.autosave()
	else:
		bus.sfx_requested.emit("sfx_deduction_wrong")
	return result


# ---------- Hint ----------

func use_hint() -> Dictionary:
	# Kembalikan {ok, text} — hint cerdas berdasarkan progres.
	var dm := DataManager
	var bus := SignalBus
	if GameManager.hard_mode:
		return {"ok": false, "text": dm.tr_key("hint_hard")}
	if hints_left <= 0:
		return {"ok": false, "text": dm.tr_key("hint_empty")}
	hints_left -= 1
	bus.hint_used.emit(hints_left)
	var text: String = _compute_hint(dm)
	return {"ok": true, "text": text}


func _compute_hint(dm: Node) -> String:
	# 1) Bila ada deduksi yang resepnya lengkap tapi belum dipecahkan -> arahkan ke papan.
	var solvable: Array = DeductionSystem.solvable_with(dm.deductions, deductions_solved, clues_found)
	if not solvable.is_empty():
		var ded: Dictionary = dm.get_deduction(str(solvable[0]))
		return str(ded.get("hint", dm.tr_key("hint_board")))
	# 2) Cari deduksi berikutnya yang hampir lengkap -> beri tahu lokasi clue yang kurang.
	for ded_id in dm.deductions.keys():
		if ded_id in deductions_solved:
			continue
		var ded2: Dictionary = dm.deductions[ded_id]
		var missing: Array = []
		for req in ded2.get("required_clues", []):
			if not (str(req) in clues_found):
				missing.append(str(req))
		if missing.size() == 1:
			var clue: Dictionary = dm.get_clue(missing[0])
			var loc: String = str(clue.get("found_in", ""))
			var loc_name: String = str((dm.get_scene_data(loc) as Dictionary).get("name", loc))
			return dm.tr_key("hint_where").format({"clue": str(clue.get("name", "")), "loc": loc_name})
		if not missing.is_empty():
			return str(ded2.get("hint", dm.tr_key("hint_explore")))
	# 3) Semua deduksi selesai -> arahkan ke objektif.
	return dm.tr_key("hint_explore")


# ---------- Jurnal & timeline ----------

func add_journal_note(note_id: String, text: String, source: String = "") -> void:
	for n in journal_notes:
		if str((n as Dictionary).get("id", "")) == note_id:
			return  # sudah ada
	journal_notes.append({"id": note_id, "text": text, "source": source, "order": _note_counter})
	_note_counter += 1
	SignalBus.journal_updated.emit()


func add_timeline_event(event_id: String, year: String, text: String) -> void:
	for e in timeline_events:
		if str((e as Dictionary).get("id", "")) == event_id:
			return
	timeline_events.append({"id": event_id, "year": year, "text": text, "order": _timeline_counter})
	_timeline_counter += 1
	SignalBus.journal_updated.emit()


func mark_character_met(char_id: String) -> void:
	if char_id == "" or char_id == "none":
		return
	if not (char_id in characters_met):
		characters_met.append(char_id)
		var dm := DataManager
		var c: Dictionary = dm.get_character(char_id)
		if not c.is_empty():
			add_journal_note("met:" + char_id, dm.tr_key("journal_met").format({"name": str(c.get("name", char_id))}), dm.tr_key("journal_src_people"))


## Abadikan Momen: sembunyikan UI sejenak, jepret viewport, simpan PNG.
func capture_moment(moment_id: String) -> void:
	var dm := DataManager
	var bus := SignalBus
	var m: Dictionary = dm.get_moment(moment_id)
	if m.is_empty():
		return
	if moment_id in moments_taken:
		bus.toast_requested.emit(str(m.get("name", moment_id)), "system")
		return
	var ui := get_tree().get_first_node_in_group("ui_layer") as CanvasLayer
	if ui:
		ui.hide()
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if ui and is_instance_valid(ui):
		ui.show()
	if img == null or img.is_empty():
		Logger.warn("InvestigationManager: gagal mengabadikan momen.")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://moments"))
	if img.save_png("user://moments/%s.png" % moment_id) != OK:
		Logger.warn("InvestigationManager: gagal menyimpan momen.")
		return
	moments_taken.append(moment_id)
	bus.sfx_requested.emit("sfx_photo_taken")
	bus.toast_requested.emit("%s: %s" % [dm.tr_key("moment_taken"), str(m.get("name", moment_id))], "item")
	add_journal_note("moment:" + moment_id, "%s - %s" % [str(m.get("name", "")), str((dm.get_scene_data(str(m.get("location", ""))) as Dictionary).get("name", ""))], dm.tr_key("journal_src_moment"))
	GameManager.set_flag("moment_" + moment_id, true)
	AchievementManager.evaluate()
	SaveManager.autosave()


func has_moment(moment_id: String) -> bool:
	return moment_id in moments_taken
