class_name SaveUtils
extends RefCounted
## Serialisasi / deserialisasi JSON dan file save.


## Ubah Dictionary menjadi string JSON pretty.
static func to_json(data: Dictionary) -> String:
	return JSON.stringify(data, "\t")


## Parse string JSON menjadi Dictionary (kosong bila gagal).
static func from_json(text: String) -> Dictionary:
	if text == null or text.strip_edges().is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


## Baca seluruh isi file teks; "" bila gagal.
static func read_text_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		GameLog.warn("SaveUtils: file tidak ditemukan: %s" % path)
		return ""
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		GameLog.warn("SaveUtils: gagal membuka: %s" % path)
		return ""
	var content: String = f.get_as_text()
	f.close()
	return content


## Tulis string ke file (buat folder bila perlu). True bila sukses.
static func write_text_file(path: String, content: String) -> bool:
	var dir_path: String = path.get_base_dir()
	if dir_path != "" and dir_path != "res://" and not DirAccess.dir_exists_absolute(dir_path):
		# Untuk user://, pastikan folder ada.
		var err_make: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
		if err_make != OK:
			GameLog.warn("SaveUtils: gagal membuat folder: %s" % dir_path)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		GameLog.error("SaveUtils: gagal menulis: %s" % path)
		return false
	f.store_string(content)
	f.close()
	return true


## Deep-copy Dictionary/Array lewat JSON round-trip.
static func deep_copy(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))
