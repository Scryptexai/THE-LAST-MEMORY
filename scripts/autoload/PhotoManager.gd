extends Node
## PhotoManager — mode foto bebas: tangkap layar & kelola galeri user://photos.
## Autoload; tidak terikat save slot (foto milik pemain, bukan progres).

const PHOTO_DIR := "user://photos"
const MAX_THUMBS := 24

var photos: Array = []  # Array[String] nama file, terbaru dulu
var capturing: bool = false


func _ready() -> void:
	rescan()


## Pindai ulang direktori foto (terbaru dulu).
func rescan() -> void:
	photos.clear()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PHOTO_DIR))
	for f in DirAccess.get_files_at(PHOTO_DIR):
		if f.to_lower().ends_with(".png"):
			photos.append(f)
	photos.sort()
	photos.reverse()


func photo_count() -> int:
	return photos.size()


func photo_path(filename: String) -> String:
	return PHOTO_DIR + "/" + filename


## Jepret layar (UI disembunyikan sesaat) lalu simpan PNG berstempel waktu.
func capture() -> void:
	if capturing:
		return
	capturing = true
	var bus := SignalBus
	var ui := get_tree().get_first_node_in_group("ui_layer") as CanvasLayer
	if ui:
		ui.hide()
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if ui and is_instance_valid(ui):
		ui.show()
	if img == null or img.is_empty():
		Logger.warn("PhotoManager: tangkapan layar gagal.")
		capturing = false
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PHOTO_DIR))
	var stamp := Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace(" ", "_")
	var fname := "foto_" + stamp + ".png"
	if img.save_png(PHOTO_DIR + "/" + fname) != OK:
		Logger.warn("PhotoManager: gagal menyimpan foto.")
		capturing = false
		return
	photos.push_front(fname)
	bus.sfx_requested.emit("sfx_shutter")
	bus.toast_requested.emit(DataManager.tr_key("photo_saved"), "item")
	AchievementManager.unlock("ach_photographer")
	Logger.info("PhotoManager: tersimpan %s" % fname)
	capturing = false
