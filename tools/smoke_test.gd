extends SceneTree
## Uji asap headless: jalankan game sungguhan tanpa layar, lalu:
## 1) mulai game baru, 2) kunjungi SEMUA lokasi, 3) berinteraksi dengan setiap NPC
## & objek di tiap lokasi, 4) mainkan SEMUA dialog (pilihan pertama yang tersedia),
## 5) buka semua layar UI, 6) picu 1 ending. Keluar dengan kode 1 bila ada error.
##
## Pakai:  godot --headless --path . -s res://tools/smoke_test.gd
## (butuh .godot/global_script_class_cache.cfg — lihat tools/godot_check.sh)

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAX_STEPS_PER_DIALOGUE := 60

var _fail: int = 0
# Autoload diambil lewat root karena skrip -s dikompilasi sebelum global autoload terdaftar.
var GameManager: Node
var DataManager: Node
var DialogueManager: Node
var InvestigationManager: Node
var SaveManager: Node


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	GameManager = root.get_node("GameManager")
	DataManager = root.get_node("DataManager")
	DialogueManager = root.get_node("DialogueManager")
	InvestigationManager = root.get_node("InvestigationManager")
	SaveManager = root.get_node("SaveManager")
	# Muat scene utama (autoload sudah dibuat engine dari project.godot).
	var packed: PackedScene = load(MAIN_SCENE)
	if packed == null:
		_err("gagal memuat Main.tscn")
		_finish()
		return
	var main: Node = packed.instantiate()
	root.add_child(main)
	await _frames(3)
	_ok("Main.tscn + UI (%d layar) dimuat" % (main.get_node("UI") as Node).get_child_count())

	# --- 1) Game baru ---
	await main.start_new_game(false, false)
	await _frames(3)
	_check(GameManager.state == "dialogue", "game baru → dialog pembuka aktif (state=%s)" % GameManager.state)
	await _play_out_dialogue()
	_check(GameManager.state == "gameplay", "setelah intro state=gameplay (%s)" % GameManager.state)

	# --- 2) Kunjungi semua lokasi + interaksi semua entitas ---
	var visited: int = 0
	for sid in DataManager.scenes.keys():
		await main.travel_to(str(sid), "default")
		await _frames(4)
		var loc: Node = main.get_node("World/LocationContainer").get_child(0) if main.get_node("World/LocationContainer").get_child_count() > 0 else null
		_check(loc != null, "lokasi %s terbangun" % sid)
		if loc == null:
			continue
		visited += 1
		GameManager.notify_location_loaded(str(sid))
		var n_int: int = 0
		for node in get_nodes_in_group("interactable"):
			if not is_instance_valid(node) or not node.has_method("interact"):
				continue
			if node.has_method("get_prompt"):
				var _p = node.get_prompt()
			node.interact()
			n_int += 1
			await _frames(2)
			if DialogueManager.is_active():
				await _play_out_dialogue()
			# Tutup layar apa pun yang terbuka oleh interaksi.
			if GameManager.state != "gameplay":
				GameManager.change_state("gameplay")
			await _frames(1)
		_ok("  %s: %d interaksi" % [sid, n_int])
	_check(visited == DataManager.scenes.size(), "semua %d lokasi dikunjungi (%d)" % [DataManager.scenes.size(), visited])

	# --- 3) Semua dialog ---
	var played: int = 0
	var ids: Array = DataManager.dialogues.keys()
	ids.sort()
	for did in ids:
		if DialogueManager.start_dialogue(str(did)):
			await _play_out_dialogue()
			played += 1
		if GameManager.state == "ending":
			GameManager.restore_pre_ending()
			GameManager.change_state("gameplay")
		if GameManager.state != "gameplay":
			GameManager.change_state("gameplay")
	_ok("%d/%d dialog dimainkan" % [played, ids.size()])

	# --- 4) Semua layar UI ---
	var ui: Node = main.get_node("UI")
	for st in ["investigation", "inventory", "journal", "photo", "settings", "pause", "gameplay"]:
		GameManager.change_state(st)
		await _frames(2)
	for scr in ["investigation", "inventory", "journal", "main_menu"]:
		var s: Node = ui.call("get_screen", scr)
		if s and s.has_method("refresh"):
			s.call("refresh")
	var hud: Node = ui.call("get_screen", "hud")
	if hud:
		hud.call("show_recap")
		hud.call("toggle_travel")
		hud.call("toggle_travel")
		hud.call("show_toast", "uji", "clue")
	await _frames(2)
	_ok("semua layar UI dibuka & di-refresh")

	# --- 5) Sistem investigasi ---
	for cid in DataManager.clues.keys():
		InvestigationManager.add_clue(str(cid))
	for did in DataManager.deductions.keys():
		var d: Dictionary = DataManager.get_deduction(str(did))
		InvestigationManager.try_deduction(d.get("required_clues", []))
	for iid in DataManager.items.keys():
		InvestigationManager.add_item(str(iid))
	for mid in DataManager.moments.keys():
		InvestigationManager.capture_moment(str(mid))
	InvestigationManager.use_hint()
	_check(InvestigationManager.deductions_solved.size() == DataManager.deductions.size(), "%d clue, %d/%d deduksi, %d item" % [InvestigationManager.clues_found.size(), InvestigationManager.deductions_solved.size(), DataManager.deductions.size(), DataManager.items.size()])

	# --- 6) Simpan/muat + ekspor jurnal ---
	SaveManager.save_to_slot(1)
	var data: Dictionary = SaveManager.load_from_slot(1)
	_check(not data.is_empty(), "save/load slot 1")
	var jp: String = (load("res://scripts/utils/JournalExporter.gd") as GDScript).call("export_markdown")
	_check(jp != "", "ekspor jurnal → %s" % jp)
	await _frames(1)

	# --- 7) Ending ---
	var eid: String = GameManager.evaluate_ending()
	GameManager.trigger_ending(eid)
	await _frames(6)
	_check(GameManager.state == "ending", "ending '%s' tampil (state=%s)" % [eid, GameManager.state])
	await _frames(2)
	main.quit_to_menu()
	await _frames(2)
	_check(GameManager.state == "main_menu", "kembali ke menu utama")

	# --- 8) Semua ending + lanjutkan dari save + Baru+ / mode sulit ---
	for e in DataManager.endings.keys():
		await main.start_new_game(false, false)
		await _play_out_dialogue()
		GameManager.trigger_ending(str(e))
		await _frames(6)
		_check(GameManager.state == "ending", "ending %s" % e)
		main.quit_to_menu()
		await _frames(2)
	await main.continue_game(SaveManager.load_from_slot(1))
	await _frames(4)
	_check(GameManager.state == "gameplay", "lanjutkan dari slot 1 (state=%s, lokasi=%s)" % [GameManager.state, GameManager.current_location])
	main.quit_to_menu()
	await _frames(2)
	await main.start_new_game(true, true)
	await _play_out_dialogue()
	_check(GameManager.new_game_plus and GameManager.hard_mode, "Baru+ & mode sulit")
	main.quit_to_menu()
	await _frames(2)
	_finish()


func _play_out_dialogue() -> void:
	var steps: int = 0
	while DialogueManager.is_active() and steps < MAX_STEPS_PER_DIALOGUE:
		steps += 1
		var choices: Array = DialogueManager.current_node.get("choices", [])
		if choices.is_empty():
			DialogueManager.advance()
		else:
			var picked: bool = false
			for i in range(choices.size()):
				if DialogueManager.choose(i):
					picked = true
					break
			if not picked:
				DialogueManager.finish()
		await _frames(1)
	if steps >= MAX_STEPS_PER_DIALOGUE:
		_err("dialog %s tidak selesai dalam %d langkah" % [DialogueManager.dialogue_id, MAX_STEPS_PER_DIALOGUE])
		DialogueManager.finish()


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _check(cond: bool, msg: String) -> void:
	if cond:
		_ok(msg)
	else:
		_err(msg)


func _ok(msg: String) -> void:
	print("  ✔ " + msg)


func _err(msg: String) -> void:
	_fail += 1
	printerr("  ✘ " + msg)


func _finish() -> void:
	print("SMOKE TEST: %s (%d gagal)" % ["PASS" if _fail == 0 else "FAIL", _fail])
	quit(1 if _fail > 0 else 0)
