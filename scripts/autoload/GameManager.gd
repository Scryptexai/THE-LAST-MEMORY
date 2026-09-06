extends Node
## GameManager — state machine global, progres chapter, flags cerita,
## objektif, evaluasi ending, dan orkestrasi pindah lokasi.

const STATES := ["main_menu", "loading", "gameplay", "dialogue", "investigation",
	"inventory", "journal", "settings", "pause", "photo", "ending"]

var state: String = "main_menu"
var previous_gameplay_state: String = "gameplay"
var current_chapter: String = "prolog"
var current_location: String = "rumah_nenek"
var last_spawn_tag: String = "default"
var current_objective: String = "obj_datang"
var flags: Dictionary = {}
var final_choice: String = ""
var endings_seen: Array = []
var visited_locations: Array = []  # Array[String] lokasi pernah dikunjungi
var new_game_plus: bool = false
var hard_mode: bool = false  # Mode Detektif: tanpa hint, tanpa penanda objek, tanpa pratinjau relasi
var pre_ending_snapshot: Dictionary = {}
var text_speed: float = 1.0
var ui_scale: float = 1.0             # aksesibilitas: skala seluruh UI (0.85–1.4)
var high_contrast: bool = false       # aksesibilitas: kotak dialog & teks kontras tinggi
var reduce_motion: bool = false       # aksesibilitas: tanpa goyangan kamera/kilas sinematik


func set_ui_scale(v: float) -> void:
	ui_scale = clampf(v, 0.85, 1.4)
	var win := get_window()
	if win:
		win.content_scale_factor = ui_scale
	SignalBus.accessibility_changed.emit()


func set_high_contrast(on: bool) -> void:
	high_contrast = on
	SignalBus.accessibility_changed.emit()


func set_reduce_motion(on: bool) -> void:
	reduce_motion = on
	SignalBus.accessibility_changed.emit()
var cam_sensitivity: float = 1.0
var auto_advance: bool = false  # dialog linear lanjut otomatis setelah selesai diketik
var _ending_token: int = 0


func _ready() -> void:
	_ensure_input_actions()
	change_state("main_menu")


## Jaring pengaman: pastikan aksi input ada walau project.godot berubah.
func _ensure_input_actions() -> void:
	_add_key_action("move_forward", [KEY_W, KEY_UP])
	_add_key_action("move_back", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("run", [KEY_SHIFT])
	_add_key_action("interact", [KEY_E])
	_add_key_action("open_journal", [KEY_J, KEY_TAB])
	_add_key_action("open_inventory", [KEY_I])
	_add_key_action("open_investigation", [KEY_L])
	_add_key_action("open_map", [KEY_M])


func _add_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var exists: bool = false
		for e in InputMap.action_get_events(action):
			if e is InputEventKey and (e as InputEventKey).physical_keycode == k:
				exists = true
				break
		if not exists:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)


# ---------- State ----------

func change_state(new_state: String) -> void:
	if not (new_state in STATES):
		Logger.warn("GameManager: state tak dikenal: %s" % new_state)
		return
	if state == new_state:
		return
	if state == "gameplay" and new_state != "gameplay":
		previous_gameplay_state = state
	state = new_state
	Logger.debug("GameManager: state -> %s" % state)
	# Kontrol mouse per state.
	if state == "gameplay":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	SignalBus.game_state_changed.emit(state)


func is_gameplay_input_active() -> bool:
	return state == "gameplay"


func toggle_pause() -> void:
	if state == "gameplay":
		change_state("pause")
	elif state == "pause":
		change_state("gameplay")


# ---------- Flags / chapter / objektif ----------

func set_flag(flag_name: String, value: Variant) -> void:
	var was: Variant = flags.get(flag_name, null)
	flags[flag_name] = value
	SignalBus.flag_changed.emit(flag_name, value)
	if bool(value) and not bool(was):
		_announce_quest_flag(flag_name)


## Toast saat flag memulai/menyelesaikan tugas sampingan (quests.json).
func _announce_quest_flag(flag_name: String) -> void:
	var dm := DataManager
	for q in dm.quests:
		var qd: Dictionary = q
		var qname: String = str(qd.get("name_en", qd.get("name", ""))) if dm.language == "en" else str(qd.get("name", ""))
		if str(qd.get("done_flag", "")) == flag_name:
			SignalBus.toast_requested.emit(dm.tr_key("toast_quest_done").format({"name": qname}), "achievement")
		elif str(qd.get("start_flag", "")) == flag_name and str(qd.get("start_flag", "")).begins_with("quest_"):
			SignalBus.toast_requested.emit(dm.tr_key("toast_quest_start").format({"name": qname}), "system")


