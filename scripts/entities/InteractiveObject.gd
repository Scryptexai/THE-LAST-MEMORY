extends StaticBody3D
## InteractiveObject — pintu, peti, surat, foto, portal lokasi, dsb.
## Dikonfigurasi dari data lokasi (scenes.json) atau langsung via setup().

@export var object_id: String = "obj"
@export var display_name: String = "Objek"
@export var prompt_key: String = "prompt_examine"  # prompt_talk/examine/travel/open/read/pickup
@export var dialogue_id: String = ""
@export var clue_id: String = ""
@export var item_id: String = ""
@export var required_item: String = ""       # item agar bisa dipakai
@export var required_flag: String = ""       # "flag=value" agar aktif
@export var consume_dialogue: String = ""    # dialog bila required belum terpenuhi
@export var target_location: String = ""     # bila ini portal
@export var target_spawn: String = "default"
@export var one_shot: bool = false           # hilang/nonaktif setelah dipakai
@export var memory_dialogue: String = ""     # dialog kilas balik (psychometry)
@export var gives_flag: String = ""          # "flag=value" setelah dipakai
@export var journal_text: String = ""
@export var moment_id: String = ""
var dialogue_variants: Dictionary = {}       # {flag: dialogue_id} varian dialog per flag

var _used: bool = false
var _marker: MeshInstance3D
var _t: float = 0.0
var _base_y: float = 0.0


func _ready() -> void:
	add_to_group("interactable")
	_base_y = position.y
	_build_marker()


func setup(cfg: Dictionary) -> void:
	for k in ["object_id", "display_name", "prompt_key", "dialogue_id", "clue_id",
			"item_id", "required_item", "required_flag", "consume_dialogue",
			"target_location", "target_spawn", "memory_dialogue", "gives_flag", "journal_text", "moment_id"]:
		if cfg.has(k):
			set(k, str(cfg[k]))
	one_shot = bool(cfg.get("one_shot", one_shot))
	dialogue_variants = cfg.get("variants", {})
	if _marker:
		_marker.visible = _is_active()


func _build_marker() -> void:
	# Penanda melayang (tanda seru kecil) agar objek penting terlihat.
	_marker = MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.16, 0.28, 0.16)
	_marker.mesh = prism
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.48, 0.03)
	mat.emission_enabled = true
	mat.emission = Color(0.85, 0.48, 0.03)
	mat.emission_energy_multiplier = 0.8
	_marker.material_override = mat
	_marker.position = Vector3(0, 1.9, 0)
	add_child(_marker)
	_marker.visible = _is_active()


func _process(delta: float) -> void:
	if _marker and _marker.visible:
		_t += delta
		_marker.position.y = 1.9 + sin(_t * 2.2) * 0.08
		_marker.rotation.y += delta * 1.5


func _is_active() -> bool:
	if _used and one_shot:
		return false
	if GameManager.hard_mode and target_location == "":
		return false  # Mode Detektif: hanya portal yang ditandai
	return true


func get_prompt() -> String:
	var dm := DataManager
	var key: String = prompt_key if prompt_key != "" else "prompt_examine"
	return dm.tr_key(key).format({"name": display_name})


func set_highlight(_on: bool) -> void:
	if _marker:
		_marker.scale = Vector3.ONE * (1.35 if _on else 1.0)


func interact(_from: Node = null) -> void:
	var gm := GameManager
	var dm := DataManager
	var im := InvestigationManager
	var bus := SignalBus
	if not gm.is_gameplay_input_active():
		return
	if _used and one_shot:
		return
	# 1) Cek syarat flag.
	if required_flag != "" and not _flag_satisfied(gm, required_flag):
		_fallback_dialogue("Butuh sesuatu yang lain terlebih dahulu.")
		return
	# 2) Cek item syarat.
	if required_item != "" and not im.has_item(required_item):
		var need_name: String = str((dm.get_item(required_item) as Dictionary).get("name", required_item))
		bus.toast_requested.emit(dm.tr_key("toast_need_item").format({"item": need_name}), "system")
		bus.sfx_requested.emit("sfx_deduction_wrong")
		_fallback_dialogue("")
		return
	# 3) Portal lokasi.
	if target_location != "":
		bus.sfx_requested.emit("sfx_door_open")
		var main := get_tree().current_scene
		if main and main.has_method("travel_to"):
			main.travel_to(target_location, target_spawn)
		return
	# 4) Konsumsi item syarat (mis. kunci) bila sekali pakai? Kunci tidak habis; hadiah habis.
	# 5) Beri clue / item.
	if clue_id != "":
		im.add_clue(clue_id)
	if item_id != "":
		im.add_item(item_id)
	if gives_flag != "":
		_apply_gives_flag(gm, gives_flag)
	if journal_text != "":
		im.add_journal_note("obj:" + object_id, journal_text, dm.tr_key("journal_src_world"))
	if moment_id != "":
		im.capture_moment(moment_id)
	# 6) Dialog (memori lebih dulu bila ada; lalu dialog biasa).
	if memory_dialogue != "" and dm.has_dialogue(memory_dialogue):
		bus.sfx_requested.emit("sfx_memory")
		DialogueManager.start_dialogue(memory_dialogue)
		_mark_used()
		return
	if dialogue_id != "" and dm.has_dialogue(dialogue_id):
		DialogueManager.start_dialogue(dialogue_id)
	elif clue_id == "" and item_id == "":
		bus.toast_requested.emit(display_name, "system")
	_mark_used()


func _flag_satisfied(gm: Node, req: String) -> bool:
	# Format "flag" (truthy) atau "flag=value".
	if "=" in req:
		var parts: PackedStringArray = req.split("=", true, 1)
		return str(gm.get_flag(parts[0].strip_edges(), "")) == parts[1].strip_edges()
	return bool(gm.get_flag(req.strip_edges(), false))


func _apply_gives_flag(gm: Node, spec: String) -> void:
	if "=" in spec:
		var parts: PackedStringArray = spec.split("=", true, 1)
		var v: String = parts[1].strip_edges()
		if v == "true":
			gm.set_flag(parts[0].strip_edges(), true)
		elif v == "false":
			gm.set_flag(parts[0].strip_edges(), false)
		elif v.is_valid_int():
			gm.set_flag(parts[0].strip_edges(), int(v))
		else:
			gm.set_flag(parts[0].strip_edges(), v)
	else:
		gm.set_flag(spec.strip_edges(), true)


## Pilih varian dialog: flag pertama yang bernilai true menang.
func _resolve_dialogue(gm: Node) -> String:
	for k in dialogue_variants.keys():
		if bool(gm.get_flag(str(k), false)):
			return str(dialogue_variants[k])
	return dialogue_id


func _fallback_dialogue(toast_text: String) -> void:
	var bus := SignalBus
	if consume_dialogue != "" and DataManager.has_dialogue(consume_dialogue):
		DialogueManager.start_dialogue(consume_dialogue)
	elif toast_text != "":
		bus.toast_requested.emit(toast_text, "system")


func _mark_used() -> void:
	if one_shot:
		_used = true
		if _marker:
			_marker.visible = false
