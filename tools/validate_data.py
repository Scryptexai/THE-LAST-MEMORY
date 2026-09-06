#!/usr/bin/env python3
"""Validasi invarian data THE LAST MEMORY (tanpa Godot).

Memeriksa: semua JSON valid; semua dialog terjangkau dari titik masuk
(scene NPC/interactable/varian/hadiah, panggilan start_dialogue di kode,
referensi dlg_* di JSON lain); pencapaian dirujuk dua arah; ui_strings id/en
paritas + semua tr_key() di kode ada; referensi clue/item/objective/moment/
scene/flag-quest konsisten. Keluar dengan kode 1 bila ada pelanggaran.

Pakai:  python3 tools/validate_data.py   (dari root repo)
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    errs = []
    for p in sorted(glob.glob("assets/data/*.json")):
        try:
            load(p)
        except json.JSONDecodeError as e:  # pragma: no cover
            errs.append(f"JSON rusak: {p}: {e}")
    if errs:
        for e in errs:
            print(" -", e)
        return 1
    print("JSON OK")

    dlg = {n["id"]: n for n in load("assets/data/dialogues.json")["dialogues"]}
    scenes = load("assets/data/scenes.json")["scenes"]
    scene_ids = {s["id"] for s in scenes}
    code_all = ""
    for p in glob.glob("scripts/**/*.gd", recursive=True):
        code_all += open(p, encoding="utf-8").read() + "\n"

    # --- Keterjangkauan dialog ---
    entries = {"dlg_intro_01"}
    for s in scenes:
        for npc in s.get("npcs", []):
            entries.add(npc.get("dialogue_id", ""))
            entries.update(npc.get("variants", {}).values())
            for g in npc.get("gifts", {}).values():
                entries.add(g.get("dialogue", ""))
        for o in s.get("interactables", []):
            for k in ("dialogue_id", "consume_dialogue", "memory_dialogue"):
                entries.add(o.get(k, ""))
            entries.update(o.get("variants", {}).values())
    entries.update(re.findall(r'start_dialogue\("(dlg_[a-z0-9_]+)"', code_all))
    for p in glob.glob("assets/data/*.json"):
        if p.endswith("dialogues.json"):
            continue
        entries.update(re.findall(r'"(dlg_[a-z0-9_]+)"', open(p, encoding="utf-8").read()))
    entries.discard("")
    for e in sorted(entries):
        if e not in dlg:
            errs.append(f"titik masuk dialog hilang: {e}")
    seen, stack = set(), list(entries)
    while stack:
        x = stack.pop()
        if x in seen or x not in dlg:
            continue
        seen.add(x)
        n = dlg[x]
        nx = n.get("next", "")
        if nx not in ("", "END"):
            if nx not in dlg:
                errs.append(f"{x}.next -> {nx} tidak ada")
            stack.append(nx)
        for ch in n.get("choices", []):
            cn = ch.get("next", "")
            if cn not in ("", "END"):
                if cn not in dlg:
                    errs.append(f"{x} pilihan -> {cn} tidak ada")
                stack.append(cn)
    for k in dlg:
        if k not in seen:
            errs.append(f"dialog tak terjangkau: {k}")
    print(f"dialogues: {len(dlg)}, reachable: {len(seen)}")

    # --- Pencapaian dua arah ---
    ach = {a["id"] for a in load("assets/data/achievements.json")["achievements"]}
    refs = set(re.findall(r'unlock\("(ach_[a-z_]+)"', code_all))
    if refs - ach:
        errs.append(f"unlock() merujuk pencapaian tak dikenal: {sorted(refs - ach)}")
    if ach - refs:
        errs.append(f"pencapaian tak pernah di-unlock: {sorted(ach - refs)}")
    print(f"achievements: {len(ach)}, refs: {len(refs)}")

    # --- ui_strings ---
    us = load("assets/data/ui_strings.json")
    mism = set(us["id"]) ^ set(us["en"])
    if mism:
        errs.append(f"ui_strings id/en tidak paritas: {sorted(mism)}")
    keys = set(re.findall(r'tr_key\("([a-z_0-9]+)"', code_all))
    for k in sorted(keys):
        if k not in us["id"] and not k.startswith("chapter_"):
            errs.append(f"tr_key('{k}') tidak ada di ui_strings")
    for ep in load("assets/data/epilogues.json")["epilogues"]:
        nk = ep.get("name_key")
        if nk and nk not in us["id"]:
            errs.append(f"epilogues name_key {nk} tidak ada")
    print(f"ui_strings: {len(us['id'])} keys, {len(keys)} code refs")

    # --- Referensi silang ---
    clues = {c["id"] for c in load("assets/data/clues.json")["clues"]}
    items = {i["id"] for i in load("assets/data/items.json")["items"]}
    moments = {m["id"] for m in load("assets/data/moments.json")["moments"]}
    objs = {o["id"] for o in load("assets/data/objectives.json")["objectives"]}
    for s in scenes:
        if not os.path.exists(s.get("scene_path", "").replace("res://", "")):
            errs.append(f"scene_path hilang: {s.get('scene_path')}")
        for o in s.get("interactables", []):
            if o.get("clue_id") and o["clue_id"] not in clues:
                errs.append(f"clue {o['clue_id']} hilang ({s['id']})")
            if o.get("item_id") and o["item_id"] not in items:
                errs.append(f"item {o['item_id']} hilang ({s['id']})")
            if o.get("required_item") and o["required_item"] not in items:
                errs.append(f"required_item {o['required_item']} hilang ({s['id']})")
            if o.get("moment_id") and o["moment_id"] not in moments:
                errs.append(f"moment {o['moment_id']} hilang ({s['id']})")
        for npc in s.get("npcs", []):
            for gid in npc.get("gifts", {}):
                if gid not in items:
                    errs.append(f"hadiah {gid} bukan item ({s['id']})")
    for m in load("assets/data/moments.json")["moments"]:
        if m.get("location") not in scene_ids:
            errs.append(f"moment {m['id']} lokasi {m.get('location')} tidak ada")
    for c in load("assets/data/clues.json")["clues"]:
        if c.get("found_in") and c["found_in"] not in scene_ids:
            errs.append(f"clue {c['id']} found_in {c['found_in']} tidak ada")
    for q in load("assets/data/quests.json")["quests"]:
        if q.get("location") and q["location"] not in scene_ids:
            errs.append(f"quest {q['id']} lokasi {q['location']} tidak ada")

    def effect_lists(n, key):
        out = list(n.get("effects", {}).get(key, []))
        for ch in n.get("choices", []):
            out += list(ch.get(key, []))
        return out

    for n in dlg.values():
        for c in effect_lists(n, "add_clues"):
            if c not in clues:
                errs.append(f"{n['id']}: add_clues {c} hilang")
        for it in effect_lists(n, "add_items") + effect_lists(n, "remove_items"):
            if it not in items:
                errs.append(f"{n['id']}: item {it} hilang")
        for ch in n.get("choices", []):
            for it in ch.get("requires_items", []):
                if it not in items:
                    errs.append(f"{n['id']}: requires_items {it} hilang")
        o = n.get("effects", {}).get("objective", "")
        if o and o not in objs:
            errs.append(f"{n['id']}: objective {o} hilang")
        mv = n.get("effects", {}).get("move_to", "")
        if mv and mv not in scene_ids:
            errs.append(f"{n['id']}: move_to {mv} tidak ada")

    print("RESULT:", "FAIL" if errs else "PASS")
    for e in errs:
        print(" -", e)
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
