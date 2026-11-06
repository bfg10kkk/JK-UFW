#!/bin/sh
# jk-ufw: put the "Country Blocking" page (world map) and dashboard widget onto a running firewall for testing,
# without rebuilding the image. Run as root on the firewall (console option 8 "Shell", or over SSH):
#
#   fetch -o /tmp/try-geoblock.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-geoblock.sh
#   sh /tmp/try-geoblock.sh                                 # files from stable/26.7
#   sh /tmp/try-geoblock.sh claude/project-thread-5i7j4g    # or from another branch, e.g. one under review
#
# Undo: sh /tmp/try-geoblock.sh --remove   (or reinstall core: opnsense-revert core)
# The alias jkufw_geoblock and the two "jk-ufw: geoblock" rules stay in the config; delete them in
# Firewall > Aliases and Firewall > Rules if you no longer want them.
#
# BSD-2-Clause, see jk-ufw/LICENSE.
set -e

REPO="https://raw.githubusercontent.com/bfg10kkk/JK-UFW"
BRANCH="${1:-stable/26.7}"
BASE=/usr/local/opnsense
OWN="
mvc/app/controllers/OPNsense/Firewall/GeoblockController.php
mvc/app/views/OPNsense/Firewall/geoblock.volt
mvc/app/models/OPNsense/JkUfw/ACL/ACL.xml
www/js/jkufw-worldmap.js
www/js/widgets/JkUfwGeoblock.js
"
SHARED="
mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml
www/js/widgets/Metadata/JkUfw.xml
"

clear_caches() {
    # menu and ACL are cached; the next page load rebuilds them
    rm -f /var/lib/php/tmp/opnsense_menu_cache.xml /var/lib/php/tmp/opnsense_acl_cache.json
}

if [ "$BRANCH" = "--remove" ]; then
    for f in $OWN; do rm -f "$BASE/$f"; done
    clear_caches
    echo "Removed. The menu and widget entries stay but point to missing files and are not shown."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-geo.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
for f in $OWN $SHARED; do
    mkdir -p "$TMP/$(dirname "$f")"
    fetch -q -o "$TMP/$f" "$REPO/$BRANCH/src/opnsense/$f" || { echo "!!! cannot download $f from branch $BRANCH"; exit 1; }
done
# the widgets this metadata file lists must exist too, take them from the same branch
for w in $(sed -n 's#.*<filename>\(.*\)</filename>.*#\1#p' "$TMP/www/js/widgets/Metadata/JkUfw.xml") JkUfwCommon.js; do
    f="www/js/widgets/$w"
    [ -f "$TMP/$f" ] || fetch -q -o "$TMP/$f" "$REPO/$BRANCH/src/opnsense/$f" || true
done
(cd "$TMP" && find . -type f) | while read -r f; do
    mkdir -p "$BASE/$(dirname "$f")"
    install -m 0644 "$TMP/$f" "$BASE/$f"
done
clear_caches

echo
echo "Done. Open https://<firewall>/ui/firewall/geoblock  (menu: Firewall > Country Blocking)"
echo "You need a free MaxMind GeoLite2 license key; the page asks for it and downloads the database."
echo "Dashboard: + Add widget > 'jk-ufw: Блокировка стран'."
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
