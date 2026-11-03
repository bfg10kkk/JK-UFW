#!/bin/sh
# Rebuilds the jk-ufw theme.
# Base layer: the "rebellion" dark theme (BSD-2-Clause, see LICENSE), taken from a
# clone of the upstream plugins repository: misc/theme-rebellion.
# Usage: ./build.sh /path/to/plugins-clone
set -e
PLUGINS=${1:?path to a clone of the upstream plugins repository}
HERE=$(cd "$(dirname "$0")" && pwd)
SRC="$PLUGINS/misc/theme-rebellion/src/opnsense/www/themes/rebellion/build"
DST="$HERE/src/opnsense/www/themes/jkufw/build"
rm -rf "$DST" && mkdir -p "$DST" && cp -R "$SRC/." "$DST/"
rm -f "$DST/images/default-logo.png" "$DST/images/icon-logo.png"
for f in "$DST"/css/*.css; do
  # orange palette -> red; point font/image URLs at this theme instead of the stock one
  sed -i.bak \
    -e 's/#[Ee][Aa]7105/#e5202e/g'  -e 's/#[Ee][Cc]6[Dd]12/#ef3340/g' \
    -e 's/#[Dd]95100/#c8101e/g'     -e 's/#9[Ff]4[Dd]03/#8f0d17/g' \
    -e 's/#[Bb]85904/#a5121c/g'     -e 's/#9[Cc]3[Aa]00/#7d0b14/g' \
    -e 's/#[Cc][Ee]671[Cc]/#c81d2a/g' -e 's/#[Ee][Dd]9[Aa]50/#f0646e/g' \
    -e 's/#[Ff]7[Ee]2[Dd]6/#f9d6d9/g' \
    -e 's|/ui/themes/opnsense/build/|/ui/themes/jkufw/build/|g' "$f"
  rm -f "$f.bak"
done
cat "$HERE/overrides/main.css"      >> "$DST/css/main.css"
cat "$HERE/overrides/ui.css"        >> "$DST/css/main.css"
cat "$HERE/overrides/grid.css"      >> "$DST/css/opnsense-bootgrid.css"
cat "$HERE/overrides/dashboard.css" >> "$DST/css/dashboard.css"
mkdir -p "$DST/fonts/inter" && cp "$HERE"/assets/fonts/inter/* "$DST/fonts/inter/"
cp "$HERE/assets/default-logo.svg" "$HERE/assets/icon-logo.svg" "$DST/images/"
mkdir -p "$DST/js" && cp "$HERE/assets/js/theme.js" "$DST/js/theme.js"
[ -f "$HERE/assets/favicon.png" ] && cp "$HERE/assets/favicon.png" "$DST/images/favicon.png"
echo "jk-ufw theme built in $DST"
