extends Node
## SaveManager — menyimpan & memuat progres pemain (slot 1..3 + autosave).
##
## Struktur save:
## { version, timestamp, playtime, chapter, location, spawn_tag, flags,
##   choices_made, clues_found, deductions_solved, relationships, inventory,
##   journal_notes, timeline_events, hints_left, final_choice, endings_seen,
##   settings:{music_volume, sfx_volume, ambient_volume, language} }

const SAVE_VERSION := 3
const SLOT_COUNT := 3
const SAVE_PATH := "user://save_slot_%d.json"
const AUTOSAVE_PATH := "user://autosave.json"

var playtime: float = 0.0
var _tracking: bool = false


func _process(delta: float) -> void:
	if _tracking:
		playtime += delta


func start_tracking() -> void:
	_tracking = true


func stop_tracking() -> void:
	_tracking = false


func reset_playtime() -> void:
	playtime = 0.0


## Susun Dictionary save dari seluruh manager.
func collect() -> Dictionary:
	var gm := GameManager
	var im := InvestigationManager
	var rm := RelationshipManager
	var dm := DialogueManager
	var am := AudioManager
	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"playtime": playtime,
		"chapter": gm.current_chapter,
		"location": gm.current_location,
		"spawn_tag": gm.last_spawn_tag,
		"objective": gm.current_objective,
		"flags": SaveUtils.deep_copy(gm.flags),
		"choices_made": SaveUtils.deep_copy(dm.history),
		"effects_applied": SaveUtils.deep_copy(dm.effects_applied),
		"clues_found": SaveUtils.deep_copy(im.clues_found),
		"deductions_solved": SaveUtils.deep_copy(im.deductions_solved),
		"relationships": SaveUtils.deep_copy(rm.values),
		"inventory": SaveUtils.deep_copy(im.inventory),
		"journal_notes": SaveUtils.deep_copy(im.journal_notes),
		"timeline_events": SaveUtils.deep_copy(im.timeline_events),
		"characters_met": SaveUtils.deep_copy(im.characters_met),
		"hints_left": im.hints_left,
		"final_choice": gm.final_choice,
		"endings_seen": SaveUtils.deep_copy(gm.endings_seen),
		"settings": {
			"music_volume": am.music_volume,
			"sfx_volume": am.sfx_volume,
			"ambient_volume": am.ambient_volume,
			"language": DataManager.language,
		},
	}


## Terapkan Dictionary save ke seluruh manager.
func apply(data: Dictionary) -> bool:
	if data.is_empty() or int(data.get("version", 0)) > SAVE_VERSION:
		Logger.warn("SaveManager: versi save tidak dikenali.")
		return false
	var gm := GameManager
	var im := InvestigationManager
	var rm := RelationshipManager
	var dm := DialogueManager
	var am := AudioManager
	playtime = float(data.get("playtime", 0.0))
	gm.current_chapter = str(data.get("chapter", "prolog"))
	gm.current_location = str(data.get("location", "rumah_nenek"))
	gm.last_spawn_tag = str(data.get("spawn_tag", "default"))
	gm.current_objective = str(data.get("objective", "obj_datang"))
	gm.flags = (data.get("flags", {}) as Dictionary).duplicate(true)
	gm.final_choice = str(data.get("final_choice", ""))
	gm.endings_seen = (data.get("endings_seen", []) as Array).duplicate(true)
	dm.history = (data.get("choices_made", []) as Array).duplicate(true)
	dm.effects_applied = (data.get("effects_applied", []) as Array).duplicate(true)
	im.clues_found = (data.get("clues_found", []) as Array).duplicate(true)
	im.deductions_solved = (data.get("deductions_solved", []) as Array).duplicate(true)
	im.inventory = (data.get("inventory", []) as Array).duplicate(true)
	im.journal_notes = (data.get("journal_notes", []) as Array).duplicate(true)
	im.timeline_events = (data.get("timeline_events", []) as Array).duplicate(true)
	im.characters_met = (data.get("characters_met", []) as Array).duplicate(true)
	im.hints_left = int(data.get("hints_left", 3))
	rm.values = (data.get("relationships", {}) as Dictionary).duplicate(true)
	var settings: Dictionary = data.get("settings", {})
	if not settings.is_empty():
		am.set_music_volume(float(settings.get("music_volume", 0.8)))
		am.set_sfx_volume(float(settings.get("sfx_volume", 0.9)))
		am.set_ambient_volume(float(settings.get("ambient_volume", 0.7)))
		DataManager.set_language(str(settings.get("language", "id")))
	Logger.info("SaveManager: save diterapkan (chapter=%s, lokasi=%s)." % [gm.current_chapter, gm.current_location])
	return true


func save_to_slot(slot: int) -> bool:
	if slot < 1 or slot > SLOT_COUNT:
		return false
	var ok: bool = SaveUtils.write_text_file(SAVE_PATH % slot, SaveUtils.to_json(collect()))
	if ok:
		var bus := SignalBus
		bus.toast_requested.emit(DataManager.tr_key("toast_saved"), "system")
	return ok


func load_from_slot(slot: int) -> Dictionary:
	if slot < 1 or slot > SLOT_COUNT:
		return {}
	return SaveUtils.from_json(SaveUtils.read_text_file(SAVE_PATH % slot))


func autosave() -> bool:
	return SaveUtils.write_text_file(AUTOSAVE_PATH, SaveUtils.to_json(collect()))


func load_autosave() -> Dictionary:
	return SaveUtils.from_json(SaveUtils.read_text_file(AUTOSAVE_PATH))


func slot_info(slot: int) -> Dictionary:
	var data: Dictionary = load_from_slot(slot)
	if data.is_empty():
		return {}
	return {
		"chapter": str(data.get("chapter", "?")),
		"location": str(data.get("location", "?")),
		"playtime": float(data.get("playtime", 0.0)),
		"timestamp": str(data.get("timestamp", "")),
		"clues": (data.get("clues_found", []) as Array).size(),
	}


func has_any_save() -> bool:
	if not SaveUtils.from_json(SaveUtils.read_text_file(AUTOSAVE_PATH)).is_empty():
		return true
	for i in range(1, SLOT_COUNT + 1):
		if not load_from_slot(i).is_empty():
			return true
	return false


func delete_slot(slot: int) -> void:
	var path: String = ProjectSettings.globalize_path(SAVE_PATH % slot)
	if FileAccess.file_exists(SAVE_PATH % slot):
		DirAccess.remove_absolute(path)
