#!/usr/bin/env bash
# Bangun Godot 4.3 headless minimal dari sumber (≈15 menit, 2 core) — untuk
# lingkungan yang tidak bisa mengunduh rilis resmi (mis. sandbox tanpa akses
# ke GitHub Releases). Hanya butuh: gcc/g++, python3, scons (pip), curl.
# Hasil: $OUT/godot (template_debug, tanpa X11/audio/Vulkan — cukup untuk
# --headless, --check-only, dan tools/smoke_test.gd).
set -euo pipefail
VER="${GODOT_VER:-4.3-stable}"
SRC="${SRC:-/tmp/godot-src}"
OUT="${OUT:-$HOME/build}"
mkdir -p "$OUT/bin" "$SRC"
python3 -c "import SCons" 2>/dev/null || pip install -q --break-system-packages scons
# pkg-config palsu: semua lib sistem dinyatakan tidak ada -> pakai builtin.
if ! command -v pkg-config >/dev/null 2>&1; then
	printf '#!/bin/sh\ncase "$1" in --version) echo 1.8.1; exit 0;; esac\nexit 1\n' > "$OUT/bin/pkg-config"
	chmod +x "$OUT/bin/pkg-config"
	export PATH="$OUT/bin:$PATH"
fi
if [ ! -d "$SRC/godot-$VER" ]; then
	curl -sL -o "$SRC/godot.tgz" "https://codeload.github.com/godotengine/godot/tar.gz/refs/tags/$VER"
	tar xzf "$SRC/godot.tgz" -C "$SRC"
fi
cd "$SRC/godot-$VER"
scons -j"$(nproc)" platform=linuxbsd target=template_debug optimize=size debug_symbols=no lto=none \
	x11=no wayland=no alsa=no pulseaudio=no dbus=no speechd=no udev=no fontconfig=no vulkan=no opengl3=no \
	module_mono_enabled=no module_openxr_enabled=no module_webrtc_enabled=no module_webxr_enabled=no module_mobile_vr_enabled=no \
	module_raycast_enabled=no module_lightmapper_rd_enabled=no module_xatlas_unwrap_enabled=no module_vhacd_enabled=no \
	module_basis_universal_enabled=no module_astcenc_enabled=no module_cvtt_enabled=no module_etcpak_enabled=no module_squish_enabled=no \
	module_tinyexr_enabled=no module_ktx_enabled=no module_upnp_enabled=no module_theora_enabled=no module_camera_enabled=no \
	module_fbx_enabled=no module_gltf_enabled=no module_navigation_enabled=no module_msdfgen_enabled=no \
	module_text_server_adv_enabled=no module_text_server_fb_enabled=yes module_multiplayer_enabled=no module_enet_enabled=no \
	module_websocket_enabled=no module_mbedtls_enabled=no module_noise_enabled=no module_csg_enabled=no module_gridmap_enabled=no \
	module_interactive_music_enabled=no module_dds_enabled=no module_hdr_enabled=no module_tga_enabled=no module_bmp_enabled=no \
	module_zip_enabled=no module_jsonrpc_enabled=no module_minimp3_enabled=no module_ogg_enabled=no module_vorbis_enabled=no \
	module_webp_enabled=no module_jpg_enabled=no module_meshoptimizer_enabled=no progress=no verbose=no
cp bin/godot.linuxbsd.template_debug.x86_64 "$OUT/godot"
echo "OK: $OUT/godot ($("$OUT/godot" --version))"
