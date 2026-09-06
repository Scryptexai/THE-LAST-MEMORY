#!/usr/bin/env python3
"""Buat .godot/global_script_class_cache.cfg dari semua `class_name` di scripts/.
Dipakai untuk menjalankan Godot template/headless tanpa editor (mis. tools/godot_check.sh).
Editor Godot membuat file ini sendiri; skrip ini hanya meniru formatnya."""
import os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
entries = []
for dp, _, fs in os.walk(os.path.join(ROOT, "scripts")):
    for f in sorted(fs):
        if not f.endswith(".gd"):
            continue
        p = os.path.join(dp, f)
        src = open(p, encoding="utf-8").read()
        m = re.search(r"^class_name\s+(\w+)", src, re.M)
        if not m:
            continue
        base = "RefCounted"
        mb = re.search(r"^extends\s+([\w\"./:]+)", src, re.M)
        if mb:
            base = mb.group(1).strip('"')
            if base.startswith("res://"):
                # extends via path: pakai class_name file tujuan bila ada
                tgt = os.path.join(ROOT, base[len("res://"):])
                try:
                    mm = re.search(r"^class_name\s+(\w+)", open(tgt, encoding="utf-8").read(), re.M)
                    base = mm.group(1) if mm else "Node"
                except OSError:
                    base = "Node"
        rel = "res://" + os.path.relpath(p, ROOT).replace(os.sep, "/")
        entries.append((m.group(1), base, rel))
os.makedirs(os.path.join(ROOT, ".godot"), exist_ok=True)
items = ", ".join(
    '{\n"base": &"%s",\n"class": &"%s",\n"icon": "",\n"language": &"GDScript",\n"path": "%s"\n}' % (b, c, p)
    for c, b, p in entries
)
open(os.path.join(ROOT, ".godot", "global_script_class_cache.cfg"), "w", encoding="utf-8").write("list=Array[Dictionary]([%s])\n" % items)
print("class cache: %d class_name" % len(entries))
