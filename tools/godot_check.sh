#!/usr/bin/env bash
# Verifikasi dengan engine Godot SUNGGUHAN (headless):
#   1) tools/check_scripts.gd: muat+kompilasi semua skrip & scene (persis seperti editor),
#   2) tools/smoke_test.gd: jalankan game, semua lokasi/dialog/UI/ending.
# Pakai: tools/godot_check.sh [path-ke-godot]
#   Binari dicari dari argumen, $GODOT, lalu PATH (godot / godot4).
#   Bila tidak ada editor: template_debug hasil build sendiri juga bisa
#   (lihat tools/build_godot_headless.sh) — untuk itu perlu class cache,
#   yang dibuat otomatis oleh tools/gen_class_cache.py.
set -u
cd "$(dirname "$0")/.."
BIN="${1:-${GODOT:-}}"
if [ -z "$BIN" ]; then
	for c in godot godot4 godot4.3 /home/user/build/godot; do
		if command -v "$c" >/dev/null 2>&1; then BIN="$c"; break; fi
	done
fi
if [ -z "$BIN" ]; then
	echo "(godot_check: binari Godot tidak ditemukan — lewati)"
	exit 0
fi
echo "Godot: $("$BIN" --version 2>/dev/null | tail -1) ($BIN)"
python3 tools/gen_class_cache.py
NOISE='No renderers available|main.cpp:2097|fontconfig|os_linuxbsd.cpp:852|MSDFGEN|text_server_fb.cpp:746|mesh_get_surface_count|Parameter "m" is null|Parameter "t" is null|texture_2d_get|gagal mengabadikan momen|variant_utility.cpp:1112|ObjectDB instances leaked|object.cpp:2284|^\[DEBUG\]|^$'
FAIL=0
OUT=$(timeout 300 "$BIN" --headless --path . -s res://tools/check_scripts.gd 2>&1 | grep -Ev "$NOISE")
echo "$OUT" | grep -E "✘|SCRIPT ERROR|^ERROR|Parse Error|SCRIPT CHECK" | head -40
echo "$OUT" | grep -q "SCRIPT CHECK: PASS" || FAIL=1
OUT=$(timeout 600 "$BIN" --headless --path . -s res://tools/smoke_test.gd 2>&1 | grep -Ev "$NOISE")
echo "$OUT" | grep -E "✘|SCRIPT ERROR|^ERROR|SMOKE TEST" | head -40
if echo "$OUT" | grep -qE "SCRIPT ERROR|^ERROR|✘|SMOKE TEST: FAIL"; then FAIL=1; fi
echo "$OUT" | grep -q "SMOKE TEST: PASS" || FAIL=1
exit $FAIL
