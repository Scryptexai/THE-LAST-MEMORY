extends Node
## AchievementManager — pelacakan & notifikasi pencapaian (autoload).
## Kondisi dievaluasi idempoten lewat evaluate() dari berbagai hook progres.

var unlocked: Array = []  # Array[String]


func reset() -> void:
	unlocked.clear()


func is_unlocked(ach_id: String) -> bool:
	return ach_id in unlocked


## Buka pencapaian: toast + fanfare + catatan jurnal. Idempoten.
func unlock(ach_id: String) -> bool:
	if ach_id in unlocked:
		return false
	var dm := DataManager
	var a: Dictionary = dm.get_achievement(ach_id)
	if a.is_empty():
		return false
	unlocked.append(ach_id)
	SaveManager.record_global("achievements", ach_id)
	var nm: String = str(a.get("name_en", "")) if dm.language == "en" and str(a.get("name_en", "")) != "" else str(a.get("name", ach_id))
	SignalBus.sfx_requested.emit("sfx_achievement")
	SignalBus.toast_requested.emit("🏆 " + nm, "achievement")
	InvestigationManager.add_journal_note("ach:" + ach_id, "Pencapaian: " + str(a.get("name", ach_id)), dm.tr_key("journal_src_story"))
	Logger.info("AchievementManager: terbuka %s" % ach_id)
	return true


## Nilai semua kondisi dari status manajer lain. Aman dipanggil kapan saja.
func evaluate() -> void:
	var im := InvestigationManager
	var gm := GameManager
	var dm := DataManager
	var prog: Dictionary = im.clue_progress()
	if int(prog.get("found", 0)) >= 1:
		unlock("ach_first_clue")
	if int(prog.get("total", 0)) > 0 and int(prog.get("found", 0)) >= int(prog.get("total", 0)):
		unlock("ach_eagle")
	var nd: int = (im.deductions_solved as Array).size()
	if nd >= 1:
		unlock("ach_first_ded")
	if nd >= 4:
		unlock("ach_detective")
		if im.hints_left >= 3:
			unlock("ach_no_help")
	var nm: int = (im.moments_taken as Array).size()
	if nm >= 1:
		unlock("ach_first_shot")
	if dm.moments.size() > 0 and nm >= dm.moments.size():
		unlock("ach_collector")
	var ne: int = (gm.endings_seen as Array).size()
	if ne >= 1:
		unlock("ach_one_ending")
	if ne >= 4:
		unlock("ach_all_endings")
	if (gm.visited_locations as Array).size() >= 5:
		unlock("ach_explorer")
	if bool(gm.get_flag("ng_plus", false)):
		unlock("ach_ngplus")
	if gm.hard_mode and ne >= 1:
		unlock("ach_hardboiled")
	var ng: int = 0
	for k in (gm.flags as Dictionary).keys():
		if str(k).begins_with("gift_") and bool((gm.flags as Dictionary)[k]):
			ng += 1
	if ng >= 5:
		unlock("ach_generous")
	if GameManager.completion_percent() >= 100:
		unlock("ach_completionist")