func get_flag(flag_name: String, default: Variant = null) -> Variant:
	return flags.get(flag_name, default)


func set_chapter(chapter_id: String) -> void:
	if chapter_id == "" or chapter_id == current_chapter:
		return
	current_chapter = chapter_id
	flags["chseen_" + chapter_id] = true
	SignalBus.chapter_changed.emit(chapter_id)
	Logger.info("GameManager: chapter -> %s" % chapter_id)
	_announce_unlocked_locations(chapter_id)


## Status tugas sampingan: "hidden" | "active" | "done" (+ progres langkah).
func quest_status(q: Dictionary) -> Dictionary:
	var im := InvestigationManager
	var start_flag: String = str(q.get("start_flag", ""))
	var done_flag: String = str(q.get("done_flag", ""))
	var steps: Array = q.get("steps", [])
	var out: Dictionary = {"state": "hidden", "step_done": 0, "step_total": steps.size(), "count": -1, "count_total": -1}
	if start_flag != "" and not bool(get_flag(start_flag, false)):
		return out
	out["state"] = "active"
	if str(q.get("count", "")) == "moments":
		out["count"] = (im.moments_taken as Array).size()
		out["count_total"] = DataManager.moments.size()
		if int(out["count_total"]) > 0 and int(out["count"]) >= int(out["count_total"]):
			out["state"] = "done"
	var n: int = 0
	for s in steps:
		var f: String = str((s as Dictionary).get("flag", ""))
		if f != "" and bool(get_flag(f, false)):
			n += 1
	out["step_done"] = n
	if done_flag != "" and bool(get_flag(done_flag, false)):
		out["state"] = "done"
		out["step_done"] = steps.size()
	return out


## Toast bila bab ini membuka lokasi baru (scenes.json "unlock_flag").
func _announce_unlocked_locations(chapter_id: String) -> void:
	var dm := DataManager
	for sid in dm.scenes.keys():
		var sdata: Dictionary = dm.scenes[sid]
		if str(sdata.get("unlock_flag", "")) == "chseen_" + chapter_id:
			SignalBus.toast_requested.emit(dm.tr_key("toast_location_unlocked").format({"name": str(sdata.get("name", sid))}), "system")


## Tandai semua bab s/d bab saat ini (untuk save lama yg belum punya flag chseen_*).
func _backfill_chseen() -> void:
	var order: Array = ["prolog", "bab1", "bab2", "bab3", "bab4", "final"]
	var idx: int = order.find(current_chapter)
	if idx < 0:
		idx = 0
	for i in range(idx + 1):
		flags["chseen_" + str(order[i])] = true


## Persentase penyelesaian: petunjuk 30 + deduksi 20 + ending 20 + momen 20 + relasi 10.
func completion_percent() -> int:
	var im := InvestigationManager
	var dm := DataManager
	var rm := RelationshipManager
	var prog: Dictionary = im.clue_progress()
	var score: float = 0.0
	if int(prog.get("total", 0)) > 0:
		score += 30.0 * float(prog.get("found", 0)) / float(prog.get("total", 1))
	score += 20.0 * float((im.deductions_solved as Array).size()) / 4.0
	score += 20.0 * float((endings_seen as Array).size()) / 4.0
	if dm.moments.size() > 0:
		score += 20.0 * float((im.moments_taken as Array).size()) / float(dm.moments.size())
	var rel: float = 0.0
	for c in ["rara", "pak_harto", "mira"]:
		var mx: int = rm.get_max(c)
		if mx > 0:
			rel += float(rm.get_value(c)) / float(mx)
	score += 10.0 * rel / 3.0
	return int(roundf(score))


func set_objective(objective_id: String) -> void:
	if objective_id == "":
		return
	current_objective = objective_id
	var text: String = DataManager.get_objective(objective_id)
	SignalBus.objective_changed.emit(text)


func objective_text() -> String:
	return DataManager.get_objective(current_objective)


