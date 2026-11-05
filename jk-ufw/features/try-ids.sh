#!/bin/sh
# jk-ufw: put the "Threat Management" (IDS/IPS) page and dashboard widget onto a running firewall for testing,
# without rebuilding the image. Run as root on the firewall (console option 8 "Shell", or over SSH):
#
#   fetch -o /tmp/try-ids.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-ids.sh
#   sh /tmp/try-ids.sh                          # files from stable/26.7
#   sh /tmp/try-ids.sh claude/project-thread-yohjd2   # or from another branch, e.g. one under review
#
# Undo: sh /tmp/try-ids.sh --remove   (or reinstall core: opnsense-revert core)
#
# BSD-2-Clause, see jk-ufw/LICENSE.
set -e

REPO="https://raw.githubusercontent.com/bfg10kkk/JK-UFW"
BRANCH="${1:-stable/26.7}"
BASE=/usr/local/opnsense
FILES="
mvc/app/controllers/OPNsense/IDS/ThreatsController.php
mvc/app/views/OPNsense/IDS/threats.volt
mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml
www/js/widgets/Metadata/JkUfw.xml
www/js/widgets/JkUfwCommon.js
www/js/widgets/JkUfwOverview.js
www/js/widgets/JkUfwTraffic.js
www/js/widgets/JkUfwClients.js
www/js/widgets/JkUfwInternet.js
www/js/widgets/JkUfwSecurity.js
www/js/widgets/JkUfwDns.js
www/js/widgets/JkUfwSystem.js
www/js/widgets/JkUfwPorts.js
www/js/widgets/JkUfwServices.js
www/js/widgets/JkUfwVpn.js
www/js/widgets/JkUfwThreats.js
"

clear_caches() {
    # menu and ACL are cached; the next page load rebuilds them
    rm -f /var/lib/php/tmp/opnsense_menu_cache.xml /var/lib/php/tmp/opnsense_acl_cache.json
}

if [ "$BRANCH" = "--remove" ]; then
    rm -f "$BASE/mvc/app/controllers/OPNsense/IDS/ThreatsController.php" \
          "$BASE/mvc/app/views/OPNsense/IDS/threats.volt" \
          "$BASE/www/js/widgets/JkUfwThreats.js"
    rm -rf "$BASE/mvc/app/models/OPNsense/JkUfw"
    clear_caches
    echo "Removed. The widget entry stays in JkUfw.xml but has no file and is not offered."
    exit 0
fi

if ! pkg info -e suricata; then
    echo ">>> installing suricata"
    pkg install -y suricata
fi

TMP=$(mktemp -d /tmp/jkufw-ids.XXXXXX)
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
echo "Done. Open https://<firewall>/ui/ids/threats"
echo "(menu: Services > Intrusion Detection > Threat Management)"
echo "Dashboard: + Add widget > 'jk-ufw: Защита от угроз (IPS)'."
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
