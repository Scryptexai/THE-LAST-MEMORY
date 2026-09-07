class_name NPC2D
extends Actor2D
## NPC2D — tokoh pendukung di panggung 2D: berdiri di posnya, menoleh ke Ardi,
## melambai/melompat kecil saat Ardi mendekat, berjalan santai bila `wander_radius`,
## dan memicu dialog (termasuk hadiah & varian flag) — logika sama dengan NPC 3D.

var dialogue_id: String = ""
var dialogue_flag_variants: Dictionary = {}
var gift_options: Dictionary = {}
var wander_radius: float = 0.0

var _home: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _wait: float = 0.0
var _greeted: bool = false


func _ready() -> void:
	super()
	add_to_group("interactable")
	add_to_group("npc")
	_home = position
	_target = position
	_wait = randf_range(1.0, 3.0)


func configure(cfg: Dictionary) -> void:
	character_id = str(cfg.get("character_id", "warga"))
	display_name = str(cfg.get("display_name", "Warga"))
	dialogue_id = str(cfg.get("dialogue_id", ""))
	dialogue_flag_variants = cfg.get("variants", {})
	gift_options = cfg.get("gifts", {})
	wander_radius = float(cfg.get("wander", 0.0)) * 90.0  # meter → px desain
	load_sprite(character_id)


func _process(delta: float) -> void:
	super(delta)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var near: bool = false
	if player:
		var d: float = absf(player.position.x - position.x)
		near = d < 260.0
		if near and not moving:
			face_towards(player.position.x)
		if d < 170.0 and not _greeted:
			_greeted = true
			hop()
		elif d > 300.0:
			_greeted = false
	_update_wander(delta, near)


func _update_wander(delta: float, near_player: bool) -> void:
	if wander_radius <= 0.0:
		moving = false
		return
	if near_player or not GameManager.is_gameplay_input_active():
		moving = false
		return
	var to: Vector2 = _target - position
	if to.length() < 4.0:
		moving = false
		_wait -= delta
		if _wait <= 0.0:
			_wait = randf_range(2.0, 5.0)
			var ang: float = randf() * TAU
			var r: float = randf_range(wander_radius * 0.3, wander_radius)
			_target = clamp_to_floor(_home + Vector2(cos(ang) * r, sin(ang) * r * 0.25))
		return
	moving = true
	running = false
	var spd: float = 70.0 * view_scale() / 0.35
	var step: Vector2 = to.normalized() * spd * delta
	if step.length() > to.length():
		step = to
	position += step
	face_towards(_target.x)


func get_prompt() -> String:
	return DataManager.tr_key("prompt_talk").format({"name": display_name})


func interact(_from: Node = null) -> void:
	var gm := GameManager
	if not gm.is_gameplay_input_active():
		return
	InvestigationManager.mark_character_met(character_id)
	var gift_dlg: String = _check_gift()
	if gift_dlg != "":
		DialogueManager.start_dialogue(gift_dlg)
		return
	var dlg: String = _resolve_dialogue()
	if dlg == "":
		SignalBus.toast_requested.emit(display_name + " ...", "system")
		return
	DialogueManager.start_dialogue(dlg)


func _check_gift() -> String:
	if gift_options.is_empty():
		return ""
	var im := InvestigationManager
	var gm := GameManager
	for item_id in gift_options.keys():
		var g: Dictionary = gift_options[item_id]
		var flag: String = str(g.get("flag", ""))
		if flag != "" and gm.flag_on(flag):
			continue
		if im.has_item(str(item_id)):
			if flag != "":
				gm.set_flag(flag, true)
			var rel: Dictionary = g.get("relationship", {})
			for cid in rel.keys():
				RelationshipManager.add(str(cid), int(rel[cid]))
			im.remove_item(str(item_id))
			return str(g.get("dialogue", ""))
	return ""


func _resolve_dialogue() -> String:
	var gm := GameManager
	var variant_key: String = str(gm.get_flag(character_id + "_variant", ""))
	if variant_key != "" and dialogue_flag_variants.has(variant_key):
		return str(dialogue_flag_variants[variant_key])
	for k in dialogue_flag_variants.keys():
		if gm.flag_on(str(k)):
			return str(dialogue_flag_variants[k])
	return dialogue_id