# ---------- Efek generik (dipakai dialog & deduksi) ----------

## Terapkan Dictionary efek ke seluruh manager.
func apply_effects(effects: Dictionary) -> void:
	if effects.is_empty():
		return
	var im := InvestigationManager
	var rm := RelationshipManager
	var bus := SignalBus
	for k in (effects.get("flags", {}) as Dictionary).keys():
		set_flag(str(k), (effects["flags"] as Dictionary)[k])
	for c in effects.get("add_clues", []):
		im.add_clue(str(c))
	for it in effects.get("add_items", []):
		im.add_item(str(it))
	for it in effects.get("remove_items", []):
		im.remove_item(str(it))
	for k in (effects.get("relationship", {}) as Dictionary).keys():
		rm.add(str(k), int((effects["relationship"] as Dictionary)[k]))
	var journal_text: String = str(effects.get("journal", ""))
	if journal_text != "":
		var dm := DataManager
		im.add_journal_note("fx:%s:%d" % [current_chapter, randi()], journal_text, dm.tr_key("journal_src_story"))
	var tl: Dictionary = effects.get("timeline", {})
	if not tl.is_empty():
		im.add_timeline_event(str(tl.get("id", "ev%d" % randi())), str(tl.get("year", "?")), str(tl.get("text", "")))
	var chapter: String = str(effects.get("chapter", ""))
	if chapter != "":
		set_chapter(chapter)
	var objective: String = str(effects.get("objective", ""))
	if objective != "":
		set_objective(objective)
	var ending_choice: String = str(effects.get("ending_choice", ""))
	if ending_choice != "":
		register_final_choice(ending_choice)
	var move_to: String = str(effects.get("move_to", ""))
	if move_to != "":
		call_deferred("_deferred_move", move_to, str(effects.get("spawn_tag", "default")))
	var sfx: String = str(effects.get("sfx", ""))
	if sfx != "":
		bus.sfx_requested.emit(sfx)


func _deferred_move(location_id: String, spawn_tag: String) -> void:
	var main := get_tree().current_scene
	if main and main.has_method("travel_to"):
		main.travel_to(location_id, spawn_tag)


# ---------- Alur game baru / lanjut ----------

func new_game(plus: bool = false, hard: bool = false) -> void:
	_ending_token += 1
	hard_mode = hard
	if DialogueManager.is_active():
		DialogueManager.cancel()
	var kept_moments: Array = []
	if plus:
		kept_moments = InvestigationManager.moments_taken.duplicate(true)
	flags.clear()
	visited_locations.clear()
	AchievementManager.reset()
	final_choice = ""
	current_chapter = "prolog"
	current_location = "rumah_nenek"
	last_spawn_tag = "intro"
	current_objective = "obj_datang"
	RelationshipManager.reset_to_defaults()
	InvestigationManager.reset()
	DialogueManager.reset_for_new_game()
	SaveManager.reset_playtime()
	SaveManager.start_tracking()
	var im := InvestigationManager
	new_game_plus = plus
	if plus:
		im.moments_taken = kept_moments
		im.hints_left = 5
		set_flag("ng_plus", true)
		im.add_item("kelereng_kaca")  # kenang-kenangan dari perjalanan sebelumnya
		im.add_journal_note("ngplus", "Perjalanan Baru+: foto kenangan dan pengalaman terbawa.", DataManager.tr_key("journal_src_story"))
	if hard:
		im.hints_left = 0
		set_flag("hard_mode", true)
		im.add_journal_note("hardmode", "Mode Detektif: tanpa hint, tanpa penanda objek. Hanya insting.", DataManager.tr_key("journal_src_story"))
	set_flag("chseen_prolog", true)
	im.add_timeline_event("ev_now", "2026", "Ardi kembali ke Kota Tua Pesisir.")
	im.mark_character_met("ardi")
	AchievementManager.evaluate()
	SaveManager.record_global_stat("runs", 1.0)
	Logger.info("GameManager: permainan baru dimulai.")


func continue_from_data(data: Dictionary) -> bool:
	_ending_token += 1
	if DialogueManager.is_active():
		DialogueManager.cancel()
	if data.is_empty():
		return false
	if not SaveManager.apply(data):
		return false
	_backfill_chseen()
	SaveManager.start_tracking()
	return true


