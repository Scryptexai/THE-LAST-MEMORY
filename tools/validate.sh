#!/usr/bin/env bash
# Validasi penuh: parse semua GDScript (gdtoolkit) + invarian data.
# Pakai: tools/validate.sh   (butuh: pip install gdtoolkit; opsional: npm i @gdscript-analyzer/core)
set -u
cd "$(dirname "$0")/.."
FAIL=0
N=0
if command -v gdparse >/dev/null 2>&1; then
	for f in $(find scripts -name '*.gd' | sort); do
		N=$((N + 1))
		OUT=$(gdparse "$f" 2>&1) || { echo "=== $f"; echo "$OUT" | head -12; FAIL=1; }
	done
	[ $FAIL -eq 0 ] && echo "GDSCRIPT PARSE OK ($N files)"
else
	echo "(gdparse tidak ditemukan — lewati parse GDScript; pip install gdtoolkit)"
fi
if command -v node >/dev/null 2>&1; then
	node tools/analyze_gd.mjs || FAIL=1
fi
python3 tools/validate_data.py || FAIL=1
exit $FAIL
