extends Node
## Main — orkestrasi scene: menu -> loading -> lokasi -> dialog -> ending.
## Memuat lokasi secara dinamis agar Player & UI tetap persisten.

var in_game: bool = false

var _location_container: Node3D
var _current_location: Node3D = null


func _ready() -> void:
	_location_container = $World/LocationContainer
	var bus := SignalBus
	bus.ending_triggered.connect(_on_ending_triggered)
	# Musik menu + pastikan mouse terlihat.
	AudioManager.play_music("music_main_menu")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# ---------- Alur utama ----------

func start_new_game() -> void:
	GameManager.new_game()
	in_game = true
	await travel_to("rumah_nenek", "intro")
	# Dialog pembuka setelah tiba.
	await get_tree().process_frame
	DialogueManager.start_dialogue("dlg_intro_01")


func continue_game(data: Dictionary) -> void:
	if data.is_empty():
		SignalBus.toast_requested.emit(
			DataManager.tr_key("toast_no_save"), "system")
		return
	if not GameManager.continue_from_data(data):
		return
	in_game = true
	var gm := GameManager
	await travel_to(gm.current_location, gm.last_spawn_tag)


func quit_to_menu() -> void:
	_clear_location()
	in_game = false
	GameManager.quit_to_menu()
	AudioManager.play_music("music_main_menu")


## Pindah lokasi dengan layar loading berprogres.
func travel_to(location_id: String, spawn_tag: String = "default") -> void:
	if location_id == "__travel__":
		var ui := $UI as CanvasLayer
		if ui.has_method("get_screen"):
			var hud := (ui as Node).call("get_screen", "hud")
			if hud and hud.has_method("toggle_travel"):
				hud.toggle_travel()
		return
	var dm := DataManager
	var gm := GameManager
	var bus := SignalBus
	if (dm.get_scene_data(location_id) as Dictionary).is_empty():
		Logger.warn("Main: lokasi tak dikenal: %s" % location_id)
		return
	gm.last_spawn_tag = spawn_tag
	gm.change_state("loading")
	bus.loading_progress.emit(0.1, dm.tr_key("loading_travel"))
	await get_tree().process_frame
	_clear_location()
	bus.loading_progress.emit(0.35, dm.tr_key("loading_build"))
	await get_tree().process_frame
	var packed: PackedScene = load(str((dm.get_scene_data(location_id) as Dictionary).get("scene_path", "")))
	if packed == null:
		Logger.error("Main: gagal memuat scene lokasi: %s" % location_id)
		gm.change_state("gameplay")
		return
	_current_location = packed.instantiate() as Node3D
	_location_container.add_child(_current_location)
	bus.loading_progress.emit(0.7, dm.tr_key("loading_ready"))
	await get_tree().process_frame
	await get_tree().process_frame
	# Masuk & serahkan ke gameplay.
	if _current_location.has_method("enter"):
		_current_location.enter(spawn_tag)
	gm.last_spawn_tag = spawn_tag
	bus.loading_progress.emit(1.0, dm.tr_key("loading_ready"))
	await get_tree().create_timer(0.25).timeout
	if gm.state == "loading":
		gm.change_state("gameplay")
	# Pastikan Player terlihat & kamera aktif.
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		var cam := player.get_node_or_null("CamPivot/SpringArm3D/Camera3D") as Camera3D
		if cam:
			cam.current = true


func _clear_location() -> void:
	if _current_location and is_instance_valid(_current_location):
		_location_container.remove_child(_current_location)
		_current_location.queue_free()
	_current_location = null
	for c in _location_container.get_children():
		c.queue_free()


func _on_ending_triggered(_ending_id: String) -> void:
	in_game = true  # tetap di dunia; EndingUI menutupi layar
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
