class_name Hotspot2D
extends Node2D
## Hotspot2D — objek interaktif di latar lukisan (pintu, laci, foto, dsb).
## Logika interaksi (clue/item/flag/dialog/portal) sama persis dengan
## InteractiveObject 3D; di sini hanya presentasinya: penanda berdenyut yang
## menyala saat disorot, ikon sesuai jenis prompt, dan area klik.

var object_id: String = "obj"
var display_name: String = "Objek"
var prompt_key: String = "prompt_examine"
var dialogue_id: String = ""
var clue_id: String = ""
var item_id: String = ""
var required_item: String = ""
var required_flag: String = ""
var consume_dialogue: String = ""
var target_location: String = ""
var target_spawn: String = "default"
var one_shot: bool = false
var memory_dialogue: String = ""
var gives_flag: String = ""
var journal_text: String = ""
var moment_id: String = ""
var dialogue_variants: Dictionary = {}

## Titik berdiri Ardi (ruang panggung) dan area hover.
var stand: Vector2 = Vector2.ZERO
var area: Rect2 = Rect2(-40, -40, 80, 80)

var _used: bool = false
var _hover: bool = false
var _t: float = 0.0
var _seed: float = 0.0


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("hotspot")
	_seed = randf() * TAU
	z_index = 3500  # penanda selalu di atas tokoh


func setup(cfg: Dictionary) -> void:
	for k in ["object_id", "display_name", "prompt_key", "dialogue_id", "clue_id",
			"item_id", "required_item", "required_flag", "consume_dialogue",
			"target_location", "target_spawn", "memory_dialogue", "gives_flag", "journal_text", "moment_id"]:
		if cfg.has(k):
			set(k, str(cfg[k]))
	one_shot = bool(cfg.get("one_shot", one_shot))
	dialogue_variants = cfg.get("variants", {})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _is_active() -> bool:
	if _used and one_shot:
		return false
	return true


## Penanda tampil? Mode Detektif menyembunyikan semua kecuali portal.
func marker_visible() -> bool:
	if not _is_active():
		return false
	if GameManager.hard_mode and target_location == "":
		return false
	return true


func contains_point(p: Vector2) -> bool:
	if not _is_active():
		return false
	return Rect2(position + area.position, area.size).has_point(p)


func get_prompt() -> String:
	var key: String = prompt_key if prompt_key != "" else "prompt_examine"
	return DataManager.tr_key(key).format({"name": display_name})


func set_highlight(on: bool) -> void:
	_hover = on
	queue_redraw()


## Ikon penanda menurut jenis prompt.
func _glyph() -> String:
	match prompt_key:
		"prompt_travel":
			return "➜"
		"prompt_read":
			return "✎"
		"prompt_open":
			return "▣"
		"prompt_pickup":
			return "✦"
		"prompt_moment":
			return "◈"
		_:
			return "🔍"


func _draw() -> void:
	if not marker_visible():
		return
	var pulse: float = 0.5 + 0.5 * sin(_t * 2.4 + _seed)
	var r: float = 11.0 + pulse * 2.5
	var base := Color(1.0, 0.72, 0.25)
	if prompt_key == "prompt_travel":
		base = Color(0.55, 0.85, 1.0)
	elif prompt_key == "prompt_moment":
		base = Color(0.95, 0.6, 0.85)
	var bob: float = 0.0 if GameManager.reduce_motion else sin(_t * 2.0 + _seed) * 3.0
	var c := Vector2(0, bob)
	if _hover:
		draw_circle(c, r + 14.0, Color(base.r, base.g, base.b, 0.18))
		draw_arc(c, r + 9.0, 0.0, TAU, 40, Color(1, 1, 1, 0.9), 2.0, true)
		# Bingkai area objek.
		var rr := Rect2(area.position, area.size)
		draw_rect(rr, Color(base.r, base.g, base.b, 0.55), false, 1.5)
	else:
		draw_circle(c, r + 5.0 + pulse * 4.0, Color(base.r, base.g, base.b, 0.16 - pulse * 0.08))
	draw_circle(c, r, Color(0.08, 0.06, 0.12, 0.78))
	draw_arc(c, r, 0.0, TAU, 32, base, 2.0, true)
	# Titik pusat (ganti font emoji yang mungkin tak tersedia).
	draw_circle(c, 3.2, base)
	if prompt_key == "prompt_travel":
		draw_line(c + Vector2(-5, 0), c + Vector2(5, 0), base, 2.0)
		draw_line(c + Vector2(1, -4), c + Vector2(5, 0), base, 2.0)
		draw_line(c + Vector2(1, 4), c + Vector2(5, 0), base, 2.0)


# ---------- Interaksi (setara InteractiveObject 3D) ----------

func interact(_from: Node = null) -> void:
	var gm := GameManager
	var dm := DataManager
	var im := InvestigationManager
	var bus := SignalBus
	if not gm.is_gameplay_input_active():
		return
	if _used and one_shot:
		return
	if required_flag != "" and not _flag_satisfied(gm, required_flag):
		_fallback_dialogue("Butuh sesuatu yang lain terlebih dahulu.")
		return
	if required_item != "" and not im.has_item(required_item):
		var need_name: String = str((dm.get_item(required_item) as Dictionary).get("name", required_item))
		bus.toast_requested.emit(dm.tr_key("toast_need_item").format({"item": need_name}), "system")
		bus.sfx_requested.emit("sfx_deduction_wrong")
		_fallback_dialogue("")
		return
	if target_location != "":
		bus.sfx_requested.emit("sfx_door_open")
		var main := get_tree().current_scene
		if main and main.has_method("travel_to"):
			main.travel_to(target_location, target_spawn)
		return
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
	if memory_dialogue != "" and dm.has_dialogue(memory_dialogue):
		bus.sfx_requested.emit("sfx_memory")
		DialogueManager.start_dialogue(memory_dialogue)
		_mark_used()
		return
	var dlg: String = _resolve_dialogue(gm)
	if dlg != "" and dm.has_dialogue(dlg):
		DialogueManager.start_dialogue(dlg)
	elif clue_id == "" and item_id == "":
		bus.toast_requested.emit(display_name, "system")
	_mark_used()


func _flag_satisfied(gm: Node, req: String) -> bool:
	if "=" in req:
		var parts: PackedStringArray = req.split("=", true, 1)
		return str(gm.get_flag(parts[0].strip_edges(), "")) == parts[1].strip_edges()
	return gm.flag_on(req.strip_edges())


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


func _resolve_dialogue(gm: Node) -> String:
	for k in dialogue_variants.keys():
		if gm.flag_on(str(k)):
			return str(dialogue_variants[k])
	return dialogue_id


func _fallback_dialogue(toast_text: String) -> void:
	if consume_dialogue != "" and DataManager.has_dialogue(consume_dialogue):
		DialogueManager.start_dialogue(consume_dialogue)
	elif toast_text != "":
		SignalBus.toast_requested.emit(toast_text, "system")


func _mark_used() -> void:
	if one_shot:
		_used = true
		queue_redraw()
