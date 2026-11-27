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
# Stamp the upload: <base version>.b<commit count>.<short sha>[-dirty], e.g. 0.1.0-demo.b412.ab12cd3. Analytics reports it as `build`,
# so each itch upload can be told apart. Hex never spells "test", so the saved view's NOT LIKE '%test%' filter keeps these builds.
BASE="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot | head -1)"
[ -n "$BASE" ] || { echo "config/version not found in project.godot" >&2; exit 1; }
BUILD="${BASE}.b$(git -C "$SRC" rev-list --count HEAD).$(git -C "$SRC" rev-parse --short HEAD)"
[ -z "$(git -C "$SRC" status --porcelain --untracked-files=no)" ] || BUILD="$BUILD-dirty"
sed -i "s#^config/version=.*#config/version=\"$BUILD\"#" project.godot
echo "Build version: $BUILD"
# Safety net; the committed preset already disables mobile VRAM compression.
sed -i 's#vram_texture_compression/for_mobile=true#vram_texture_compression/for_mobile=false#' export_presets.cfg
"$GODOT" --headless --path . --editor --import --quit >/dev/null 2>&1
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
ls -l build/web/index.html >/dev/null   # fail if export produced nothing

# Publish: replace build/web and create the zip with index.html at its root.
rm -rf "$SRC/build/web"; mkdir -p "$SRC/build/web"; cp -r build/web/. "$SRC/build/web/"
rm -f "$SRC/build/GullinIt-web.zip"
(cd "$SRC/build/web" && zip -q -r -9 ../GullinIt-web.zip .)
du -b "$SRC"/build/web/* "$SRC/build/GullinIt-web.zip" | awk '{printf "%10.2f MB  %s\n",$1/1048576,$2}'
