extends CanvasLayer
## UIManager — memuat seluruh layar UI, menampilkan/menyembunyikan sesuai
## state GameManager, dan meneruskan shortcut keyboard (J/I/L/Esc).

const SCREENS := {
	"hud": "res://scenes/ui/HUD.tscn",
	"main_menu": "res://scenes/ui/MainMenu.tscn",
	"dialogue": "res://scenes/ui/DialogueUI.tscn",
	"investigation": "res://scenes/ui/InvestigationUI.tscn",
	"inventory": "res://scenes/ui/InventoryUI.tscn",
	"journal": "res://scenes/ui/JournalUI.tscn",
	"settings": "res://scenes/ui/SettingsUI.tscn",
	"loading": "res://scenes/ui/LoadingUI.tscn",
	"ending": "res://scenes/ui/EndingUI.tscn",
}

var nodes: Dictionary = {}
var settings_return: String = "gameplay"


func _ready() -> void:
	layer = 10
	for key in SCREENS.keys():
		var packed: PackedScene = load(SCREENS[key])
		if packed == null:
			Logger.error("UIManager: gagal memuat " + str(SCREENS[key]))
			continue
		var inst := packed.instantiate() as Control
		inst.name = "UI_" + key
		inst.visible = false
		add_child(inst)
		nodes[key] = inst
	var bus := SignalBus
	bus.game_state_changed.connect(_on_state_changed)
	bus.ui_screen_requested.connect(_on_screen_requested)
	_on_state_changed(GameManager.state)


func get_screen(screen_name: String) -> Control:
	return nodes.get(screen_name, null)


func show_only(names: Array) -> void:
	for k in nodes.keys():
		(nodes[k] as Control).visible = k in names


func _on_screen_requested(screen: String) -> void:
	if screen == "settings":
		open_settings()
	elif nodes.has(screen):
		show_only([screen] if screen != "hud" else ["hud"])


func open_settings() -> void:
	var gm := GameManager
	if gm.state != "settings":
		settings_return = gm.state if gm.state != "main_menu" else "main_menu"
		gm.change_state("settings")


func _on_state_changed(state: String) -> void:
	match state:
		"main_menu":
			show_only(["main_menu"])
		"loading":
			show_only(["loading"])
		"gameplay":
			show_only(["hud"])
		"dialogue":
			show_only(["hud", "dialogue"])
		"investigation":
			show_only(["hud", "investigation"])
		"inventory":
			show_only(["hud", "inventory"])
		"journal":
			show_only(["hud", "journal"])
		"settings":
			if settings_return == "main_menu":
				show_only(["main_menu", "settings"])
			else:
				show_only(["hud", "settings"])
		"pause":
			show_only(["hud", "settings"])  # pause memakai panel settings sebagai menu jeda
		"ending":
			show_only(["ending"])
		_:
			show_only(["hud"])
	_refresh_hud_state()


func _refresh_hud_state() -> void:
	var hud := get_screen("hud")
	if hud and hud.has_method("refresh_state"):
		hud.refresh_state()


func _unhandled_input(event: InputEvent) -> void:
	var gm := GameManager
	var dm := DialogueManager
	if event.is_action_pressed("open_journal"):
		if gm.state == "gameplay":
			gm.change_state("journal")
		elif gm.state == "journal":
			gm.change_state("gameplay")
	elif event.is_action_pressed("open_inventory"):
		if gm.state == "gameplay":
			gm.change_state("inventory")
		elif gm.state == "inventory":
			gm.change_state("gameplay")
	elif event.is_action_pressed("open_investigation"):
		if gm.state == "gameplay":
			gm.change_state("investigation")
		elif gm.state == "investigation":
			gm.change_state("gameplay")
	elif event.is_action_pressed("open_map"):
		if gm.state == "gameplay":
			var hud := get_screen("hud")
			if hud and hud.has_method("toggle_travel"):
				hud.toggle_travel()
	elif event.is_action_pressed("ui_cancel"):
		match gm.state:
			"journal", "inventory", "investigation":
				gm.change_state("gameplay")
			"settings":
				gm.change_state(settings_return if settings_return != "settings" else "gameplay")
			"pause":
				gm.change_state("gameplay")
			"gameplay":
				if not dm.is_active():
					gm.change_state("pause")
