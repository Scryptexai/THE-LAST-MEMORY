extends Node
## RelationshipManager — nilai hubungan Ardi dengan tiap karakter (0..maks).
## Pilihan dialog menambah/mengurangi; ambang tertentu membuka dialog spesial.

var values: Dictionary = {}  # char_id -> int


func _ready() -> void:
	reset_to_defaults()


## Isi nilai awal dari characters.json.
func reset_to_defaults() -> void:
	values.clear()
	var dm := DataManager
	for char_id in dm.characters.keys():
		values[char_id] = int((dm.characters[char_id] as Dictionary).get("relationship_start", 0))


func get_value(char_id: String) -> int:
	return int(values.get(char_id, 0))


func get_max(char_id: String) -> int:
	var dm := DataManager
	return int((dm.get_character(char_id) as Dictionary).get("relationship_max", 10))


## Tambah/kurangi hubungan (delta bisa negatif). Kembalikan nilai baru.
func add(char_id: String, delta: int, silent: bool = false) -> int:
	if delta == 0:
		return get_value(char_id)
	if char_id == "none" or char_id == "":
		return 0
	var res: Dictionary = RelationshipSystem.apply(values, char_id, delta, get_max(char_id))
	var bus := SignalBus
	bus.relationship_changed.emit(char_id, int(res["old"]), int(res["new"]))
	if not silent:
		var dm := DataManager
		var char_name: String = str((dm.get_character(char_id) as Dictionary).get("name", char_id))
		var arrow: String = "+" if delta > 0 else ""
		bus.toast_requested.emit("%s (%s%s)" % [char_name, arrow, str(delta)], "relationship_up" if delta > 0 else "relationship_down")
	return int(res["new"])


func meets(char_id: String, threshold: int) -> bool:
	return RelationshipSystem.meets(values, char_id, threshold)


func level_label(char_id: String) -> String:
	return RelationshipSystem.level_label(get_value(char_id), get_max(char_id))


func summary() -> Array:
	var dm := DataManager
	return RelationshipSystem.summary(values, dm.characters)