func quit_to_menu() -> void:
	_ending_token += 1
	if DialogueManager.is_active():
		DialogueManager.cancel()
	SaveManager.stop_tracking()
	AudioManager.stop_music()
	AudioManager.stop_ambient()
	change_state("main_menu")


# ---------- Lokasi & audio ----------

func notify_location_loaded(location_id: String) -> void:
	current_location = location_id
	if location_id != "" and not (location_id in visited_locations):
		visited_locations.append(location_id)
	SignalBus.location_changed.emit(location_id)
	restore_location_audio()
	AchievementManager.evaluate()
	SaveManager.autosave()


func restore_location_audio() -> void:
	var dm := DataManager
	var bus := SignalBus
	var data: Dictionary = dm.get_scene_data(current_location)
	if data.is_empty():
		return
	bus.music_requested.emit(str(data.get("music", "")))
	bus.ambient_requested.emit(str(data.get("ambient", "")))


# ---------- Ending ----------

## Kembali ke sesaat sebelum pilihan akhir (tombol "Jelajahi Lagi").
func restore_pre_ending() -> void:
	if pre_ending_snapshot.is_empty():
		return
	final_choice = ""
	var seen_keep: Array = endings_seen.duplicate(true)
	SaveManager.apply(pre_ending_snapshot)
	for e in seen_keep:
		if not (str(e) in endings_seen):
			endings_seen.append(str(e))
	SaveManager.start_tracking()
	pre_ending_snapshot = {}
	call_deferred("_deferred_move", current_location, last_spawn_tag)
	change_state("loading")


func register_final_choice(choice_id: String) -> void:
	if pre_ending_snapshot.is_empty():
		pre_ending_snapshot = SaveManager.collect()
		pre_ending_snapshot["final_choice"] = ""
	_ending_token += 1
	final_choice = choice_id
	Logger.info("GameManager: pilihan akhir = %s" % choice_id)
	# Tunda evaluasi hingga dialog selesai (dijaga token agar tak basi).
	call_deferred("_deferred_ending", _ending_token)


func _deferred_ending(token: int) -> void:
	if token != _ending_token:
		return  # permainan diulang/di-load; abaikan ending basi
	var dlgm := DialogueManager
	if dlgm.is_active():
		await SignalBus.dialogue_finished
		if token != _ending_token:
			return
	await get_tree().process_frame
	if token != _ending_token:
		return
	trigger_ending(evaluate_ending())


## Tentukan ending dari clue, deduksi, hubungan, dan pilihan akhir.
func evaluate_ending() -> String:
	var im := InvestigationManager
	var rm := RelationshipManager
	var clues_n: int = (im.clues_found as Array).size()
	var ded_n: int = (im.deductions_solved as Array).size()
	var total_clues: int = DataManager.clues.size()
	match final_choice:
		"bungkam":
			return "ending_rahasiaterkubur"
		"sebagian":
			if clues_n >= 10:
				return "ending_pengorbanan"
			return "ending_lukalama"
		"ungkap":
			var rel_ok: bool = rm.get_value("rara") >= 14 and rm.get_value("pak_harto") >= 9 and rm.get_value("mira") >= 7
			var all_ded: bool = ded_n >= 4
			var all_clues: bool = clues_n >= total_clues
			if rel_ok and all_ded and all_clues:
				return "ending_kebenaranutuh"
			if ded_n >= 3 and clues_n >= 12:
				# Jujur tapi ada yang retak — tetap pahit-manis.
				if rm.get_value("rara") < 8 or rm.get_value("pak_harto") < 5:
					return "ending_lukalama"
				return "ending_pengorbanan"
			return "ending_lukalama"
	return "ending_lukalama"


func trigger_ending(ending_id: String) -> void:
	if not (ending_id in endings_seen):
		endings_seen.append(ending_id)
	for e in endings_seen:
		SaveManager.record_global("endings", str(e))
	SaveManager.record_global_stat("endings_reached", 1.0)
	SaveManager.record_global_stat("best_completion", float(completion_percent()), "max")
	SaveManager.record_global_stat("fastest_ending", SaveManager.playtime, "min")
	AchievementManager.evaluate()
	change_state("ending")
	SignalBus.ending_triggered.emit(ending_id)
	SaveManager.autosave()
	Logger.info("GameManager: ENDING -> %s" % ending_id)
