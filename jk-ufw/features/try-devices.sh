#!/bin/sh
# jk-ufw: put the "Devices" page onto a running firewall for testing, without rebuilding the image.
# Run as root on the firewall (console option 8 "Shell", or over SSH):
#
#   fetch -o /tmp/try-devices.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-devices.sh
#   sh /tmp/try-devices.sh                                  # files from stable/26.7
#   sh /tmp/try-devices.sh claude/project-thread-ppevhd     # or from another branch, e.g. one under review
#
# Undo: sh /tmp/try-devices.sh --remove   (or reinstall core: opnsense-revert core)
# Blocks and speed limits made on the page stay in the configuration (aliases jkufw_block_*, rule
# "jk-ufw: blocked devices", shaper pipes "jk-ufw limit ..."); remove them on the page before --remove.
#
# BSD-2-Clause, see jk-ufw/LICENSE.
set -e

REPO="https://raw.githubusercontent.com/bfg10kkk/JK-UFW"
BRANCH="${1:-stable/26.7}"
BASE=/usr/local/opnsense
FILES="
mvc/app/controllers/OPNsense/JkUfw/DevicesController.php
mvc/app/views/OPNsense/JkUfw/devices.volt
mvc/app/models/OPNsense/JkUfw/ACL/ACL.xml
mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml
www/js/widgets/Metadata/JkUfw.xml
"

clear_caches() {
    # menu and ACL are cached; the next page load rebuilds them
    rm -f /var/lib/php/tmp/opnsense_menu_cache.xml /var/lib/php/tmp/opnsense_acl_cache.json
}

if [ "$BRANCH" = "--remove" ]; then
    rm -rf "$BASE/mvc/app/controllers/OPNsense/JkUfw" "$BASE/mvc/app/views/OPNsense/JkUfw" \
           "$BASE/mvc/app/models/OPNsense/JkUfw/ACL"
    clear_caches
    echo "Removed. The menu file stays if other jk-ufw pages use it."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-devices.XXXXXX)
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
echo "Done. Open https://<firewall>/ui/jkufw/devices   (menu: Lobby > Devices)"
echo "Live traffic per device needs iftop (installed with core). Optional: Services > Host Discovery"
echo "gives first/last seen times for devices that are not connected right now."
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
