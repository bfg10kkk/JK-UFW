#!/bin/sh
# jk-ufw: put the "Topology" page (network map with every host) onto a running firewall for testing,
# without rebuilding the image. Run as root on the firewall (console option 8 "Shell", or over SSH):
#
#   fetch -o /tmp/try-topology.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-topology.sh
#   sh /tmp/try-topology.sh                     # files from stable/26.7
#   sh /tmp/try-topology.sh <branch>            # or from another branch, e.g. one under review
#
# Undo: sh /tmp/try-topology.sh --remove   (or reinstall core: opnsense-revert core)
# The page only reads data, it changes nothing in the configuration.
#
# BSD-2-Clause, see jk-ufw/LICENSE.
set -e

REPO="https://raw.githubusercontent.com/bfg10kkk/JK-UFW"
BRANCH="${1:-stable/26.7}"
BASE=/usr/local/opnsense
FILES="
mvc/app/controllers/OPNsense/JkUfw/TopologyController.php
mvc/app/views/OPNsense/JkUfw/topology.volt
mvc/app/controllers/OPNsense/JkUfw/DevicesController.php
mvc/app/views/OPNsense/JkUfw/devices.volt
mvc/app/models/OPNsense/JkUfw/ACL/ACL.xml
mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml
"

clear_caches() {
    # menu and ACL are cached; the next page load rebuilds them
    rm -f /var/lib/php/tmp/opnsense_menu_cache.xml /var/lib/php/tmp/opnsense_acl_cache.json
}

if [ "$BRANCH" = "--remove" ]; then
    rm -f "$BASE/mvc/app/controllers/OPNsense/JkUfw/TopologyController.php" \
          "$BASE/mvc/app/views/OPNsense/JkUfw/topology.volt"
    clear_caches
    echo "Removed. The menu entry disappears with the next jk-ufw menu update or try-all.sh --remove."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-topology.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
for f in $FILES; do
    mkdir -p "$TMP/$(dirname "$f")"
    fetch -q -o "$TMP/$f" "$REPO/$BRANCH/src/opnsense/$f" || { echo "!!! cannot download $f from branch $BRANCH"; exit 1; }
done
for f in $FILES; do
    mkdir -p "$BASE/$(dirname "$f")"
    install -m 0644 "$TMP/$f" "$BASE/$f"
done
clear_caches

echo
echo "Done. Open https://<firewall>/ui/jkufw/topology   (menu: Lobby > Topology)"
echo "Optional: Services > Host Discovery shows devices that are not connected right now, with first/last seen times."
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
