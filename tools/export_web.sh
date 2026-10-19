#!/usr/bin/env bash
# Rebuild the itch.io web build: build/web/ + build/GullinIt-web.zip.
# Exports from a temp COPY so the project's .godot import cache is untouched.
# Needs a Godot 4.7.2 editor binary and web_nothreads_* export templates
# in $XDG_DATA_HOME/godot/export_templates/4.7.2.stable/.
set -euo pipefail
GODOT="${GODOT:-$HOME/Godot_v4.7.2-stable_linux.x86_64}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/gdata}" XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/gdata}"
SRC="$(cd "$(dirname "$0")/.." && pwd)"; WORK="${WORK:-$HOME/exportproj}"

rm -rf "$WORK"; mkdir -p "$WORK"
(cd "$SRC" && tar --exclude=./.tools --exclude=./.git --exclude=./test-output \
  --exclude=./build --exclude=./export_templates --exclude=./.godot -cf - .) | (cd "$WORK" && tar xf -)
cd "$WORK"; mkdir -p build/web
# Web preset: skip mobile VRAM compression (export fails with it unless project enables ETC2/ASTC import).
sed -i 's#vram_texture_compression/for_mobile=true#vram_texture_compression/for_mobile=false#' export_presets.cfg
"$GODOT" --headless --path . --editor --import --quit >/dev/null 2>&1
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
ls -l build/web/index.html >/dev/null   # fail if export produced nothing

# Publish: replace build/web and create the zip with index.html at its root.
rm -rf "$SRC/build/web"; mkdir -p "$SRC/build/web"; cp -r build/web/. "$SRC/build/web/"
rm -f "$SRC/build/GullinIt-web.zip"
(cd "$SRC/build/web" && zip -q -r -9 ../GullinIt-web.zip .)
du -b "$SRC"/build/web/* "$SRC/build/GullinIt-web.zip" | awk '{printf "%10.2f MB  %s\n",$1/1048576,$2}'
