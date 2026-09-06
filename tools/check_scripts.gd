extends SceneTree
## Muat & kompilasi SEMUA skrip .gd dan scene .tscn dengan engine sungguhan,
## setelah autoload terdaftar (berbeda dengan --check-only yang berjalan lebih awal).
## Pakai: godot --headless --path . -s res://tools/check_scripts.gd


func _initialize() -> void:
	var bad: int = 0
	var n: int = 0
	for p in _walk("res://scripts", ".gd") + ["res://tools/smoke_test.gd"]:
		n += 1
		var s: Script = load(p)
		if s == null or not s.can_instantiate():
			printerr("  ✘ skrip gagal dimuat/dikompilasi: " + p)
			bad += 1
	var m: int = 0
	for p in _walk("res://scenes", ".tscn"):
		m += 1
		var ps: PackedScene = load(p)
		if ps == null:
			printerr("  ✘ scene gagal dimuat: " + p)
			bad += 1
			continue
		var inst: Node = ps.instantiate()
		if inst == null:
			printerr("  ✘ scene gagal di-instantiate: " + p)
			bad += 1
		else:
			inst.free()
	print("SCRIPT CHECK: %s (%d skrip, %d scene, %d gagal)" % ["PASS" if bad == 0 else "FAIL", n, m, bad])
	quit(1 if bad > 0 else 0)


func _walk(dir: String, ext: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	d.list_dir_begin()
	var f: String = d.get_next()
	while f != "":
		var full: String = dir.path_join(f)
		if d.current_is_dir():
			if not f.begins_with("."):
				out.append_array(_walk(full, ext))
		elif f.ends_with(ext):
			out.append(full)
		f = d.get_next()
	out.sort()
	return out
